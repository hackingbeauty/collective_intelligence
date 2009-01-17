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
require 'linalg'

################# support

# Add methods for parsing article text
class String

	def strip_html
		gsub(/<\/?[^>]*>/, "")
	end

	def separate_words
		scan(/\w*/).map {|s| s.downcase if s.length > 3}.compact
	end

end

describe 'formatting feeds' do

	it 'should strip html' do
		str = %{<html><body>foo <a href="http://www.foo.com">link</a></body</html>}
		str.strip_html.should == "foo link"
	end

	it "should separate words" do
		"hello there FOOBAR".separate_words.should == %w{hello there foobar}
	end

end

# Add methods for multiplying and dividing arrays
class Array
  def *(other)
    r = []
    self.each_with_index do |e, i|
      r[i] = (e * other[i])
    end
    r
  end

  def /(other)
    r = []
    self.each_with_index do |e, i|
      r[i] = (e / other[i])
    end
    r
  end
end


describe "multiplyin arrays" do

	it "should do simple stuff" do
		([1,2] * [3,4]).should == [3,8] 
	end

end



################# the algorithm

class Linalg::DMatrix

	# Measure how close the features and weights matrix is
	def difcost(computed)
		[*0..vsize-1].inject(0) do |sum, row|
			hsize.times { |column| sum += (self[row,column] - computed[row,column]) ** 2 }
		end
	end

	# Initialize the weight and feature matrices with random values
	def random_matrix(vs, hs)
		Linalg::DMatrix[*([*0..vs].map { |i| [*0..hs].map { |j| (rand * 10).round.to_i } })]
	end

	def factorize(pc=10, iterations=50)
		
		w = random_matrix(vsize-1, pc-1)
		h = random_matrix(pc-1, hsize-1) 
		seed = w * h
		
		iterations.times do |i|
			cost = difcost(seed)
	 
			
			# Terminate if matrix is fully factorized
			break if cost == 0

			# Update feature matrix
			hn = w.transpose * self
			hd = w.transpose * w * h

			h = Linalg::DMatrix[*(h.to_a * hn.to_a / hd.to_a)]

			# Update weights matrix 
			wn = self  * h.transpose
			wd = w * h * h.transpose

			w = Linalg::DMatrix[*(w.to_a * wn.to_a / wd.to_a)]
		end

		[w, h]
	end

end

# Tests from page 263
describe "dealing with matrices" do
	
	it "should provide two matrices that when multiplied are nearly equal to the original matrix" do
		@m1 = Linalg::DMatrix[[1,2,3],[4,5,6]]
		@m2 = Linalg::DMatrix[[1,2],[3,4],[5,6]]
		w,h = (@m1 * @m2).factorize(3,400)
		(w * h).to_a.map{|e| e.map{|ei| ei.round}}.should == (@m1 * @m2).to_a
	end

end


################# Finding features

FEEDLIST = ['http://today.reuters.com/rss/topNews', 
          'http://today.reuters.com/rss/domesticNews',
          'http://today.reuters.com/rss/worldNews', 
          'http://hosted.ap.org/lineups/TOPHEADS-rss_2.0.xml', 
          'http://hosted.ap.org/lineups/USHEADS-rss_2.0.xml', 
          'http://hosted.ap.org/lineups/WORLDHEADS-rss_2.0.xml', 
          'http://hosted.ap.org/lineups/POLITICSHEADS-rss_2.0.xml', 
          'http://www.nytimes.com/services/xml/rss/nyt/HomePage.xml', 
          'http://www.nytimes.com/services/xml/rss/nyt/International.xml', 
          'http://news.google.com/?output=rss', 
          'http://feeds.salon.com/salon/news', 
          'http://www.foxnews.com/xmlfeed/rss/0,4313,0,00.rss', 
          'http://www.foxnews.com/xmlfeed/rss/0,4313,80,00.rss', 
          'http://www.foxnews.com/xmlfeed/rss/0,4313,81,00.rss', 
          'http://rss.cnn.com/rss/edition.rss', 
          'http://rss.cnn.com/rss/edition_world.rss', 
          'http://rss.cnn.com/rss/edition_us.rss'] 





class FeatureFinder
	# Extract invidual words, keeping track of how many times 
	# each word is used overall, 
	# as well as how many times it's used per article
	def get_article_words
		# article words is the words hashed by article  
		all_words = Hash.new(0)
		article_words = Hash.new {|h, k| h[k] = Hash.new(0)}
		article_titles =[]
		ec=0
		
		FEEDLIST.each do |feed|
			
			f = FeedNormalizer::FeedNormalizer.parse open(feed)
			next if f.nil?
			f.entries.each do |post|
				next if article_titles.include?(post.title)

				txt = post.title + post.content.strip_html
				words = separate_words(txt)
				article_titles << post.title

				words.each do |word|
					all_words[word] += 1
					article_words[ec][word] += 1
				end
				
				ec += 1
			end

		end
		
		[all_words, article_words, article_titles]  
	end


	def make_matrix(all_words, article_words)
		wordvec =[]

		#select words that are common but not too common
		all_words.each do |word, count|
			wordvec << word if count > 3 && count < article_words.length * 0.6
		end

		matrix = article_words.map do |index, words|
			wordvec.map do |word|
				(words[word] > 0) ? 1 : 0
			end
		end
		
		[matrix, wordvec]
	end

	# pg 254 tests
	def test_254(verbose=false)
		@allw,@artw,@artt = get_article_words
		@wordmatrix,@wordvec = make_matrix(@allw,@artw)
		if verbose
			puts @wordvec[0..10]
			puts @artt[1]
			puts @wordmatrix[1][0..10]
		end
	end




	def get_weights
		test_254
		@v = Linalg::DMatrix[*@wordmatrix]
		@weights,@feat = factorize(@v,10,50)
	end

end

class FeatureDisplayer
	def show_features(w,h,titles,wordvec,out='features.txt')
		@h = h
		@w = w
		@wordvec = wordvec
		@titles = titles
		pc,@wc=h.vsize,h.hsize
		@toppatterns = []
		titles.length.times do |i|
			@toppatterns[i] = []
		end
		@patternnames = []



		File.open(out, 'w') do |results|
		
			pc.times do |i|
				process_feature(i, results)
			end

		end
		@toppatterns = @toppatterns.reject{|a| a.empty?}
		[@toppatterns, @patternnames]
	end

	def process_feature(i, results)

		@slist = []
		
		#create a list of words and their weights
		@wc.times do |j|
			@slist << [@h[i,j], @wordvec[j]]
		end

		@slist = @slist.sort.reverse

		n = @slist[0..6].map do |s|
			s[1]
		end

		results << n.join("\n") + "\n"
		@patternnames << n

		flist = []

		@titles.length.times do |j|
			flist[@w[j,i]] = @titles[j]
			@toppatterns[j] << [@w[j,i], i, @titles[j]]
		end

		flist = flist.compact.sort.reverse

		flist[0..2].each do |f|
			results << f.to_s + "\n"
		end
		results << "\n"

	end

	def view_features
		get_weights
		@topp, @pn = show_features(@weights,@feat,@artt,@wordvec)
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


	def by_article
		view_features
		show_articles(@artt, @topp, @pn)
	end


end
