require "#{File.expand_path(File.dirname(__FILE__))}/../spec_helper"

describe 'Validating a message' do

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

    post '/v2/validate', bad_xml, {'X-APIKEY' => @user.apikey}
    last_response.status.must_equal 400
    errors = Nokogiri::XML(last_response.body)
    last_response.body.must_include 'OrganizationStatement'
    last_response.body.must_include 'Did not expect'
  end

  describe "well formated xml" do
    before do
      mandatory = CWC::XMLGeneratorV2.new.mandatory_doc
      node = mandatory.builder.doc.xpath('//CWC/Recipient/MemberOffice').first
      node.content = 'HVA07'
      @xml = mandatory.to_xml
    end

    it "should accept the message" do
      post '/v2/validate', @xml, {'X-APIKEY' => @user.apikey}
      last_response.status.must_equal 200
      last_response.body.must_equal 'Message Validated'
    end

    it "should save the message" do
      post '/v2/validate', @xml, {'X-APIKEY' => @user.apikey}
      @user.messages.count.must_equal 0
    end

    it "should save the message with proper office id" do
      post '/v2/validate', @xml, {'X-APIKEY' => @user.apikey}
      @user.messages.count.must_equal 0
    end

  end

end
