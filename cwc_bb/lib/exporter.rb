module CWC

  # it will attempt to archive all messages as:
  #  one large xml file
  #  xml file per office
  #  xml file per api key
  #  xml file per campaign id
  def self.archive_and_remove_all_messages(out_dir = '/tmp', confirm)
    return false unless confirm == 'yes, delete all'

    q = Message.all.to_a + Message.deleted.to_a

    Message.db.collection('cwc_messages').remove

    per_office = {}
    per_key = {}
    per_campaign = {}

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.Response {
        xml.Messages{
          q.each do |msg|

            if per_office.has_key?(msg.office_id)
              per_office[msg.office_id] << msg.xml
            else
              per_office[msg.office_id] = [msg.xml]
            end

            if per_key.has_key?(msg.user.apikey)
              per_key[msg.user.apikey] << msg.xml
            else
              per_key[msg.user.apikey] = [msg.xml]
            end

            if per_campaign.has_key?(msg.campaign_id)
              per_campaign[msg.campaign_id] << msg.xml
            else
              per_campaign[msg.campaign_id] = [msg.xml]
            end

            xml.Message msg.xml
          end
        }
        xml.Count       q.size
        xml.TotalCount  q.size
      }
    end

    File.open("#{out_dir}/cwc_all_in_one.xml", 'w') {|f| f.write(builder.to_xml) }

    per_office.each_pair do |oid,xmls|
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.Response {
          xml.Messages{
            xmls.each do |xml_str|
              xml.Message xml_str
            end
          }
          xml.Count       xmls.size
          xml.TotalCount  xmls.size
        }
      end

      File.open("#{out_dir}/cwc_office_#{oid}.xml", 'w') {|f| f.write(builder.to_xml) }

    end

    per_key.each_pair do |key,xmls|
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.Response {
          xml.Messages{
            xmls.each do |xml_str|
              xml.Message xml_str
            end
          }
          xml.Count       xmls.size
          xml.TotalCount  xmls.size
        }
      end

      File.open("#{out_dir}/cwc_key_#{key}.xml", 'w') {|f| f.write(builder.to_xml) }

    end

    per_campaign.each_pair do |cid,xmls|
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.Response {
          xml.Messages{
            xmls.each do |xml_str|
              xml.Message xml_str
            end
          }
          xml.Count       xmls.size
          xml.TotalCount  xmls.size
        }
      end
      cid_file = Digest::SHA1.hexdigest(cid.to_s)
      File.open("#{out_dir}/cwc_campaign_#{cid_file}.xml", 'w') {|f| f.write(builder.to_xml) }

    end

  end

end
