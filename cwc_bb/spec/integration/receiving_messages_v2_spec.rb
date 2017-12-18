require "#{File.expand_path(File.dirname(__FILE__))}/../spec_helper"

describe 'Receiving a message' do

  before do
    @user = FactoryGirl.create(:user)
  end

  it "should reject bad xml" do
    mandatory = CWC::XMLGeneratorV2.new.mandatory_doc
    mandatory.builder.doc.xpath('//CWC/Message/ConstituentMessage').first.remove

    node = mandatory.builder.doc.xpath('//CWC').first
    Nokogiri::XML::Builder.with(node) do |xml|
      xml.ExtraStuff "Y"
    end

    bad_xml = mandatory.to_xml

    post '/v2/message', bad_xml, {'X-APIKEY' => @user.apikey}
    last_response.status.must_equal 400
    errors = Nokogiri::XML(last_response.body)
    last_response.body.must_include 'OrganizationStatement'
    last_response.body.must_include 'Did not expect'
  end


  it "REMOVE THIS AFTER TESTING PHASE IS DONE: should reject non-allowed office" do
    mandatory = CWC::XMLGeneratorV2.new.mandatory_doc
    node = mandatory.builder.doc.xpath('//CWC/Recipient/MemberOffice').first
    node.content = 'HVA07'
    @xml = mandatory.to_xml
    post '/v2/message', @xml, {'X-APIKEY' => @user.apikey}
    last_response.status.must_equal 400
    last_response.body.must_equal 'During the testing phase delivery is not enabled for HVA07'
  end

  describe "well formated xml" do
    before do
      mandatory = CWC::XMLGeneratorV2.new.mandatory_doc
      node = mandatory.builder.doc.xpath('//CWC/Recipient/MemberOffice').first
      node.content = 'HVA05'
      @xml = mandatory.to_xml
    end

    it "should accept the message" do
      post '/v2/message', @xml, {'X-APIKEY' => @user.apikey}
      last_response.status.must_equal 200
      last_response.body.must_equal 'Message Accepted'
    end

    it "should save the message" do
      post '/v2/message', @xml, {'X-APIKEY' => @user.apikey}
      @user.messages.count.must_equal 1
      @user.messages.first.sent.must_equal false
    end

    it "should save the message with proper office id" do
      post '/v2/message', @xml, {'X-APIKEY' => @user.apikey}
      @user.messages.count.must_equal 1
      @user.messages.first.sent.must_equal false
      @user.messages.first.office_id.must_equal 'HVA05'
    end

  end

end
