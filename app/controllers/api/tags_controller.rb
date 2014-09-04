class Api::TagsController < ApplicationController

  # Delete tags
  # Delete records of tags inside Historychange Table
  def delete
    if params[:tag_id].present?
      tag = Tag.find_by_id(params[:tag_id])
      if tag.present?
        tag.remove_records(params[:tag_id])
        tag.delete
      else
        render json: { error_msg: "Invalid tag_id" }
      end
      render json: { status: true }
    else
      render json: { error_msg: "Params tag_id must be presented" }
    end
  end

  # Returns tags and locations within range of (n) Km
  # Current range is set as 1km
  def within_location
    if params[:latitude].present? and params[:longitude].present?
      tagsArray = [ ]
      locationTagsArray = [ ]
      normalTagsArray = [ ]
      topicsArray = [ ]
      params[:radius].present? ? radius = params[:radius] : radius=1
      places = Place.nearest(params[:latitude], params[:longitude],radius)

      places.each do |place|
        topics = place.topics
        topics.map { |t| topicsArray.push(t.id) unless topicsArray.include?(t.id) } if topics.present?
      end

      TopicWithTag.where(topic_id: topicsArray).map { |tag| tagsArray.push(tag.tag_id) unless tagsArray.include?(tag.tag_id) } if TopicWithTag.where(topic_id: topicsArray).present?

      Tag.where(id: tagsArray).each do |checkTag|
        if checkTag.tag_type == Tag::NORMAL
          normalTagsArray.push(checkTag.keyword) unless normalTagsArray.include?(checkTag.keyword)
        elsif checkTag.tag_type == Tag::LOCATION
          locationTagsArray.push(checkTag.keyword) unless locationTagsArray.include?(checkTag.keyword)
        end
      end
      render json: { tags: normalTagsArray, locationtags: locationTagsArray }
    else
      render json: { error_msg: "Params latitude and longitude must presented" }
    end
  end

end
