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
      url = u.url.to_s
      case FastImage.type(url)
      when :bmp, :gif, :jpeg, :png, :webm
        u.expanded_url.to_s
      else
        if url.start_with?("https://www.instagram.com/p/")
          "#{url}media/?size=l"
        else
          nil
        end
      end
    end
  rescue => ex
    Rails.logger.error "Media Error: #{ex.message}, " + %!#{ex.backtrace.join("\n")}!
  end
  urls.compact
end

begin
  list_user_ids = Rails.cache.fetch(:list_user_ids, expires_in: 1.hour) do
    client = Twitter::REST::Client.new({
      consumer_key: Settings.consumer_key,
      consumer_secret: Settings.consumer_secret,
      access_token: Settings.access_token,
      access_token_secret: Settings.access_token_secret,
    })
    list = client.owned_lists(count: 100).detect {|list| list.name == Settings.streaming_list_name }
    client.list_members(list.id, count: 1000).map(&:id)
  end
#  streaming_client.user do |object|
  streaming_client.filter(follow: list_user_ids.join(",")) do |object|
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
          begin
            f.write open(url).read
          rescue => e
            f.write ""
          end
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
rescue EOFError =>  eofe
  # https://github.com/sferik/twitter/issues/535
  Rails.logger.error "EOFError: #{eofe.message}, " + %!#{eofe.backtrace.join("\n")}!
  retry
rescue => ex
  Rails.logger.error "Error: #{ex.message}, " + %!#{ex.backtrace.join("\n")}!
end
