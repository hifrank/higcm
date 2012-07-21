require 'json'

module GCM

  class Handler

    attr_accessor :retry_conditions

    def initialize
      @retry_ids   = {}
      @fail_ids    = {} 
      @success_ids = {} 
      @renew_ids  = {}
      @retry_conditions =[ 'InternalServerError', 'Timout', 'Unavailable' ]
      @unregister_conditions = [ 'NotRegistered', 'InvalidRegistration' ]
    end

    def handle(registration_ids, opts, response)
      begin
        @code = response.code.to_i
        @body = JSON.parse(response.body)
        #Honor Retry-After
        @retry_after = (response.headers['Retry-After'].nil? ? 0 : response.headers['Retry-After']) 
      rescue Exception => e
        @code = 99
        @error_message = "unexpected error, response: #{response.body}, exception: #{e.inspect}"
      end
      case @code
      when 200
        #200 Message was processed successfully. The response body will contain more details about the message status, but its format will depend whether the request was JSON or plain text. See Interpreting a success response for more details.
        # handle success case, http://developer.android.com/guide/google/gcm/gcm.html#success
        @body['results'].each_with_index do | rs, index |
          reg_id = registration_ids[index]
          #handle fail
          if rs.key?('error')
            @error_message = rs['error']
            if @retry_conditions.include?(rs['error'])
              @retry_ids[reg_id] = @retry_after
              @error_message << ", retry after #{@retry_after}"
            end
            @fail_ids[reg_id] = @error_message
          #handle success
          elsif rs.key?('message_id')
            @success_ids[reg_id] = rs['message_id']
            if rs.key?('registration_id')
              @renew_ids[reg_id] = rs['registration_id']
            end
          else
            #should not jump here
          end
        end
        @do_success.call(@success_ids, response)         if @success_ids.count > 0 && @do_success
        @do_fail.call(@fail_ids, response)               if @fail_ids.count > 0 && @do_fail
        @do_renew_token.call(@renew_ids, response)       if @renew_ids.count > 0 && @do_renew_token
        @do_retry.call(@retry_ids, opts, response) if @retry_ids.count > 0 && @do_retry
      #TODO need to check what kinf of response will return
      when 400, 401
        #400 Only applies for JSON requests. Indicates that the request could not be parsed as JSON, or it contained invalid fields (for instance, passing a string where a number was expected). The exact failure reason is described in the response and the problem should be addressed before the request can be retried.
        #401 There was an error authenticating the sender account.
        registration_ids.each do | reg_id |
          if 400 == @code 
            error_message = 'request could not be parsed as JSON'
          else
            error_message = 'There was an error authenticating the sender account'
          end
          @fail_ids[reg_id] = error_message
        end
        @do_fail.call(@fail_ids, response) if @do_fail &&  @fail_ids.count > 0
      #TODO need to check what kinf of response will return
      when 500, 503
        #500 There was an internal error in the GCM server while trying to process the request. trouble shooting http://developer.android.com/guide/google/gcm/gcm.html#internal_error
        #503 Indicates that the server is temporarily unavailable (i.e., because of timeouts, etc ). Sender must retry later, honoring any Retry-After header included in the response. Application servers must implement exponential back-off. The GCM server took too long to process the request. Troubleshoot
        registration_ids.each do | reg_id |
          @retry_ids[reg_id] = @retry_after
        end
        @do_retry.call(@retry_ids, opts) if @do_retry && @retry_ids.count > 0
      else
        registration_ids.each do | reg_id |
          @fail_ids[reg_id] = @error_message
        end
        @do_fail.call(@fail_ids, response) if @do_fail && @fail_ids.count > 0
      end
    end

    # success_ids
    def do_success(&block)
      @do_success = block
    end

    # retry_ids, opts, retry_after
    def do_retry(&block)
      @do_retry = block
    end

    def do_fail(&block)
      @do_fail = block
    end

    # renew_ids(hash)
    def do_renew_token(&block)
      @do_renew_token = block
    end

  end
end
