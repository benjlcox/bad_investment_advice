require 'httparty'
require 'marky_markov'
require 'json'

class StockTwits
  SYMBOLS = %w( SHOP FB ETSY TWTR GPRO AMZN GOOG AAPL BBRY GRPN TSLA NFLX CRM BABA )

  def self.fetch_twits
    last_ids = last_message_ids

    SYMBOLS.each do |symbol|
      puts "Fetching #{symbol}..."
      response = HTTParty.get("https://api.stocktwits.com/api/2/streams/symbol/#{symbol}.json?since=#{last_message_ids[symbol]}", :verify => false)

      if response['messages'].empty?
        puts "Empty. Skipping."
        next
      end

      record_last_id(symbol, response)
      save_to_file(response)
    end
  end

  def self.generate_markov
    markov = MarkyMarkov::Dictionary.new('dictionary')
    markov.parse_file('twits.txt')
    markov.save_dictionary!
  end

  def self.new_sentence
    markov = MarkyMarkov::Dictionary.new('dictionary')
    markov.generate_n_sentences 1
  end

  private

  def self.record_last_id(symbol, response)
    file = File.read('last_ids.json')
    ids = JSON.parse(file)
    ids[symbol] = response['messages'].first['id'].to_s
    File.open('last_ids.json', 'w') {|f| f.write(ids.to_json) }
  end

  def self.last_message_ids
    file = File.exists?('last_ids.json') ? File.read('last_ids.json') : File.open('last_ids.json', 'w'){|f| f.write('{}')}
    JSON.parse(File.read(file))
  end

  def self.save_to_file(response)
    File.open('twits.txt', 'a') do |file|
      response['messages'].each do |message|
        file.puts message['body']
      end
    end
  end
end
