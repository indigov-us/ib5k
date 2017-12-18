require "#{File.expand_path(File.dirname(__FILE__))}/../spec_helper"

describe 'Email Sending' do
  before do
    @user = FactoryGirl.create(:user)
    @mandatory = CWC::XMLGeneratorV2.new.mandatory_doc
    @mandatory_xml = @mandatory.to_xml
  end

  it "should send the email once i create it " do
    CWC::OFFICE_TO_EMAIL['HVA05'] = 'HVA05-CWC@housemail.house.gov'
    new_m = CWC::Message.create xml:@mandatory_xml

    proc {
      m = CWC::Message.find new_m.id
    }.must_raise Mongoid::Errors::DocumentNotFound

    m = CWC::Message.deleted.find new_m.id
    m.sent.must_equal true
    m.smtp_id.wont_be_empty
    Mail::TestMailer.deliveries.size.must_equal 1
    delivery = Mail::TestMailer.deliveries[0]
    delivery.to.first.must_equal 'HVA05-CWC@housemail.house.gov'
  end

  it "should NOT send the email once i create it " do
    CWC::OFFICE_TO_EMAIL.delete 'HVA05'
    m = CWC::Message.create xml:@mandatory_xml
    m.reload

    m.sent.must_equal false
    m.smtp_id.must_be_nil
    m.deleted?.must_equal false

    Mail::TestMailer.deliveries.must_be_empty

  end

end
