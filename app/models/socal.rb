require 'value_enums'

class Socal

  def create_event (event_name,datetime,email, name,data,app_id, inv_code)

    user = User.find_by_email(email)
    if user.nil?
      user = User.new
      user.email = email
    else
      user.username = name
    end
    p name
    user.username = name
    user.password = '12345678'
    user.save!


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

    topic = Topic.create(title: event_name, data: result,user_id: user.id,hiveapplication_id: app_id)
    #topic.data = { "host_code" => Socal.generate_invitation_code }
    #topic.data = { "latitude" => ""}
    #topic.data = { "longitude" => "" }
    #topic.data = { "place_name" => "" }

    topic.save!
    temp_array = []
     p datetime
    if datetime.present?
      p temp_array = datetime.split(",")

      p "temp array"
      temp_array.each do |dt|
        Suggesteddate.create(topic_id: topic.id, user_id: user.id,suggested_datetime: dt, invitation_code: inv_code)
      end
    end

    return topic
  end

  def self.generate_invitation_code(contact = "")
    #a = rand(10)
    #b = rand(10)
    #c = rand(10)
    #d = rand(10)
    #
    #a.to_s + b.to_s + Time.now.to_formatted_s(:number) + c.to_s + d.to_s

    [*('A'..'Z'),*('0'..'9')].shuffle[0,6].join
  end



end
