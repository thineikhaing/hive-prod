require 'value_enums'

class Socal

  def create_event (event_name,datetime,data,app_id, inv_code,user_id)
    app_data = Hash.new


    #get all extra columns that define in app setting
    appAdditionalField = AppAdditionalField.where(:app_id => app_id, :table_name => "Topic")

    if appAdditionalField.present?
      defined_Fields = Hash.new
      appAdditionalField.each do |field|
        defined_Fields[field.additional_column_name] = nil
      end
      #get all extra columns that define in app setting against with the params data
      if data.present?
        data = defined_Fields.deep_merge(data)
        result = Hash.new
        defined_Fields.keys.each do |key|
          result.merge!(data.extract! (key))
        end
      else
        result = defined_Fields
      end
    end

    topic = Topic.create(title: event_name, data: result,user_id: user_id ,hiveapplication_id: app_id)
    topic.save!

    temp_array = []
    if datetime.present?
      p datetime = JSON.parse(datetime)
      datetime.each do |dt|
        s_date = s_Time = dt["date"].to_time

        if dt["time"] == "00:00:00"
          s_Time = nil
        end

        Suggesteddate.create(topic_id: topic.id, user_id: user_id,suggested_datetime: s_date,suggesttime: s_Time , invitation_code: inv_code)
      end

    end

    return topic
  end

  def self.generate_invitation_code(contact = "")
    a = rand(10)
    b = rand(10)
    c = rand(10)
    d = rand(10)

    a.to_s + b.to_s + Time.now.to_formatted_s(:number) + c.to_s + d.to_s

    # [*('A'..'Z'),*('0'..'9')].shuffle[0,6].join

  end



end
