require "#{File.expand_path(File.dirname(__FILE__))}/../spec_helper"

describe "XML to mailproc format" do

  before do
    @full = CWC::XMLGenerator.new.full_doc
    @full_xml = @full.to_xml

    @mandatory = CWC::XMLGenerator.new.mandatory_doc
    @mandatory_xml = @mandatory.to_xml
  end

end
