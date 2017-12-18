module CWC
  class Api < Sinatra::Base

    # from and to are inclusive and they should be formatted like
    #     2012-Sep-04
    # also accepts api_key, office_id and campaign_id parameters
    get '/stats/:from/:to' do |from,to|
      res = {}
      q = {created_at:{'$gte' => Date.parse(from).to_time(:utc), '$lt' => (Date.parse(to)+1).to_time(:utc)}}
      if params['api_key']
        u = User.where(activated:true,apikey:params['api_key']).first
        if u
          q[:user_id] = u.id
        end
      end

      if params['office_id']
        q[:office_id] = params['office_id']
      end
      if params['campaign_id']
        q[:campaign_id] = params['campaign_id']
      end

      messages = Message.where(q).without(:xml).to_a + Message.deleted.where(q).without(:xml).to_a

      res['Total'] = messages.size
      res['Offices'] = {}
      res['Campaigns'] = {}

      messages.each do |msg|

        if !res['Offices'][msg.office_id]
          res['Offices'][msg.office_id] = {
            'Total' => 0,
            'Campaigns' => {}
          }
        end

        res['Offices'][msg.office_id]['Total'] += 1

        if !res['Offices'][msg.office_id]['Campaigns'][msg.campaign_id]
          res['Offices'][msg.office_id]['Campaigns'][msg.campaign_id] = 0
        end
        res['Offices'][msg.office_id]['Campaigns'][msg.campaign_id] += 1


        if !res['Campaigns'][msg.campaign_id]
          res['Campaigns'][msg.campaign_id] = {
            'Total' => 0,
            'Offices' => {}
          }
        end

        res['Campaigns'][msg.campaign_id]['Total'] += 1
        if !res['Campaigns'][msg.campaign_id]['Offices'][msg.office_id]
          res['Campaigns'][msg.campaign_id]['Offices'][msg.office_id] = 0
        end
        res['Campaigns'][msg.campaign_id]['Offices'][msg.office_id] += 1
      end


      res['Offices'].each_key do |office_id|
        cmp_data = res['Offices'][office_id].delete('Campaigns')
        res['Offices'][office_id]['Campaigns'] = cmp_data.map{|c| {id:c[0], count:c[1]}}
      end


      res['Campaigns'] = res['Campaigns'].map{|c| {id:c[0], 'Total' => c[1]['Total'], 'Offices' => c[1]['Offices']}}
      content_type "application/xml"
      res.to_xml(skip_types:true,root:'Result')

    end

  end
end
