require "#{File.expand_path(File.dirname(__FILE__))}/../spec_helper"

describe 'Export and empty' do

  before do
    # create 2 users
    @user_a = FactoryGirl.create(:user)
    @user_b = FactoryGirl.create(:user)

    # CWC::Message.all.delete_all

    @offices = {
      'HVA07' => 4,
      'HMD05' => 2,
      'HCA22' => 2
    }

    @cids = [Digest::SHA256.hexdigest(rand(100).to_s), Digest::SHA256.hexdigest(rand(100).to_s)]

    @cids.each do |campaign_id|
      ['HVA07','HMD05'].each do |office|
        mandatory = CWC::XMLGeneratorV2.new.mandatory_doc

        node = mandatory.builder.doc.xpath('//CWC/Recipient/MemberOffice').first
        node.content = office

        node = mandatory.builder.doc.xpath('//CWC/Delivery/CampaignId').first
        node.content = campaign_id

        @user_a.messages.create xml:mandatory.to_xml
      end
    end

    @cids.each do |campaign_id|
      ['HVA07','HCA22'].each do |office|
        mandatory = CWC::XMLGeneratorV2.new.mandatory_doc

        node = mandatory.builder.doc.xpath('//CWC/Recipient/MemberOffice').first
        node.content = office

        node = mandatory.builder.doc.xpath('//CWC/Delivery/CampaignId').first
        node.content = campaign_id

        @user_b.messages.create xml:mandatory.to_xml
      end
    end

    CWC::Message.all.count.must_equal 8

  end


  describe "stats" do

    before do
      @date = Time.now.strftime('%Y-%b-%d')
      @url = "/stats/#{@date}/#{@date}"
    end

    it "should return proper global stats" do
      get @url

      doc = Nokogiri::XML(last_response.body)
      doc.xpath('//Result/Total').first.content.must_equal "8"
    end
  end


  describe "archive" do
    before do
      `rm -rf /tmp/cwc_test_export`
      `mkdir /tmp/cwc_test_export`
      CWC.archive_and_remove_all_messages('/tmp/cwc_test_export/','yes, delete all')
    end


    it "should have exported the all in one file" do
      File.exist?('/tmp/cwc_test_export/cwc_all_in_one.xml').must_equal true

      all_in_one_xml = File.read('/tmp/cwc_test_export/cwc_all_in_one.xml')

      doc = Nokogiri::XML(all_in_one_xml).root

      doc.xpath('//Count').first.content.to_i.must_equal 8
      doc.xpath('//Messages/Message').size.must_equal 8
    end

    it "should have exported the per office files" do
      @offices.keys.each{|oid|
        File.exist?("/tmp/cwc_test_export/cwc_office_#{oid}.xml").must_equal true
      }

      @offices.each_pair do |k,v|
        doc = Nokogiri::XML(File.read("/tmp/cwc_test_export/cwc_office_#{k}.xml")).root
        doc.xpath('//Count').first.content.to_i.must_equal v
        doc.xpath('//Messages/Message').size.must_equal v
      end

    end

    it "should have exported the per key files" do
      key = @user_a.apikey
      File.exist?("/tmp/cwc_test_export/cwc_key_#{key}.xml").must_equal true

      doc = Nokogiri::XML(File.read("/tmp/cwc_test_export/cwc_key_#{key}.xml")).root
      doc.xpath('//Count').first.content.to_i.must_equal 4
      doc.xpath('//Messages/Message').size.must_equal 4

      key = @user_b.apikey
      File.exist?("/tmp/cwc_test_export/cwc_key_#{key}.xml").must_equal true

      doc = Nokogiri::XML(File.read("/tmp/cwc_test_export/cwc_key_#{key}.xml")).root
      doc.xpath('//Count').first.content.to_i.must_equal 4
      doc.xpath('//Messages/Message').size.must_equal 4
    end


    it "should have exported the per campaign files" do
      @cids.each do |campaign_id|
        cid_file = Digest::SHA1.hexdigest(campaign_id.to_s)
        File.exist?("/tmp/cwc_test_export/cwc_campaign_#{cid_file}.xml").must_equal true

        doc = Nokogiri::XML(File.read("/tmp/cwc_test_export/cwc_campaign_#{cid_file}.xml")).root
        doc.xpath('//Count').first.content.to_i.must_equal 4
        doc.xpath('//Messages/Message').size.must_equal 4
      end

    end

  end

end
