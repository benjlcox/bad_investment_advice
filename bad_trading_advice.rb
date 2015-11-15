require 'sinatra'
require './db/db'
require './lib/stocktwits'
require './lib/markov'

get '/' do
  Markov.new.generate_sentence
end

get '/last_ids.json' do
  content_type :json
  Twit.last_ids.to_json
end

get '/messages.json' do
  content_type :json
  Twit.all_twits.to_json
end
