require 'sinatra'
require 'httparty'
require 'byebug'
require 'marky_markov'

SYMBOLS = %w( SHOP FB ETSY TWTR GPRO AMZN GOOG AAPL BBRY GRPN TSLA NFLX CRM BABA )

helpers do
  def fetch_twits(symbol)
    response = HTTParty.get("https://api.stocktwits.com/api/2/streams/symbol/#{symbol}.json", :verify => false)

    File.open('twits.txt', 'a') do |file|
      response['messages'].each do |message|
        file.puts message['body']
      end
    end
  end

  def generate_markov
    markov = MarkyMarkov::Dictionary.new('dictionary')
    markov.parse_file('twits.txt')
    markov.save_dictionary!
  end

  def return_sentence
    markov = MarkyMarkov::Dictionary.new('dictionary')
    markov.generate_n_sentences 1
  end
end

get '/fetch' do
  SYMBOLS.each do |symbol|
    puts "Fetching #{symbol}..."
    fetch_twits(symbol)
  end
  generate_markov
  puts "-------------------"
  "Done."
end

get '/' do
  return_sentence
end
