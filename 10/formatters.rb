# Add methods for parsing article text
class String

	def strip_html
		gsub(/<\/?[^>]*>/, " ")
	end

	def separate_words
		scan(/\w*/).select {|s| s.length > 3}.map{|s| s.downcase}
	end

end

