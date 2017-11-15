require 'httparty'
require 'json'
require 'cgi'
require 'redis'
require 'sidekiq'
require 'sidekiq/api'
require 'holidays'
require 'dotenv'
require 'byebug'
Dotenv.load

require './db/db'
require './lib/markov'
require './workers/post_worker'
require './workers/like_worker'
$redis = Redis.new(url: ENV["REDIS_URL"])

class StockTwits
  BASE_URL = "https://api.stocktwits.com/api/2"
  SYMBOLS = {
    "FB" => 'Facebook',"ETSY" => 'Etsy',"TWTR" => "Twitter","GPRO" => 'GoPro',"AMZN" => 'Amazon',
    "GOOG" => 'Google',"AAPL" => 'Apple',"BBRY" => 'Blackberry',"GRPN" => 'Groupon',"TSLA" => 'Tesla',
    "NFLX" => 'Netflix',"CRM" => 'Salesforce',"BABA" => 'Alibaba',"LNKD" => 'LinkedIn',
    "MSFT" => 'Microsoft',"AABA" => 'Altaba', "MDB" => 'MongoDB', "ROKU" => 'Roku'
  }

  CURRENT_TIME = Time.now.in_time_zone('Eastern Time (US & Canada)')
  POSTING_WINDOW = { start: Time.parse("9:30 am EST"), finish: Time.parse("4:45 pm EST") }

  def fetch_twits
    last_ids = last_message_ids

    SYMBOLS.keys.each do |symbol|
      params = "since=#{last_ids[symbol]}&" unless last_ids[symbol].nil?
      url = "https://api.stocktwits.com/api/2/streams/symbol/#{symbol}.json?#{params}access_token=#{ENV['STOCKTWITS_TOKEN']}"
      puts "Fetching #{symbol} with #{url}"
      response = HTTParty.get(url, :verify => false)

      if response.code == 429
        puts 'Rate limit exceeded'
        break
      end

      if response['messages'].empty?
        puts "Empty. Skipping."
        next
      end

      save_to_db(response)
      send_likes(response['messages'])
    end
  end

  def post_message
    return unless should_send_message?

    rand(1..3).times do |i|
      delay = rand(1..60)

      if ENV['RACK_ENV'] == 'production'
        puts "POST QUEUED FOR #{delay} MINUTES"
        PostWorker.perform_in(delay.minutes)
      else
        post_dev_message(delay)
      end
    end
  end

  def post_message_now
    if ENV['RACK_ENV'] == 'production'
      PostWorker.new.perform
    else
      post_dev_message
    end
  end

  def post_to_twits
    message = Markov.new.generate_sentence
    sentiment = choose_sentiment
    url = "#{BASE_URL}/messages/create.json?access_token=#{ENV['STOCKTWITS_TOKEN']}"\
      "&body=#{CGI.escape(message)}"\
      "&sentiment=#{sentiment}"

    puts "Sending #{url}"

    response = HTTParty.post(url, :verify => false)

    if response.code != 200
      puts "ERROR (#{response.code}): #{response.body}"
    else
      puts "Post Complete."
    end
  end

  def send_likes(messages)
    messages.each do |message|
      next unless rand(1..100) == 1

      delay = rand(1..30)
      puts "Liking #{message['id']} in #{delay} minutes"

      if ENV['RACK_ENV'] == 'production'
        LikeWorker.perform_in(delay.minutes, message['id'])
      else
        "Like message: #{message['id']}"
      end
    end
  end

  def post_like(id)
    url = "#{BASE_URL}/messages/like.json?access_token=#{ENV['STOCKTWITS_TOKEN']}"

    HTTParty.post(url, { body: "id=#{id}" })
  end

  private

  def post_dev_message(delay=0)
    message = Markov.new.generate_sentence
    puts "Delay: #{delay}, Message: << #{message} >>"
  end

  def should_send_message?
    if !in_posting_window? || is_a_weekend? || is_an_american_holiday?
      puts 'Posting conditions not met.'
      false
    else
      true
    end
  end

  def in_posting_window?
    CURRENT_TIME > POSTING_WINDOW[:start] && CURRENT_TIME < POSTING_WINDOW[:finish]
  end

  def is_a_weekend?
    CURRENT_TIME.saturday? || CURRENT_TIME.sunday?
  end

  def is_an_american_holiday?
    Date.current.holiday?(:us)
  end

  def choose_sentiment
    if rand(1..3) === 1
      ['bearish', 'bullish'].sample
    else
      'neutral'
    end
  end

  def last_message_ids
    SYMBOLS.keys.each_with_object({}) do |symbol, obj|
      obj[symbol] = Twit.where(stock: symbol).maximum(:key)
    end
  end

  def save_to_db(response)
    response['messages'].each do |message|
      Twit.create(
        stock: response['symbol']['symbol'],
        key: message['id'],
        body: message['body']
      )
    end
  end
end
