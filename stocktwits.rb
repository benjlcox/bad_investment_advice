require 'httparty'
require 'marky_markov'
require 'json'
require './db/db'

class StockTwits
  SYMBOLS = %w( SHOP FB ETSY TWTR GPRO AMZN GOOG AAPL BBRY GRPN TSLA NFLX CRM BABA )

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

      save_to_file(response)
    end
  end

  def self.generate_markov
    markov = MarkyMarkov::Dictionary.new('dictionary')
    Twit.all.each { |twit| markov.parse_string(twit.body) }
    markov.save_dictionary!
  end

  def self.new_sentence
    markov = MarkyMarkov::Dictionary.new('dictionary')
    markov.generate_n_sentences 1
  end

  private

  def self.last_message_ids
    SYMBOLS.each_with_object({}) do |symbol, obj|
      obj[symbol] = Twit.where(stock: symbol).maximum(:key)
    end
  end

  def self.save_to_file(response)
    response['messages'].each do |message|
      Twit.create(
        stock: response['symbol']['symbol'],
        key: message['id'],
        body: message['body']
      )
    end
  end
end
