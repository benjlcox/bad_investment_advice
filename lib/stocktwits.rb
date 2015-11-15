require 'httparty'
require 'json'
require 'dotenv'
Dotenv.load

require './db/db'

class StockTwits
  SYMBOLS = ENV['SYMBOLS'].split(',')

  def self.fetch_twits
    last_ids = last_message_ids

    SYMBOLS.each do |symbol|
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

  private

  def self.last_message_ids
    SYMBOLS.each_with_object({}) do |symbol, obj|
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
