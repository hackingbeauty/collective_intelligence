require 'open-uri'
require 'rubygems'
require 'hpricot'
require 'sqlite3'
require 'ruby-debug'

class Crawler

	IGNORE_WORDS = ['the','of','to','and','a','in','is','it']

	attr_accessor :con

	def initialize(dbname)
		@con = SQLite3::Database.new(dbname)
	end

	def self.del
		@con.close
	end

	def dbcommit
		@con.commit
	end

	def getentryid(table, field, value, create_new=true)
		cur = @con.execute(%Q{select rowid from #{table} where #{field}='#{value}'})
		#debugger
		res = cur.first
		if res == nil
			@con.execute(%Q{insert into #{table} (#{field}) values ('#{value}')})
			cur = @con.execute(%Q{select rowid from #{table} where #{field}='#{value}'})
			return cur.last
		else
			res[0]
		end
	end

	def addtoindex(url, soup)
		return if isindexed(url)

		puts "Indexing #{url}"
		
		# Get the individual words
		
		text = gettextonly(soup)
		words = separatewords(text)
		
		# Get the url id
		urlid = getentryid('urllist', 'url', url)

		# Link each word to this url
		0.upto(words.length) do |i|
			word = words[i]
			next if IGNORE_WORDS.include?(word)
			
			wordid = getentryid('wordlist', 'word', word)
			@con.execute(%Q{insert into wordlocation(urlid,wordid,location) values (#{urlid},#{wordid},#{i})})

		end
		
	end

	def gettextonly(soup)
		resulttext = ''
		#debugger
		soup.traverse_text do |t|
			resulttext += "#{t}\n"	
		end
		resulttext
	end

	def separatewords(text)
		captures = text.scan(/(\w*)/)
		return unless captures
		captures.flatten.reject{|w| w == ""}.map{|w| w.downcase}	
	end

	def isindexed(url)
		#debugger
		u = @con.execute(%Q{select rowid from urllist where url='#{url}'}).first
		if u != nil
			# Check if it has actually been crawled
			v = @con.execute(%Q{
				select * from wordlocation where urlid=#{u[0]}}).first
			return true if v != nil
		end
		return false
	end

	def addlinkref(url_from, url_to, link_text)
		#pass
	end

	def crawl(pages, depth=2)
		depth.times do 
			newpages = []
			pages.each do |page|
				begin
					c = open(page)
				rescue
					puts "Could not open #{page}"
					next
				end
				
				#debugger
				soup = Hpricot(c.read) 
				self.addtoindex(page, soup)

				links = soup.search('a')

				@con.transaction

				links.each do |link|
					if link.attributes.include?("href")
						url = URI::join(page, link['href'])
						# 	not sure what this does...
					  # 	if url.find("'")!=-1: continue 
						url = url.to_s.split('#')[0]
						if URI::split(url.to_s)[0] == 'http'
							newpages << url
						end
						linkText = self.gettextonly(link)
						self.addlinkref(page, url, linkText)
					end
				end
				self.dbcommit
			end
		pages = newpages
		end
	end

	def createindextables
		@con.transaction
		@con.execute('create table urllist(url)') 
		@con.execute('create table wordlist(word)') 
		@con.execute('create table wordlocation(urlid,wordid,location)') 
		@con.execute('create table link(fromid integer,toid integer)') 
		@con.execute('create table linkwords(wordid,linkid)') 
		@con.execute('create index wordidx on wordlist(word)') 
		@con.execute('create index urlidx on urllist(url)') 
		@con.execute('create index wordurlidx on wordlocation(wordid)') 
		@con.execute('create index urltoidx on link(toid)') 
		@con.execute('create index urlfromidx on link(fromid)') 
		@con.commit
	end

end


#system('rm searchindex.db')
@c = Crawler.new('searchindex.db')
#c.createindextables

#c.crawl(['http://kiwitobes.com/wiki/Perl.html'])
# load 'search_engine.rb'
#c.crawl(['http://kiwitobes.com/wiki/Categorical_list_of_programming_languages.html'])


class Searcher

	def initialize(dbname)
		@con = SQLite3::Database.new(dbname)
	end

	def del
		@con.close
	end

	def getmatchrows(q)
		
		# Strings to build the query
		fieldlist = 'w0.urlid'
		tablelist=''
		clauselist=''
		wordids = []		

		# Split the words by spaces
		words = q.split(' ')
		tablenumber = 0

		words.each do |word|
			# get the word ID
			wordrow = @con.execute(%Q{select rowid from wordlist where word='#{word.downcase}'})
			if wordrow != nil
				wordid = wordrow[0]
				wordids << wordid
				if tablenumber > 0
					tablelist += ','
					clauselist += ' and '
					clauselist += %Q|w#{tablenumber - 1}.urlid=w#{tablenumber}.urlid and |
				end
				fieldlist += ", w#{tablenumber}.location"
				tablelist += "wordlocation w#{tablenumber}"
				clauselist += "w#{tablenumber}.wordid=#{wordid}"
				tablenumber += 1
			end
		end
		
		fullquery = "select #{fieldlist} from #{tablelist} where #{clauselist}"
		cur = @con.execute(fullquery)
		rows = cur #?
		
		[rows, wordids]
	end

	def getscoredlist(rows, wordids)
		totalscores = rows.inject({}){|h, k| h[k[0]] = 0; h}
		#
		#debugger
		
		weights  = [[1.0, frequencyscore(rows)],
								[1.5, locationscore(rows)],
								[0.8, distancescore(rows)]
								]

		weights.each do |weight, scores|
			totalscores.each do |key, value|
				totalscores[key] += weight * (scores[key] || 0)
			end
		end

		totalscores
	end

	def normalizescores(scores, smallIsBetter=false)
		vsmall = 0.00001
		hash = {}

		if smallIsBetter
			minscore = scores.values.min
			scores.each {|u, l| hash[u] = minscore.to_f / [vsmall, l].max}
		else
			maxscore = scores.values.max
			maxscore = vsmall if maxscore.zero?
			scores.each {|u, c| hash[u] = c.to_f / maxscore } 
		end

		hash
	end

	def frequencyscore(rows)
		counts = rows.inject({}){|h, k| h[k[0]] = 0; h}

		rows.each {|row| counts[row[0]] += 1}
		normalizescores(counts)
	end

	def locationscore(rows)
		locations = rows.inject({}){|h, k| h[k[0]] = 1000000; h}
		rows.each do |row|
			loc = row[1..-1].inject(0){|sum, n| sum += n.to_i}
			locations[row[0]] = loc if loc < locations[row[0]]
		end

		normalizescores(locations, true)
	end

	def distancescore(rows)
		return rows.inject({}){|h,k| h[k[0]] = 1.0} if rows[0].length <= 2	

		mindistance = rows.inject({}){|h,k| h[k[0]] = 100000; h}

		rows.each do |row|
			dist = [*2..row.length].map{|i| (row[i].to_i - row[i-1].to_i).abs}.inject(0){|sum, n| sum += n}
			mindistance[row[0]] = dist if dist < mindistance[row[0]]
		end

		normalizescores(mindistance, true)
	end

	def geturlname(id)
		@con.execute("select url from urllist where rowid=#{id}").first[0]
	end

	def query(q)
		rows,wordids = getmatchrows(q)
		scores = getscoredlist(rows,wordids)
		rankedscores = scores.map do |url, score|
			[score,url]	
		end.sort_by{|score, url| score}.reverse

		rankedscores[0..10].each do |score, urlid|
			puts "#{score}\t#{geturlname(urlid)}"
		end
	end

end


@searcher = Searcher.new('searchindex.db')
