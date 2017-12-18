require "#{File.expand_path(File.dirname(__FILE__))}/../lib/config.rb"


module CWC

  class XMLGeneratorV2

    def initialize
      @doc = Nokogiri::XML::Builder.new
      @doc.CWC {|xml|
        xml.CWCVersion "1.0"
        xml.Delivery
        xml.Recipient
        xml.Constituent
        xml.Message
      }

      @mandatory_attr = %w{add_delivery add_recipient add_constituent add_message}
      @optional_attr = %w{add_delivery_optional add_recipient_optional add_constituent_optional add_message_optional}

    end

    def mandatory_doc
      @mandatory_attr.each {|m| send m}
      node = @doc.doc.xpath('//CWC/Message').first
      Nokogiri::XML::Builder.with(node) do |xml|
        xml.ConstituentMessage "Dear Congresswoman, as a father of two small children, I believe that nothing is more important than access to education."
        xml.MoreInfo "http://www.aec.org/issue/legislation/HR233/"
      end
      self
    end

    def full_doc
      @mandatory_attr.each {|m| send m}
      @optional_attr.each {|m| send m}
      self
    end

    def add_delivery
      node = @doc.doc.xpath('//CWC/Delivery').first
      Nokogiri::XML::Builder.with(node) do |xml|
        more_random = (0...50).map{ ('a'..'z').to_a[rand(26)] }.join
        xml.DeliveryId    Digest::MD5.hexdigest("#{rand(1000).to_s}_#{rand(1000).to_s}_#{more_random}")
        xml.DeliveryDate  Time.now.strftime('%Y%m%d')
        xml.DeliveryAgent "Agent name"
        xml.DeliveryAgentAckEmailAddress "someemail@gmail.com"

        xml.DeliveryAgentContact {
          xml.DeliveryAgentContactName  "Contact Name"
          xml.DeliveryAgentContactEmail "otheremail@gmail.com"
          xml.DeliveryAgentContactPhone "202-555-5678"
        }

        xml.CampaignId Digest::SHA256.hexdigest(rand(100).to_s)
      end
    end

    def add_delivery_optional
      node = @doc.doc.xpath('//CWC/Delivery').first
      Nokogiri::XML::Builder.with(node) do |xml|
        xml.Organization "Organization Name"
        xml.OrganizationContact {
          xml.OrganizationContactName "Contact Name"
          xml.OrganizationContactEmail "orgemail@gmail.com"
          xml.OrganizationContactPhone "302-645-9438"
        }
        xml.OrganizationAbout "About this organization"
      end
    end

    def add_recipient
      node = @doc.doc.xpath('//CWC/Recipient').first
      Nokogiri::XML::Builder.with(node) do |xml|
        xml.MemberOffice "HVA05"
      end
    end

    def add_recipient_optional
      node = @doc.doc.xpath('//CWC/Recipient').first
      Nokogiri::XML::Builder.with(node) do |xml|
        xml.IsResponseRequested "Y"
        xml.NewsletterOptIn     "Y"
      end
    end

    def add_constituent
      node = @doc.doc.xpath('//CWC/Constituent').first
      Nokogiri::XML::Builder.with(node) do |xml|
        xml.Prefix            "Mr."
        xml.FirstName         "First"
        xml.LastName          "Last"
        xml.Address1          "2101 O'Neil Avenue"
        xml.City              "Cheyenne"
        xml.StateAbbreviation "WY"
        xml.Zip               "82001-3512"
        xml.Email             "constituent_email@gmail.com"
      end
    end

    def add_constituent_optional
      node = @doc.doc.xpath('//CWC/Constituent').first
      Nokogiri::XML::Builder.with(node) do |xml|
        xml.MiddleName "A."
        xml.Suffix "Jr."
        xml.Title "Vice Principal"
        xml.ConstituentOrganization "Sandview Elementary School"
        xml.Address2 "Room 310"
        xml.Address3 "Rural Route"
        xml.Phone "234-324-2344"
        xml.AddressValidation "Y"
        xml.EmailValidation "Y"
      end
    end

    def add_message
      node = @doc.doc.xpath('//CWC/Message').first
      Nokogiri::XML::Builder.with(node) do |xml|
        xml.Subject "Excellence in Education"
        xml.LibraryOfCongressTopic "Education"
      end
    end

    def add_message_optional
      node = @doc.doc.xpath('//CWC/Message').first
      Nokogiri::XML::Builder.with(node) do |xml|
        xml.Bill {
          xml.BillCongress "112"
          xml.BillTypeAbbreviation "hr"
          xml.BillNumber "233"
        }
        xml.ProOrCon "Pro"
        xml.OrganizationStatement "I urge you to support the Education for All Americans Act of 2009 to help foster learning for all Americans, benefitting their communities and themselves."
        xml.ConstituentMessage "Dear Congresswoman, as a father of two small children, I believe that nothing is more important than access to education."
        xml.MoreInfo "http://www.aec.org/issue/legislation/HR233/"
      end
    end

    def builder
      @doc
    end

    def to_xml
      @doc.to_xml
    end

  end
end
