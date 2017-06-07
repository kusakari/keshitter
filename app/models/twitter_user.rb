class TwitterUser < ApplicationRecord

  def self.update_or_create_by_object(tw_user)
    attrs = {
      user_id:     tw_user.id,
      name:        tw_user.name,
      screen_name: tw_user.screen_name,
      profile_image_url: tw_user.profile_image_url,
    }
    if tw_user = TwitterUser.where(user_id: tw_user.id).first
      tw_user.update_attributes(attrs)
    else
      tw_user = TwitterUser.create(attrs)
    end
    tw_user
  end

end
