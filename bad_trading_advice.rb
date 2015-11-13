require 'sinatra'
require './stocktwits'

get '/' do
  StockTwits.new_sentence
end

get '/last_ids' do
  JSON.parse(File.read('last_ids.json'))
end

get '/messages' do
  File.read('twits.txt')
end
