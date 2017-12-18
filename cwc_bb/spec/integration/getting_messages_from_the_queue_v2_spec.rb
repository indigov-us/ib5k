require "#{File.expand_path(File.dirname(__FILE__))}/../spec_helper"

describe 'Being able to get pending messages' do

  before do
    user = FactoryGirl.create(:user)
    30.times do
      mandatory = CWC::XMLGeneratorV2.new.mandatory_doc
      node = mandatory.builder.doc.xpath('//CWC/Recipient/MemberOffice').first
      node.content = 'HVA05'
      post '/v2/message', mandatory.to_xml, {'X-APIKEY' => user.apikey}
    end
  end

  it "should be able to get the first 10 emails" do
    get '/v2/hva05/queue.json?skip=0&limit=10'

    res = Yajl::Parser.parse(last_response.body)
    res['totalCount'].must_equal 30
    res['count'].must_equal 10
    res['skip'].must_equal 0
    res['limit'].must_equal 10
    res['messages'].size.must_equal 10
  end

  it "should archive messages after i receive them" do
    get '/v2/hva05/queue.json?skip=0&limit=10'
    res = Yajl::Parser.parse(last_response.body)
    res['totalCount'].must_equal 30

    get '/v2/hva05/queue.json?skip=0&limit=10'
    res = Yajl::Parser.parse(last_response.body)
    res['totalCount'].must_equal 30
  end

  it "should be able to parse the resulting xml message" do
    get "/v2/hva05/queue.xml?skip=0&limit=10"
    doc = Nokogiri::XML(last_response.body)
    msg = doc.xpath('//Response/Messages/Message').first.content
    new_doc = Nokogiri::XML(msg)
    new_doc.xpath('//CWC/Recipient/MemberOffice').first.content.size.must_equal 5
  end

  it "should delete the selected messages" do

    get '/v2/hva05/queue.xml?skip=0&limit=10'
    doc = Nokogiri::XML(last_response.body)
    totalCount = doc.xpath('//Response/TotalCount').first.content.to_i
    totalCount.must_equal 30


    resp = Nokogiri::XML(last_response.body)
    messages = resp.xpath('//Response/Messages/Message').map{|a| Nokogiri::XML(a.content)}
    # build up a mark as delivered query
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.MarkAsDelivered {
        xml.Messages{
           messages.each do |msg|
            xml.Message {
              xml.DeliveryId msg.xpath('//CWC//Delivery/DeliveryId').first.content
              xml.DeliveryAgent msg.xpath('//CWC//Delivery/DeliveryAgent').first.content
            }
          end
        }
      }
    end

    post '/v2/hva05/mark_as_delivered', builder.to_xml
    doc = Nokogiri::XML(last_response.body)
    doc.xpath('//Response/Success').first.content.must_equal 'All messages marked as delivered'

    get '/v2/hva05/queue.xml?skip=0&limit=10'
    doc = Nokogiri::XML(last_response.body)
    totalCount = doc.xpath('//Response/TotalCount').first.content.to_i
    totalCount.must_equal 20

  end


end
