require 'marky_markov'
require 'dotenv'
Dotenv.load

require './db/db'
require './lib/aws'

class Markov

  STOCK_REGEX = /\$[a-zA-Z]/

  def self.generate
    markov = MarkyMarkov::Dictionary.new('dictionary')
    Twit.all.each { |twit| markov.parse_string(twit.body) }
    markov.save_dictionary!
    S3.new.upload(ENV['DICTIONARY'])
  end

  def initialize
    @markov = MarkyMarkov::Dictionary.new('dictionary')
  end

  def sentence
    loop do
      puts "Generating sentence..."

      sentence = create_sentence
      sentence = check_symbol(sentence)
      sentence = scrub_links(sentence)

      next if check_length(sentence)
      next if contains_all_symbols(sentence)

      puts "Validated -> { #{sentence} }"
      break
    end
  end

  private

  def create_sentence
    @markov.generate_n_sentences 1
  end

  def scrub_links(sentence)
    sentence.gsub('http://stks.', '')
  end

  def check_symbol(sentence)
    if sentence =~ STOCK_REGEX
      sentence
    else
      sentence + " $" + ENV['SYMBOLS'].split(',').sample
    end
  end

  def contains_all_symbols(sentence)
    words = sentence.split(" ")
    symbols_count = words.count{ |s| s =~ STOCK_REGEX }
    words.count == symbols_count
  end

  def check_length(sentence)
    sentence.length > 140 || sentence.length < 5
  end
end
