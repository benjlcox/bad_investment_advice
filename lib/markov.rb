require 'marky_markov'
require 'dotenv'
Dotenv.load

require './db/db'
require './lib/aws'

class Markov

  STOCK_REGEX = /\$[a-zA-Z]/

  def self.generate
    markov = MarkyMarkov::Dictionary.new(ENV['DICTIONARY_NAME'])
    Twit.all.each { |twit| markov.parse_string(twit.body) }
    markov.save_dictionary!
    S3.new.upload(ENV['DICTIONARY_FILE'])
  end

  def initialize
    @markov = MarkyMarkov::Dictionary.new(ENV['DICTIONARY_NAME'])
  end

  def generate_sentence
    loop do
      puts "Generating sentence..."

      @advice = create_sentence
      @advice = check_symbol(@advice)
      @advice = scrub_links(@advice)
      @advice = remove_bad_punctuation(@advice)
      @advice = @advice&.humanize

      next if @advice.nil?
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
    remove_matches(sentence, ['http://stks.', ' chart', /co\/.{5}[\s\z]/, /https*\/\/\w+[\.|\s]/])
  end

  def remove_bad_punctuation(sentence)
    remove_matches(sentence, [/\s\./, /"/, /:/])
  end

  def check_symbol(sentence)
    if name = sentence_has_company_name(sentence)
      symbol = StockTwits::SYMBOLS.invert[name.capitalize]
      sentence + " $" + symbol unless sentence =~ /#{symbol}/
    elsif sentence =~ STOCK_REGEX
      sentence
    else
      sentence + " $" + StockTwits::SYMBOLS.keys.sample
    end
  end

  def sentence_has_company_name(sentence)
    sentence = sentence.downcase.gsub(/\W+/, ' ').split(' ')
    names = StockTwits::SYMBOLS.values.map{|name| name.downcase}

    result = sentence & names
    if result.empty?
      false
    else
      result.sample
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

  def remove_matches(sentence, patterns)
    patterns.each do |pattern|
      break if sentence.nil? || sentence.empty?
      sentence = sentence.gsub(pattern, '')
    end
    sentence
  end
end
