require 'httparty'
require 'json'
require 'dotenv'
Dotenv.load

require './db/db'
require './lib/markov'

class StockTwits
  SYMBOLS = {
    "FB" => 'Facebook',"ETSY" => 'Etsy',"TWTR" => "Twitter","GPRO" => 'GoPro',"AMZN" => 'Amazon',
    "GOOG" => 'Google',"AAPL" => 'Apple',"BBRY" => 'Blackberry',"GRPN" => 'Groupon',"TSLA" => 'Tesla',
    "NFLX" => 'Netflix',"CRM" => 'Salesforce',"BABA" => 'Alibaba',"LNKD" => 'LinkedIn',
    "MSFT" => 'Microsoft',"YHOO" => 'Yahoo'
  }

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

    body = Markov.new.generate_sentence
    url = "https://api.stocktwits.com/api/2/messages/create.json?access_token=#{ENV['STOCKTWITS_TOKEN']}&body=#{body}"

    puts "Sending #{url}"

    response = HTTParty.post(url, :verify => false)

    if response.code != 200
      puts "ERROR (#{response.code}): #{response.body}"
    else
      puts "Post Complete."
    end
  end

  private

  def should_send_message?
    true
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
