# Programming Collective Intelligence
#
# Chapter 11
#
# By Mischa Fierer
#
# http://www.themomorohoax.com
# http://github.com/mischa
#
# In the interest of saving time and being able to reference the book,
# I have not changed too many variable names, etc, nor have I 
# completely translated everything to use Ruby idioms.

require 'rubygems'
require 'feed-normalizer'
require 'open-uri'
require 'spec'
require 'ruby-debug'
require 'nnmf'
require 'formatters'
require 'array_math'

################# Finding features

class FeatureFinder

	FEEDLIST = [
				 'http://feeds.reuters.com/reuters/topNews',
				 'http://feeds.reuters.com/reuters/domesticNews',
				 'http://feeds.reuters.com/reuters/worldNews',
				 # 'http://hosted.ap.org/lineups/TOPHEADS-rss_2.0.xml?SITE=NCWIN&SECTION=HOME',
				 'http://hosted.ap.org/lineups/USHEADS-rss_2.0.xml?SITE=OKPON&SECTION=HOME',
				 # 'http://hosted.ap.org/lineups/WORLDHEADS-rss_2.0.xml?SITE=KLIF&SECTION=HOME',
				 'http://hosted.ap.org/lineups/POLITICSHEADS-rss_2.0.xml?SITE=SCGRE&SECTION=HOME',
				 # 'http://www.nytimes.com/services/xml/rss/nyt/HomePage.xml',
				 # 'http://www.nytimes.com/services/xml/rss/nyt/International.xml',
				 'http://news.google.com/?output=rss',
				 # 'http://feeds.salon.com/salon/news', 
				 # 'http://www.foxnews.com/xmlfeed/rss/0,4313,0,00.rss',
				 # 'http://www.foxnews.com/xmlfeed/rss/0,4313,80,00.rss',
				 # 'http://www.foxnews.com/xmlfeed/rss/0,4313,81,00.rss', 
				 # 'http://rss.cnn.com/rss/edition.rss',
				 # 'http://rss.cnn.com/rss/edition_world.rss', 
				 'http://rss.cnn.com/rss/edition_us.rss',
						] 

	def initialize
		@all_words = Hash.new(0)
		@article_words = Hash.new {|h, k| h[k] = Hash.new(0)}
		@titles = []; @feature_words =[]
		@ec=0
	end

	def data
		get_article_words
		make_matrix
		# weights,features = make_matrix.factorize(10,50)
		weights,features = @matrix.factorize(20,50)
		[@titles, @feature_words, weights,features]
	end


	# Extract invidual words, keeping track of how many times 
	# each word is used overall, 
	# as well as how many times it's used per article
	def get_article_words
		FEEDLIST.each do |feed|
			f = FeedNormalizer::FeedNormalizer.parse open(feed)
			i = 0
			f.entries.each do |entry|
				i += 1
				next if @titles.include?(entry.title)				
				process_entry(entry)
				@ec += 1
			end
			puts "added #{i} entries from #{feed}"
		end
		puts "title len: #{@titles.length}"
		# [@all_words, @article_words, @article_titles] s 
	end

	def process_entry(entry)
		words = "#{entry.title} #{entry.content.strip_html}".separate_words
		@titles << entry.title

		words.each do |word|
			@all_words[word] += 1
			@article_words[@ec][word] += 1
		end
	end

	def make_matrix
		#select words that are common but not too common
		@all_words.each { |word, count| @feature_words << word if count > 3 && count < @article_words.length * 0.6 }

		# Create the word matrix
		matrix = @article_words.map do |index, words| 
			@feature_words.map {|word| (words[word]  && words.include?(word)) ? 1 : 0}
		end
		@matrix = DMatrix[*matrix]
		#[matrix, feature_words]
	end
end


################# Displaying features

class FeatureDisplayer
	
	attr :slist

	def initialize
		ff = FeatureFinder.new
		@titles,@feature_words,@weights,@features = ff.data
	  topp,pn = show_features #(weights,features,titles,@feature_words)
		show_articles(@titles,@toppatterns,pn)
	end

	def show_features(out='features.txt') #(w,h,titles,wordvec,out='features.txt')
		feature_groups = @features.vsize
		@word_count =	@features.hsize

		@toppatterns = []
		@titles.length.times { |i| @toppatterns[i] = []}
		@patternnames = []

		# Loop over all the features		
		File.open(out, 'w') { |results| feature_groups.times { |i|  process_feature(i, results)}}

		@toppatterns = @toppatterns.reject{|a| a.empty?}
	  [@toppatterns, @patternnames]
	end

	def process_feature(i, results)

		@weighted_words = []
		
		#create the list of clustered words and their weights
		@word_count.times do |j|
			@weighted_words << [@features[i,j], @feature_words[j]]
		end

		# Print the first six elements
		top_six = @weighted_words.sort!.reverse![0..5].map{|weight_word| weight_word.last}
		results << "Words: [#{top_six.join(", ")}]\n"
		@patternnames << top_six

    # Create a list of articles for this feature		
		flist = []

		@titles.length.times do |j|
			flist << [@weights[j,i+1], @titles[j]]
			@toppatterns[j] << [@weights[j,i], i, @titles[j]]
		end
		
		# debugger

		flist = flist.compact.sort.reverse

		flist[0..2].each do |f|
			results << f.join("  /   ") + "\n"
		end
		debugger
		results << "\n\n"

	end

	def show_articles(titles, toppatterns, patternnames,out='articles.txt')
		File.open(out, 'w') do |results|
			titles.length.times do |j|
				results << titles[j] + "\n"

				toppatterns[j] = toppatterns[j].sort
				toppatterns[j] = toppatterns[j].reverse

				3.times do |i|
					results << toppatterns[j][i][0].to_s + ' ' +
						patternnames[toppatterns[j][i][1]].join(", ") + "\n"
					results << "\n"
				end
			end
		end
	end

end

@fd = FeatureDisplayer.new
