class Home  < ActiveRecord::Base


  def self.map_view_by_app(id)
    @placesMap = Place.order("created_at DESC").reload

    #filtering for normal topic, image, audio and video
    @latestTopics = [ ]
    @latestTopicUser = [ ]

    @placesMap.map { |f|
      @latestTopics.push(f.topics.where(hiveapplication_id: id).last)
    }

    @latestTopics.each do |topic|
      if topic.present?
        @latestTopicUser.push(topic.username)
      end

      # else
      #   @latestTopicUser.push("nothing")
      # end
    end
    #
    # gon.places =  @placesMap.as_json
    #
    # gon.latestTopicUser = @latestTopicUser
    #
    # gon.latestTopics = @latestTopics

    # { places: @placesMap.as_json, latestTopicUser: @latestTopicUser, latestTopics: @latestTopics}

  end


end