require 'value_enums'

class Socal

  def create_event (event_name,invitation_code,latitude,longitude,place_name,address,description,datetime,creator)
    user = User.find_or_create_by_email(creator[:email])
    user.username = creator[:name]
    user.save!

    appAdditionalField = AppAdditionalField.where(:app_id => 4, :table_name => "Topic")
    result = Hash.new


    appAdditionalField.each do |field|
      result[field.additional_column_name]=nil
    end

    result["invitation_code"] = invitation_code
    result["content"] =  description
    result["place_name"]  = place_name
    result["address"] = address
    result["latitude"] = latitude
    result["longitude"] = longitude

    topic = Topic.create(title: event_name, data: result,user_id: user.id)

    if datetime.present?
      temp_array = datetime.split(",")
      temp_array.each do |dt|
        Suggesteddate.create(topic_id: topic.id, suggested_datetime: dt, invitation_code: topic.invitation_code)
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
  end



end
