require 'rubygems'
require 'feed-normalizer'
require 'open-uri'
require 'ruby-debug'
require 'gsl'
include GSL

FEEDLIST= [
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

def stripHTML(h)
	p=''
	s=0
	for c in h.split(//)
		if c=='<'
			s=1
		elsif c=='>'
			s=0
			p += ' '
		elsif s==0
			p+=c
		end	
	end
	 p
end

def separatewords(text)
	text.scan(/\w*/).select{|s| s.length>3}.map{|s| s.downcase}
end

def getarticlewords
	allwords={}
	articlewords=[]
	articletitles=[]
	ec=0
	# Loop over every feed
	for feed in FEEDLIST
		f=FeedNormalizer::FeedNormalizer.parse open(feed)

		# Loop over every article
		i=0
		for e in f.entries
			i += 1
			# Ignore identical articles
			next if articletitles.include?(e.title)
			
			# Extract the words
			txt = e.title + stripHTML(e.content)
			words = separatewords(txt)
			articlewords << {}
			articletitles << e.title

      # Increase the counts for this word in allwords and in articlewords
			for word in words
				allwords[word] ||= 0
				allwords[word] += 1
				articlewords[ec][word] ||= 0
				articlewords[ec][word] += 1
			end			
			ec += 1
		end
	end
	[allwords, articlewords, articletitles]
end

def makematrix(allw, articlew)
	wordvec = []

  # Only take words that are common but not too common
	for w,c in allw
		if c > 3 and c < articlew.length*0.6
			wordvec << w
		end
	end
	
  # Create the word matrix		
	l1 = articlew.map{|f| wordvec.map{|word| (f.include?(word) && f[word]) || 0}}
	return [l1, wordvec]
end

def showfeatures(w,h,titles,wordvec,out='features.txt')
	File.open(out, 'w') do |outfile|
		pc,wc=h.shape
		toppatterns=[*0..titles.length].map{|i| []}
		patternnames =[]
	
  	# Loop over all the features
		pc.times do |i|
			slist=[]

			# Create a list of words and their weights
			wc.times do |j|
				slist << [h[i,j], wordvec[j]]
			end

			slist.sort!
			slist.reverse!

			# Print the first six elements
			n = slist[0..5].map{|s| s[1]}
			outfile << n.join(", ") + "\n"
			patternnames << n

			# Create a list of articles for this feature
			flist = []
			titles.length.times do |j|
				# Add the article with its weight
				flist << [w[j,i].round.to_i, titles[j]]
				toppatterns[j] << [w[j,i], i, titles[j]]
			end

			# Reverse sort the list
			flist.sort!
			flist.reverse!

			flist[0..2].each do |f|
				outfile << f.join("\t\t") + "\n"
			end
			outfile << "\n\n\n"
			
		end # pc.times
		[toppatterns, patternnames]		
	end # File.open 
end

