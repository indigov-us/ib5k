module CWC
  class Api < Sinatra::Base
    post '/v2/message' do
      user = require_apikey

      xml_str = request.body.read

      begin
        XMLValidatorV2.validate(xml_str)
      rescue XML::ParseError => e
        halt 400, e.message
      end

      # BEGIN: extra limitation just for the full chain testing
      allowed_offices = ["HCA48", "HCA49", "HCA50", "HCA51", "HCA52", "HCA53", "HFL13", "HFL14", "HFL15", "HFL16", "HFL17", "HFL18", "HNY24", "HNY25", "HNY26", "HNY27", "HNY28", "HNY29", "HPA07", "HPA08", "HPA09", "HPA10", "HPA11", "HPA12", "HVA01", "HVA02", "HVA03", "HVA04", "HVA05", "HVA06"]
      parsed_xml = Nokogiri::XML.parse(xml_str)
      office = parsed_xml.xpath('//CWC/Recipient/MemberOffice').first.content
      if !allowed_offices.include?(office.upcase)
        halt 400, "During the testing phase delivery is not enabled for #{office.upcase}"
      end
      # END: extra limitation just for the full chain testing

      user.messages.create xml:xml_str
      "Message Accepted"
    end

    post '/v2/validate' do
      user = require_apikey

      xml_str = request.body.read

      begin
        XMLValidatorV2.validate(xml_str)
      rescue XML::ParseError => e
        halt 400, e.message
      end
      "Message Validated"
    end


  end
end
