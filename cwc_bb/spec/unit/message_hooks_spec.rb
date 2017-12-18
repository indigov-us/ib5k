require "#{File.expand_path(File.dirname(__FILE__))}/../spec_helper"


describe 'Message Hooks' do

  before do
    @full = CWC::XMLGeneratorV2.new.full_doc
    @full_xml = @full.to_xml
  end

  it "should extract the office id from the xml" do
    m = CWC::Message.create xml:@full_xml
    m.office_id.must_equal @full.builder.doc.xpath('//CWC/Recipient/MemberOffice').first.content.strip
  end


  it "should extract the campaign id from the xml" do
    m = CWC::Message.create xml:@full_xml
    m.campaign_id.must_equal @full.builder.doc.xpath('//CWC/Delivery/CampaignId').first.content.strip
  end

  it "should extract the delivery id from the xml" do
    m = CWC::Message.create xml:@full_xml
    m.delivery_id.must_equal @full.builder.doc.xpath('//CWC/Delivery/DeliveryId').first.content.strip
  end

  it "should extract the delivery agent from the xml" do
    m = CWC::Message.create xml:@full_xml
    m.delivery_agent.must_equal @full.builder.doc.xpath('//CWC/Delivery/DeliveryAgent').first.content.strip
  end

end
