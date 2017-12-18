module CWC
  class Api < Sinatra::Base
    get '/v2/:office/queue.json' do |office|
      skip = params['skip'].to_i
      limit = params['limit'] ? params['limit'].to_i : 10

      q = Message.where(office_id: office.upcase).limit(limit).skip(skip)
      res = {
              totalCount: q.count,
              count: q.to_a.size,
              skip: skip,
              limit: limit,
              messages: q.map{|msg| msg.xml}
      }
      json res
    end


    get '/v2/:office/queue.xml' do |office|
      skip = params['skip'].to_i
      limit = params['limit'] ? params['limit'].to_i : 10
      q = Message.where(office_id: office.upcase).limit(limit).skip(skip)


      builder = Nokogiri::XML::Builder.new do |xml|
        xml.Response {
          xml.Messages{
            q.to_a.each do |msg|
              xml.Message msg.xml
            end
          }
          xml.Count       q.to_a.size
          xml.Skip        skip
          xml.Limit       limit
          xml.TotalCount  q.count
        }
      end

      builder.to_xml
    end

    # given xml input with proper deivery id and deliver agent fileds,
    # we will mark all of the messages as received
    post '/v2/:office/mark_as_delivered' do |office|
      begin
        doc = Nokogiri::XML(request.body.read)
        doc.xpath('//MarkAsDelivered//Messages/Message').each do |msg|
          delivery_id    = msg.xpath('DeliveryId').first.content
          delivery_agent = msg.xpath('DeliveryAgent').first.content
          query = {office_id: office.upcase, delivery_id: delivery_id, delivery_agent: delivery_agent}
          Message.where(query).first.delete
        end

        builder = Nokogiri::XML::Builder.new do |xml|
          xml.Response {
            xml.Success 'All messages marked as delivered'
          }
        end
        builder.to_xml

      rescue => e
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.Response {
            xml.Error 'Erorr while parsing request'
          }
        end
        builder.to_xml
      end
    end

    get '/v2/messages.json' do
      user = require_apikey

      skip = params['skip'].to_i
      limit = params['limit'] ? params['limit'].to_i : 10

      q = user.messages.limit(limit).skip(skip)
      res = {
        totalCount: q.count,
        count: q.to_a.size,
        skip: skip,
        limit: limit,
        messages: q.map{|msg| msg.xml}
      }
      json res
    end

    get '/v2/messages.xml' do
      user = require_apikey

      skip = params['skip'].to_i
      limit = params['limit'] ? params['limit'].to_i : 10

      q = user.messages.limit(limit).skip(skip)

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.Response {
          xml.Messages{
            q.to_a.each do |msg|
              xml.Message msg.xml
            end
          }
          xml.Count       q.to_a.size
          xml.Skip        skip
          xml.Limit       limit
          xml.TotalCount  q.count
        }
      end

      builder.to_xml
    end

  end
end
