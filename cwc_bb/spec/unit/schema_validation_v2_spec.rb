require "#{File.expand_path(File.dirname(__FILE__))}/../spec_helper"


describe 'Schema Validation' do

  before do
    @full = CWC::XMLGeneratorV2.new.full_doc
    @full_xml = @full.to_xml

    @mandatory = CWC::XMLGeneratorV2.new.mandatory_doc
    @mandatory_xml = @mandatory.to_xml
  end

  it "must fail with bad closing tags" do
    proc {
      xml = File.read("#{File.expand_path(File.dirname(__FILE__))}/../examples/bad_closing_tags.xml")
      CWC::XMLValidatorV2.validate(xml)
    }.must_raise CWC::XML::ParseError
  end

  it "must be ok with bad characters if in CDATA block" do
    xml = File.read("#{File.expand_path(File.dirname(__FILE__))}/../examples/bad_characters_but_with_cdata.xml")
    CWC::XMLValidatorV2.validate(xml).must_equal true
  end

  it "must fail with bad characters" do
    proc {
      xml = File.read("#{File.expand_path(File.dirname(__FILE__))}/../examples/bad_characters.xml")
      CWC::XMLValidatorV2.validate(xml)
    }.must_raise CWC::XML::ParseError
  end

  it "must fail if we send more than one xml messages" do
    proc {
      CWC::XMLValidatorV2.validate(@mandatory.to_xml+"\n"+@mandatory.to_xml)
    }.must_raise CWC::XML::ParseError
  end

  it "should accept the sample message included in the spec" do
    xml = File.read("#{File.expand_path(File.dirname(__FILE__))}/../../docs/cwc_xml_submition_sample.xml")
    CWC::XMLValidatorV2.validate(xml).must_equal true
  end


  it "should accept non hex unique message id" do
    @full.builder.doc.xpath('//CWC/Delivery/DeliveryId').first.content = 'LKAP1036285LFVUID194HDCl6452ADDF'
    CWC::XMLValidatorV2.validate(@full.to_xml).must_equal true
  end

  it "must parse proper xml" do
    CWC::XMLValidatorV2.validate(@full_xml).must_equal true
    CWC::XMLValidatorV2.validate(@mandatory_xml).must_equal true
  end

  it "must parse email addresse" do
    emails = %w{foo+stackoverflow@example.com gyordanov@gmail.com galin.yordanov@mail.house.gov test@mail.co.uk}
    emails.each do |email|
      @full.builder.doc.xpath('//CWC/Constituent/Email').first.content = email
      CWC::XMLValidatorV2.validate(@full.to_xml).must_equal true
    end

    bad_emails = %w{foo+stackoverflowexample.com xxxx @bar.com abc@.bar.com}
    bad_emails.each do |email|
      @full.builder.doc.xpath('//CWC/Constituent/Email').first.content = email
      proc {
        CWC::XMLValidatorV2.validate(@full.to_xml)
      }.must_raise CWC::XML::ParseError
    end

  end

  it "must fail on xml with extra elements" do
    node = @mandatory.builder.doc.xpath('//CWC').first
    Nokogiri::XML::Builder.with(node) do |xml|
      xml.ExtraStuff "Y"
    end
    proc {
      CWC::XMLValidatorV2.validate(@mandatory.to_xml)
    }.must_raise CWC::XML::ParseError
  end

  it "should fail if OrganizationStatement AND ConstituentMessage are missing" do
    @full.builder.doc.xpath('//CWC/Message/OrganizationStatement').first.remove
    @full.builder.doc.xpath('//CWC/Message/ConstituentMessage').first.remove
    proc {
      CWC::XMLValidatorV2.validate(@full.to_xml)
    }.must_raise CWC::XML::ParseError
  end

  it "should fail if delivery is the wrong length" do
    @full.builder.doc.xpath('//CWC/Delivery/DeliveryId').first.content = '1'
    proc {
      CWC::XMLValidatorV2.validate(@full.to_xml)
    }.must_raise CWC::XML::ParseError

    @full.builder.doc.xpath('//CWC/Delivery/DeliveryId').first.content = '3'*1000
    proc {
      CWC::XMLValidatorV2.validate(@full.to_xml)
    }.must_raise CWC::XML::ParseError
  end

  it "should fail with incorect pro_or_con" do
    @full.builder.doc.xpath('//CWC/Message/ProOrCon').first.content = '1'
    proc {
      CWC::XMLValidatorV2.validate(@full.to_xml)
    }.must_raise CWC::XML::ParseError

    @full.builder.doc.xpath('//CWC/Message/ProOrCon').first.content = 'Pro'
    CWC::XMLValidatorV2.validate(@full.to_xml).must_equal true
    @full.builder.doc.xpath('//CWC/Message/ProOrCon').first.content = 'pRo'
    CWC::XMLValidatorV2.validate(@full.to_xml).must_equal true
    @full.builder.doc.xpath('//CWC/Message/ProOrCon').first.content = 'CON'
    CWC::XMLValidatorV2.validate(@full.to_xml).must_equal true
    @full.builder.doc.xpath('//CWC/Message/ProOrCon').first.content = 'coN'
    CWC::XMLValidatorV2.validate(@full.to_xml).must_equal true
  end

  it "should fail with bad bill type" do
    @full.builder.doc.xpath('//CWC/Message/Bill/BillTypeAbbreviation').first.content = 'notgood'
    proc {
      CWC::XMLValidatorV2.validate(@full.to_xml)
    }.must_raise CWC::XML::ParseError
  end

  it "should fail with bad bill congress" do
    @full.builder.doc.xpath('//CWC/Message/Bill/BillCongress').first.content = '-543'
    proc {
      CWC::XMLValidatorV2.validate(@full.to_xml)
    }.must_raise CWC::XML::ParseError
  end

  it "should fail with bad libraryofcongresstopic" do
    @full.builder.doc.xpath('//CWC/Message/LibraryOfCongressTopic').first.content = 'Not in the List'
    proc {
      CWC::XMLValidatorV2.validate(@full.to_xml)
    }.must_raise CWC::XML::ParseError
  end


  it "do proper zip validation" do
    @full.builder.doc.xpath('//CWC/Constituent/Zip').first.content = '1234'
    proc {
      CWC::XMLValidatorV2.validate(@full.to_xml)
    }.must_raise CWC::XML::ParseError

    @full.builder.doc.xpath('//CWC/Constituent/Zip').first.content = '12345'
    CWC::XMLValidatorV2.validate(@full_xml).must_equal true

    @full.builder.doc.xpath('//CWC/Constituent/Zip').first.content = '12345-1234'
    CWC::XMLValidatorV2.validate(@full_xml).must_equal true

    @full.builder.doc.xpath('//CWC/Constituent/Zip').first.content = '12345X1234'
    proc {
      CWC::XMLValidatorV2.validate(@full.to_xml)
    }.must_raise CWC::XML::ParseError
  end

end
