module TweetsHelper
  def twitter_status_url(screen_name: nil, status_id: nil)
    "https://twitter.com/#{screen_name}/status/#{status_id}"
  end

  def twitter_user_url(user_id)
    "https://twitter.com/intent/user?user_id=#{user_id}"
  end

  def keshitter_media_urls(tweet)
    return "" if tweet.media_uris.nil?
    tweet.media_uris.split("\n").map do |uri|
      "#{request.protocol}#{request.host_with_port}" + Pathname.new("/").join(Settings.media_dir_name, uri).to_s
    end.join("\n")
  end
end
