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

  def generate_sentence
    loop do
      puts "Generating sentence..."

      @advice = create_sentence
      @advice = check_symbol(@advice)
      @advice = scrub_links(@advice)
      @advice = remove_bad_periods(@advice)

      next if check_length(@advice)
      next if contains_all_symbols(@advice)

      puts "Validated -> { #{@advice} }"
      break
    end
    @advice
  end

  private

  def create_sentence
    @markov.generate_n_sentences 1
  end

  def scrub_links(sentence)
    sentence = sentence.gsub('http://stks.', '')
    sentence.gsub(' chart', '')
  end

  def remove_bad_periods(sentence)
    sentence.gsub(/\s\./, '')
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
