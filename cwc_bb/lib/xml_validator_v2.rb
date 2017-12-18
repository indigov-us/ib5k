
module CWC

  module XML
    class ParseError < StandardError
      attr_reader :original
      def initialize(msg, original=nil);
        super(msg);
        @original = original;
      end
    end
  end

  class XMLValidatorV2
    def self.validate(xml_str)

      begin
        schema  = Nokogiri::XML::RelaxNG(File.open("#{::File.expand_path(::File.dirname(__FILE__))}/data/cwc_schema_v2.rng"))
        doc     = Nokogiri::XML(xml_str,nil,nil,Nokogiri::XML::ParseOptions::STRICT)
      rescue => error
        raise XML::ParseError.new("XML Parse Error", error)
      end

      errors = schema.validate(doc);
      if errors.size > 0
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.Errors{
            errors.each do |e|
              xml.Error e.message
            end
          }
        end
        raise XML::ParseError.new(builder.to_xml)
      end

      true
    end
  end
end
