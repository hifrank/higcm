require 'typhoeus'

module HiGCM

    class SenderError < StandardError; end

    class Sender
      attr_accessor :api_key, :api_status, :hydra, :requests

      OPTIONAL_OPTIONS = {
        :collapse_key     => String,
        :data             => Hash,
        :delay_while_idle => [true, false],
        :time_to_live     => Fixnum
      }

      def initialize(api_key)
        @api_key  = api_key
        raise SenderError.new("api_key is necessary for #{self.class}") if api_key.nil? || api_key.empty?
      end

      def send(registration_ids, opts={}, handler=nil)
        handler = HiGCM::Handler.new if handler.nil?
        request = send_async(registration_ids, opts, handler)
        send_async_run
        request.handled_response
      end

      #http://developer.android.com/guide/google/gcm/gcm.html#server
      def send_async(registration_ids, opts={}, handler=nil)

        headers = {
          'Content-Type'  => 'application/json',
          'Authorization' => sprintf("key=%s", @api_key)
        }

        body = {
          'registration_ids' => registration_ids,
        }

        #fill up option
        OPTIONAL_OPTIONS.each do | key, type |
          if opts.key?(key)
            if type.is_a?(Array)
              @valid_value = false
              type.each do | v |
                if opts[key] == v
                  @valid_value = true
                  break
                end
              end
              raise SenderError.new("#{key} should be Type #{type}") unless @valid_value
            else
              raise SenderError.new("#{key} should be Type #{type}") unless opts[key].is_a?(type)
            end
            # convert payload data to String for issue #3
            case key
            when :data
              opts[key] = convert_hash(opts[key])
            end
            body[key] = opts[key]
          end
        end

        request = Typhoeus::Request.new(
          'https://android.googleapis.com/gcm/send',
          :headers         => headers,
          :method          => :post,
          :body            => body.to_json,
          :follow_location => true
        )

        @hydra ||= Typhoeus::Hydra.new

        request.on_complete do | response |
          handler.handle(registration_ids, opts, response)
        end

        @hydra.queue(request)

        request
      end

      def send_async_run
        # handle response according to http://developer.android.com/guide/google/gcm/gcm.html#response
        @hydra.run
      end

      def convert_hash(hash)
        hash.each do | k, v |
          if v.is_a?(Hash)
            hash[k] = convert_hash(v)
          else
            if v.respond_to?(:to_s)
              hash[k] = v.to_s
            else
              raise SenderError "data value must respond to to_s function for converting to String"
            end
          end
        end
      end

    end
end
