require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe HiGCM::Handler do
  describe "#setting different criteria for retry & unregister" do
    it "should take retry_conditions & unregister_conditions" do
      handler = HiGCM::Handler.new
      handler.unregister_conditions = ['foo']
      handler.unregister_conditions.should == ['foo']

      handler.retry_conditions = ['foo']
      handler.retry_conditions.should == ['foo']
    end
  end

  describe "#handle" do
    it "#handle should handle various response in when response code is 500" do
    end

    it "#handle should handle various response when response code is 200" do
      @raw_gcm_response = File.read("#{File.dirname(__FILE__)}/../../fixtures/gcm_response_200.json")
      @retry_after = 10
      @stub_gcm_response = Typhoeus::Response.new(
        :code    => 200,
        :headers => {"Retry-After" => @retry_after},
        :body    =>  @raw_gcm_response,
        :time    => 0.1
      )
      @api_key     = 'foo'
      sender       = HiGCM::Sender.new(@api_key)
      sender.hydra = Typhoeus::Hydra.hydra
      sender.hydra.stub(:post, 'https://android.googleapis.com/gcm/send').and_return(@stub_gcm_response)

      _fails   = 0
      _success = 0
      _renew   = 0
      _retry   = 0

      _updated_token = { 5 => "32"}

      handler = HiGCM::Handler.new
      handler.do_success do | succes_ids, response |
        @success_ids      = succes_ids
      @success_response = response
      end
      handler.do_retry do | retry_ids, opts, response |
        @retry_ids      = retry_ids
      @retry_opts     = opts
      @retry_response = response
      end
      handler.do_fail do | fail_ids, response |
        @fail_ids      = fail_ids
      @fail_response = response
      end
      handler.do_renew_token do | renew_ids, response |
        @renew_ids      = renew_ids
      @renew_response = response
      end
      handler.do_unregister_token do | unreg_ids, response |
        @unreg_ids      = unreg_ids
      @unreg_response = response
      end

      registration_ids = [1, 2, 3, 4, 5, 6]
      sender.send_async(registration_ids, {}, handler)
      sender.send_async_run

      @fail_ids.should == { 2 => "Unavailable, retry after #{@retry_after}", 3 => "InvalidRegistration", 6 => "NotRegistered" }
      @fail_response.should be_a(Typhoeus::Response)

      @retry_ids.should  == { 2 => 10 }
      @retry_opts.should == {}
      @retry_response.should be_a(Typhoeus::Response)

      @renew_ids.should == { 5 => "32" }
      @renew_response.should be_a(Typhoeus::Response)

      @success_ids.should == { 1 => "1:0408", 4 => "1:1516", 5 => "1:2342" }
      @success_response.should be_a(Typhoeus::Response)

      @unreg_ids.should == { 3 => "InvalidRegistration", 6 => "NotRegistered" }
      @unreg_response.should be_a(Typhoeus::Response)

    end
  end

end
