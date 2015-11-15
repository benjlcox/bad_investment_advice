require './bad_trading_advice'
require './lib/aws'
require 'dotenv'

Dotenv.load
S3.new.download(ENV['DICTIONARY'])
run Sinatra::Application
