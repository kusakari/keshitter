class Tweet < ApplicationRecord
  belongs_to :twitter_user, primary_key: "user_id", foreign_key: "user_id"

  def self.find_or_create_by_object(tw)
    attrs = {
      status_id:   tw.id,
      user_id:     tw.user.id,
      body:        tw.text,
      created_at:  tw.created_at,
    }
    if tweet = Tweet.where(status_id: tw.id).first
      tweet.update_attributes(attrs)
    else
      tweet = Tweet.create(attrs)
    end
    tweet
  end

end
