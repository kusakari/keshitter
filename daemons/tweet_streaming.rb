require 'open-uri'

Process.daemon(true, true)

streaming_client = Twitter::Streaming::Client.new({
  consumer_key: Settings.consumer_key,
  consumer_secret: Settings.consumer_secret,
  access_token: Settings.access_token,
  access_token_secret: Settings.access_token_secret,
})

def collect_media_urls(object)
  urls = []
  begin
    urls += object.media.flat_map do |m|
      case m
      when Twitter::Media::AnimatedGif
        m.video_info.variants.map { |v| v.url.to_s }
      when Twitter::Media::Photo
        m.media_url.to_s
      else
        nil
      end
    end
    urls += object.urls.flat_map do |u|
      case FastImage.type(u.url.to_s)
      when :bmp, :gif, :jpeg, :png, :webm
        u.expanded_url.to_s
      else
        nil
      end
    end
  rescue => ex
    Rails.logger.error "Media Error: #{ex.message}, " + %!#{ex.backtrace.join("\n")}!
  end
  urls.compact
end

tries = 5
begin
  streaming_client.user do |object|
    case object
    when Twitter::Tweet
      next unless object.retweeted_status.nil?

      TwitterUser.update_or_create_by_object(object.user)
      urls = collect_media_urls(object)
      dir_path = File.join(Rails.root, "public", Settings.media_dir_name, object.id.to_s).to_s
      tweet_data = {
        status_id:   object.id,
        user_id:     object.user.id,
        body:        object.text,
        created_at:  object.created_at,
      }
      unless urls.empty?
        FileUtils.mkdir_p(dir_path)
        tweet_data[:media_uris] = urls.map do |url|
          Pathname.new(object.id.to_s).join(File.basename(url)).to_s
        end.join("\n")
      end
      urls.each do |url|
        File.open(File.join(dir_path, File.basename(url)), 'wb') do |f|
          f.write open(url).read
        end
      end
      Tweet.find_or_create_by(tweet_data)
    when Twitter::Streaming::DeletedTweet
      Tweet.where(status_id: object.id).update_all(deleted_at: Time.current)
    when Twitter::Streaming::Event
      #
    when Twitter::DirectMessage
      #
    when Twitter::Streaming::StallWarning
      #
    end
  end
rescue Twitter::Error::TooManyRequests => error
  reset_in = error.rate_limit.reset_in || 180
  sleep reset_in + 1
  retry
rescue => ex
  # https://github.com/sferik/twitter/issues/535
  if ex.is_a?(EOFError) && (tries -= 1) > 0
    sleep 5
    retry
  end
  Rails.logger.error "Error: #{ex.message}, " + %!#{ex.backtrace.join("\n")}!
end
