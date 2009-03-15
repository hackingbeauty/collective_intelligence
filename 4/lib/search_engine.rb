require 'open-uri'
require 'rubygems'
require 'hpricot'
require 'sqlite3'
require 'ruby-debug'

class Crawler

	IGNORE_WORDS = ['the','of','to','and','a','in','is','it']

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
c = Crawler.new('searchindex.db')
#c.createindextables

#c.crawl(['http://kiwitobes.com/wiki/Perl.html'])
# load 'search_engine.rb'
#c.crawl(['http://kiwitobes.com/wiki/Categorical_list_of_programming_languages.html'])


class Searcher

	def initialize(dbname)
		SQLite3::Database.new(dbname)
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
		wordrow = @con.execute(%Q{select rowid from wordlist where word='#{word}'})
		if wordrow != nil
		wordid = wordrow[0]
		wordids << wordid
		if tablenumber > 0
			tablelist += ','
			clauselist += ' and '
			clauselist += %{w#{tablenumber-1}}.urlid and 'tablenumber-1, tablenumber
			# fieldlist += 
		end
	end

end
