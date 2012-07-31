require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe HiGCM::Sender do

  before(:each) do
    @api_key = 'foo'
    @registration_ids = [1, 2, 3, 4, 5, 6]
    @raw_gcm_response = File.read("#{File.dirname(__FILE__)}/../../fixtures/gcm_response_200.json")
    @retry_after = 10
    @stub_gcm_response = Typhoeus::Response.new(
      :code    => 200,
      :headers => {"Retry-After" => @retry_after},
      :body    =>  @raw_gcm_response,
      :time    => 0.1
    )
    @sender = HiGCM::Sender.new(@api_key)
    @sender.hydra = Typhoeus::Hydra.new
    @sender.hydra.stub(:post, 'https://android.googleapis.com/gcm/send').and_return(@stub_gcm_response)
  end

  describe "#initialize" do
    it "should raise exception when api_key does not given when init" do
      expect { sender = HiGCM::Sender.new }.to raise_error
    end

    it "should raise exception when given api_key is nil or empty" do
      expect { sender = HiGCM::Sender.new ""}.to raise_error
      expect { sender = HiGCM::Sender.new nil}.to raise_error
    end

    it "should accept correct API key" do
      sender  = HiGCM::Sender.new(@api_key)
      sender.should be_a(HiGCM::Sender)
      sender.api_key.should == @api_key
    end
  end

  describe "#send" do
    it "should return Typhoeus::Response" do
      response = @sender.send(@registration_ids, {})
      response.should be_a(Typhoeus::Response)
    end

    it "should call handler.handle after request is completed" do
      handler = double(HiGCM::Handler)
      handler.should_receive(:handle).with(@registration_ids, {}, @stub_gcm_response)
      @sender.send(@registration_ids, {}, handler)
    end
  end

  describe "#send_async" do

    it "should call handler.handle after request is completed" do
      handler = double(HiGCM::Handler)
      handler.should_receive(:handle).with(@registration_ids, {}, @stub_gcm_response)
      @sender.send_async(@registration_ids, {}, handler)
      @sender.send_async_run
    end

    it "should raise exception if opts[:collapse_key] is not String, empty string is acceptable" do
      expect { @sender.send_async(@registration_ids, {:collapse_key => nil }, HiGCM::Handler.new) }.to raise_error(HiGCM::SenderError)
      expect { @sender.send_async(@registration_ids, {:collapse_key => "" }, HiGCM::Handler.new) }.not_to raise_error(HiGCM::SenderError)
    end

    it "should raise exception if opts[:data] is not Hash, empty hash is acceptable" do
      expect { @sender.send_async(@registration_ids, {:data => [] }, HiGCM::Handler.new) }.to raise_error(HiGCM::SenderError)
      expect { @sender.send_async(@registration_ids, {:data => {} }, HiGCM::Handler.new) }.not_to raise_error(HiGCM::SenderError)
    end

    it "should raise exception if opts[:delay_while_idle] && opts[:time_to_live] is not Fixnum" do
      expect { @sender.send_async(@registration_ids, {:delay_while_idle => [] }, HiGCM::Handler.new) }.to raise_error(HiGCM::SenderError)
      expect { @sender.send_async(@registration_ids, {:delay_while_idle => 1 }, HiGCM::Handler.new) }.not_to raise_error(HiGCM::SenderError)
      expect { @sender.send_async(@registration_ids, {:time_to_live => [] }, HiGCM::Handler.new) }.to raise_error(HiGCM::SenderError)
      expect { @sender.send_async(@registration_ids, {:time_to_live => 1 }, HiGCM::Handler.new) }.not_to raise_error(HiGCM::SenderError)
    end
  end

  describe "#send_async_run" do
    it "should run Typhoeus::Hydra when send requests" do
      hydra  = double(Typhoeus::Hydra)
      @sender.hydra = hydra
      hydra.should_receive(:run).once
      @sender.send_async_run
    end
  end

end
