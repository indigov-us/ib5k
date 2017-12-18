require "#{File.expand_path(File.dirname(__FILE__))}/../spec_helper"

describe 'Retreive My Messages (messages i sent)' do
  before do
    @user_a = FactoryGirl.create(:user)
    @user_b = FactoryGirl.create(:user)

    10.times do
      mandatory = CWC::XMLGeneratorV2.new.mandatory_doc
      node = mandatory.builder.doc.xpath('//CWC/Recipient/MemberOffice').first
      node.content = 'HVA05'
      post '/v2/message', mandatory.to_xml, {'X-APIKEY' => @user_a.apikey}
      post '/v2/message', mandatory.to_xml, {'X-APIKEY' => @user_b.apikey}
    end

    20.times do
      mandatory = CWC::XMLGeneratorV2.new.mandatory_doc
      node = mandatory.builder.doc.xpath('//CWC/Recipient/MemberOffice').first
      node.content = 'HFL17'
      post '/v2/message', mandatory.to_xml, {'X-APIKEY' => @user_a.apikey}
      post '/v2/message', mandatory.to_xml, {'X-APIKEY' => @user_b.apikey}
    end

    10.times do
      mandatory = CWC::XMLGeneratorV2.new.mandatory_doc
      node = mandatory.builder.doc.xpath('//CWC/Recipient/MemberOffice').first
      node.content = 'HNY24'
      post '/v2/message', mandatory.to_xml, {'X-APIKEY' => @user_a.apikey}
    end
  end

  it "should return all my messages regardless of the recipient" do
    get "/v2/messages.json?apikey=#{@user_a.apikey}&skip=0&limit=10"
    res = Yajl::Parser.parse(last_response.body)
    res['totalCount'].must_equal 40
  end

  it "should return all my messages regardless of the recipient (xml)" do
    get "/v2/messages.xml?apikey=#{@user_a.apikey}&skip=0&limit=10"
    doc = Nokogiri::XML(last_response.body)
    doc.xpath('//Response/Messages/Message').size.must_equal 10
    doc.xpath('//Response/TotalCount').first.content.to_i.must_equal 40
  end

  it "should return all my messages regardless of the recipient (xml)" do
    get "/v2/messages.xml?apikey=#{@user_b.apikey}&skip=0&limit=10"
    doc = Nokogiri::XML(last_response.body)
    doc.xpath('//Response/Messages/Message').size.must_equal 10
    doc.xpath('//Response/TotalCount').first.content.to_i.must_equal 30
  end

  it "should be able to parse the resulting xml message" do
    get "/v2/messages.xml?apikey=#{@user_b.apikey}&skip=0&limit=10"
    doc = Nokogiri::XML(last_response.body)
    msg = doc.xpath('//Response/Messages/Message').first.content
    new_doc = Nokogiri::XML(msg)
    new_doc.xpath('//CWC/Recipient/MemberOffice').first.content.size.must_equal 5
  end


end
