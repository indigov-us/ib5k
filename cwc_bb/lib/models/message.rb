module CWC

  class Message
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mongoid::Paranoia

    # the plain xml we received
    field :xml, type: String

    # was the message sent ?
    field :sent, type: Boolean, default: false

    # this will hold the ID returned by the mail delivery mechanism
    field :smtp_id, type: String

    # the office id that we need to deliver this email to
    field :office_id,   type: String
    field :campaign_id, type: String

    # we need this for the mark as read rest point
    field :delivery_id,    type: String
    field :delivery_agent, type: String

    index [
      [:user_id, Mongo::ASCENDING],
      [:created_at, Mongo::ASCENDING]], background: true

    index [
      [:office_id, Mongo::ASCENDING],
      [:archived_at, Mongo::ASCENDING]], background: true
    index [
      [:campaign_id, Mongo::ASCENDING],
      [:archived_at, Mongo::ASCENDING]], background: true
    index [
      [:office_id, Mongo::ASCENDING],
      [:delivery_id, Mongo::ASCENDING],
      [:delivery_agent, Mongo::ASCENDING],
      [:archived_at, Mongo::ASCENDING]], background: true

    index [
      [:user_id, Mongo::ASCENDING],
      [:office_id, Mongo::ASCENDING],
      [:created_at, Mongo::ASCENDING]], background: true
    index [
      [:user_id, Mongo::ASCENDING],
      [:campaign_id, Mongo::ASCENDING],
      [:created_at, Mongo::ASCENDING]], background: true
    index [
      [:office_id, Mongo::ASCENDING],
      [:campaign_id, Mongo::ASCENDING],
      [:created_at, Mongo::ASCENDING]], background: true

    belongs_to :user, class_name: 'CWC::User'

    before_create :extract_office_id
    before_create :extract_campaign_id
    before_create :extract_delivery_id

    after_create  :send_email_if_required


    def self.perform(message_id)
      m =  Message.find(message_id)
      m.forward_to_formproc
    end

    # trasform the xml to formproc and send
    def forward_to_formproc
      message = self
      res = Mail.new do
        to CWC::OFFICE_TO_EMAIL[message.office_id]
        from 'cwc@mail.house.gov'
        subject 'CWC Message'
        body message.xml.to_s
      end
      res = res.deliver!

      # not sure why but i don't get id without this to_s call ....
      res.to_s

      message.sent = true
      message.smtp_id = res.message_id
      message.save

      message.delete
    end

    private
    def extract_office_id
      if !self.office_id
        parsed_xml = Nokogiri::XML.parse(self.xml)
        tmp = parsed_xml.xpath('//CWC/Recipient/MemberOffice').first || parsed_xml.xpath('//cwc/recipient/memberoffice').first
        self.office_id = tmp.content.strip
      end
    end

    def extract_campaign_id
      if !self.campaign_id
        parsed_xml = Nokogiri::XML.parse(self.xml)
        tmp = parsed_xml.xpath('//CWC/Delivery/CampaignId').first || parsed_xml.xpath('//cwc/recipient').first
        self.campaign_id = tmp.content.strip
      end

    end

    def extract_delivery_id
      if !self.delivery_id || !self.delivery_agent
        parsed_xml = Nokogiri::XML.parse(self.xml)
        self.delivery_id = parsed_xml.xpath('//CWC//Delivery/DeliveryId').first.content
        self.delivery_agent = parsed_xml.xpath('//CWC//Delivery/DeliveryAgent').first.content
      end
    end

    def send_email_if_required
      if CWC::OFFICE_TO_EMAIL[self.office_id]
        # do indeed email this ...
        Qu.enqueue 'CWC::Message', self.id
      end
    end

  end

end
