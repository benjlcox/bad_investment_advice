require 'httparty'
require 'json'
require 'redis'
require 'sidekiq'
require 'sidekiq/api'
require 'dotenv'
Dotenv.load

require './db/db'
require './lib/markov'
require './workers/post_worker'
$redis = Redis.new(url: ENV["REDIS_URL"])

class StockTwits
  SYMBOLS = {
    "FB" => 'Facebook',"ETSY" => 'Etsy',"TWTR" => "Twitter","GPRO" => 'GoPro',"AMZN" => 'Amazon',
    "GOOG" => 'Google',"AAPL" => 'Apple',"BBRY" => 'Blackberry',"GRPN" => 'Groupon',"TSLA" => 'Tesla',
    "NFLX" => 'Netflix',"CRM" => 'Salesforce',"BABA" => 'Alibaba',"LNKD" => 'LinkedIn',
    "MSFT" => 'Microsoft',"YHOO" => 'Yahoo'
  }

  POSTING_WINDOW = { start: Time.parse("9:30 am EST"), finish: Time.parse("4:45 pm EST") }

  def self.fetch_twits
    last_ids = last_message_ids

    SYMBOLS.keys.each do |symbol|
      params = "?since=#{last_ids[symbol]}" unless last_ids[symbol].nil?
      url = "https://api.stocktwits.com/api/2/streams/symbol/#{symbol}.json#{params}"
      puts "Fetching #{symbol} with #{url}"
      response = HTTParty.get(url, :verify => false)

      if response['messages'].empty?
        puts "Empty. Skipping."
        next
      end

      save_to_db(response)
    end
  end

  def self.post_message
    return unless should_send_message?

    delay = (1..60).to_a.sample

    if ENV['RACK_ENV'] == 'production'
      puts "POST QUEUED FOR #{delay} MINUTES"
      PostWorker.perform_in(delay.minutes)
    else
      post_dev_message(delay)
    end
  end

  def self.post_to_twits
    message = Markov.new.generate_sentence
    url = "https://api.stocktwits.com/api/2/messages/create.json?access_token=#{ENV['STOCKTWITS_TOKEN']}&body=#{message}"

    puts "Sending #{url}"

    response = HTTParty.post(url, :verify => false)

    if response.code != 200
      puts "ERROR (#{response.code}): #{response.body}"
    else
      puts "Post Complete."
    end
  end

  private

  def self.post_dev_message(delay)
    message = Markov.new.generate_sentence
    puts "Delay: #{delay}, Message: << #{message} >>"
  end

  def self.should_send_message?
    if (1..3).to_a.sample > 1 && in_posting_window?
      true
    else
      puts 'Post skipped.'
      false
    end
  end

  def self.in_posting_window?
    time = Time.now.in_time_zone('Eastern Time (US & Canada)')
    time > POSTING_WINDOW[:start] && time < POSTING_WINDOW[:finish]
  end

  def self.last_message_ids
    SYMBOLS.keys.each_with_object({}) do |symbol, obj|
      obj[symbol] = Twit.where(stock: symbol).maximum(:key)
    end
  end

  def self.save_to_db(response)
    response['messages'].each do |message|
      Twit.create(
        stock: response['symbol']['symbol'],
        key: message['id'],
        body: message['body']
      )
    end
  end
end
