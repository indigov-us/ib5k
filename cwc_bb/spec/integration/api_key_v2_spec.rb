require "#{File.expand_path(File.dirname(__FILE__))}/../spec_helper"

describe 'Api Key Spec' do
  before do
    @user = FactoryGirl.create(:user)
    @mandatory = CWC::XMLGeneratorV2.new.mandatory_doc
    @mandatory_xml = @mandatory.to_xml
  end

  describe "message sending" do
    it "should reject without valid api key in params" do
      post '/v2/message?apikey=Invalid', @mandatory_xml
      last_response.status.must_equal 401
    end

    it "should reject without valid api key in header" do
      post '/v2/message', @mandatory_xml ,{'X-APIKEY' => 'Invalid'}
      last_response.status.must_equal 401
    end

    it "should reject with non-activated api key" do
      @user.activated = false
      @user.save
      post "/v2/message?apikey=#{@user.apikey}",@mandatory_xml
      last_response.status.must_equal 401
    end

    it "should accept with activated api key in params" do
      post "/v2/message?apikey=#{@user.apikey}", @mandatory_xml
      last_response.status.must_equal 200
    end

    it "should accept with activated api key in header" do
      post '/v2/message',@mandatory_xml, {'X-APIKEY' => @user.apikey}
      last_response.status.must_equal 200
    end
  end

end
