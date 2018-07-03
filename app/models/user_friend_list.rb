class UserFriendList < ActiveRecord::Base

  belongs_to :user
  #
  # def as_json(options=nil)
  #   if options[:content].present?      #return topic json with content information
  #     super(only: [:id, :user_id,:friend_id], methods: [:friend_information])
  #   else
  #     super(only: [:id, :user_id,:friend_id], methods: [:friend_information])
  #   end
  # end
  #
  #
  #
  # def friend_information
  #   if self.friend_id.present?
  #     user = User.find(self.friend_id)
  #     {id: user.id, username: user.username,last_known_latitude:user.last_known_latitude,last_known_longitude:user.last_known_longitude,avatar_url:user.avatar_url,local_avatar: Topic.get_avatar(user.username)}
  #   end
  # end

end
