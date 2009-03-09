require 'open-uri'
require 'rubygems'
require 'hpricot'

class Crawler

	IGNORE_WORDS = ['the','of','to','and','a','in','is','it']

	def initialize(dbname)
		puts 'New crawler created'
	end

	def self.del
		#pass
	end

	def dbcommit

	end

	def getentryid(table, field, value, create_new=true)
		nil
	end

	def addtoindex(url, soup)
		puts "Indexing #{url}"
	end

	def gettextonly(soup)
		nil
	end

	def separatewords(text)
		nil
	end

	def isindex(url)
		false
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

				soup = Hpricot(c) 
				self.addtoindex(page, soup)

				links = soup.search('a')

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
		#pass
	end

end


c = Crawler.new('')

c.crawl(['http://kiwitobes.com/wiki/Perl.html'])



