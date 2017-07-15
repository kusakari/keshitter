class TweetsController < ApplicationController
  before_action :set_tweet, only: [:show]

  def index
    muted_user_ids = Rails.cache.fetch(:muted_user_ids, expires_in: 1.hour) do
      client = Twitter::REST::Client.new({
        consumer_key: Settings.consumer_key,
        consumer_secret: Settings.consumer_secret,
        access_token: Settings.access_token,
        access_token_secret: Settings.access_token_secret,
      })
      client.muted_ids.attrs[:ids]
    end

    params[:search_type] ||= "all"
    tweet_ar = Tweet.where("user_id not in (?)", muted_user_ids).order("created_at desc")
    if params[:search_type] == "deleted"
      tweet_ar = tweet_ar.where.not(deleted_at: nil)
    end
    if params[:user_id].present?
      tweet_ar = tweet_ar.where(user_id: params[:user_id])
    end
    @tweets = tweet_ar.page(params[:page]).per(20)
  end

  def show
  end

  private

    def set_tweet
      @tweet = Tweet.find(params[:id])
    end
end
