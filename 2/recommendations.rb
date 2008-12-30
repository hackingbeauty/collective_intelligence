#########################################################################################
#########################################################################################
#
# 			Recommendation system
#




@critics = {'Lisa Rose'=> {'Lady in the Water'=> 2.5, 'Snakes on a Plane'=> 3.5,
 'Just My Luck'=> 3.0, 'Superman Returns'=> 3.5, 'You, Me and Dupree'=> 2.5, 
 'The Night Listener'=> 3.0},
'Gene Seymour'=> {'Lady in the Water'=> 3.0, 'Snakes on a Plane'=> 3.5, 
 'Just My Luck'=> 1.5, 'Superman Returns'=> 5.0, 'The Night Listener'=> 3.0, 
 'You, Me and Dupree'=> 3.5}, 
'Michael Phillips'=> {'Lady in the Water'=> 2.5, 'Snakes on a Plane'=> 3.0,
 'Superman Returns'=> 3.5, 'The Night Listener'=> 4.0},
'Claudia Puig'=> {'Snakes on a Plane'=> 3.5, 'Just My Luck'=> 3.0,
 'The Night Listener'=> 4.5, 'Superman Returns'=> 4.0, 
 'You, Me and Dupree'=> 2.5},
'Mick LaSalle'=> {'Lady in the Water'=> 3.0, 'Snakes on a Plane'=> 4.0, 
 'Just My Luck'=> 2.0, 'Superman Returns'=> 3.0, 'The Night Listener'=> 3.0,
 'You, Me and Dupree'=> 2.0}, 
'Jack Matthews'=> {'Lady in the Water'=> 3.0, 'Snakes on a Plane'=> 4.0,
 'The Night Listener'=> 3.0, 'Superman Returns'=> 5.0, 'You, Me and Dupree'=> 3.5},
'Toby'=> {'Snakes on a Plane'=>4.5,'You, Me and Dupree'=>1.0,'Superman Returns' =>4.0}}

def new_example; puts "\n" + "-" * 80; end

# Returns a distance-based similarity score for person1 and person2
# Defines a 2-d pref space, then calculates the distance.
def sim_distance(critics, person1, person2)
	rating_diff = lambda {|title| critics[person1][title] - critics[person2][title]}

	sum_of_squares = critics[person1].inject(0.0) do |sum, rating| 
		critics[person2][rating.first] ? sum + (rating_diff[rating.first] ** 2) : sum
	end
	return "Sum was 0" if sum_of_squares == 0.0

	1 / (1 + sum_of_squares)
end

new_example
test = sim_distance(@critics, 'Lisa Rose', 'Gene Seymour')
puts "#{test} should equal 0.148148148148"
# puts sim_distance(@critics, 'Lisa Rose', 'Claudia Puig')


# Returns the Pearson correlation coefficient for p1 and p2
# Pearson corrects for 'grade inflation'
# values closer to 1 mean higher correlation
def sim_pearson(critics, p1, p2)
	
	# Iterate through each rating in common,
	# Building for each user
	#  1) the sum of all the preferences
	#  2) the sum of all the squares
	# As well as the sum of all the products
	sum1 = sum2 = sum1_sq = sum2_sq = length = 0
	critics[p2][critics[p1].to_a.first.first]
	sum_of_products = critics[p1].inject(0) do |product_sum, rating|
		if critics[p2][rating.first] 
			sum1 += critics[p1][rating.first]
			sum2 += critics[p2][rating.first]
			sum1_sq += critics[p1][rating.first] ** 2
			sum2_sq += critics[p2][rating.first] ** 2
			length += 1
			product_sum + critics[p1][rating.first] * critics[p2][rating.first]
		else
			product_sum
		end
	end
  
	# Do math..
	# Calculate Pearson score
	num = sum_of_products - (sum1 * sum2 / length)
	den = Math.sqrt((sum1_sq - (sum1 ** 2) / length) * (sum2_sq - (sum2 ** 2) / length))

	return "den == 0" if den == 0

	num/den

end

new_example
test = sim_pearson(@critics, 'Lisa Rose', 'Gene Seymour')
puts "#{test} should equal 0.396059017191"

# Returns the best matches for person from the prefs dictionary.
# Number of results is an optional param.
# The similarity method is a block.
def top_matches(critics, person, n=5)
	scores = critics.map do |critic, movies|
		[yield(@critics, person, critic), critic] unless person == critic
	end

	scores.compact.sort.reverse[0..n]

end

new_example
test = top_matches(@critics, 'Toby', 3) { |critics, person, critic| sim_pearson(critics, person, critic) }
puts "#{test.join(", ")} should equal #{[[0.99124070716192991, 'Lisa Rose'], [0.92447345164190486, 'Mick LaSalle'], [0.89340514744156474, 'Claudia Puig']].join(", ")}"


# Gets recommendations for a person by using a weighted average 
# of every other user's rankings 
def get_recommendations(critics, person)
	
	# totalweighted rating of the movies for a given person
	totals = Hash.new(0.0)

	# total similarity of the critics to the given person for the movies
	sim_sums = Hash.new(0.0)

	#for each of the critics...
	critics.each do |critic, movies|
		next if critic == person

		# find the similarity between the given person and the critic
		sim = block_given? ? yield(critics, person, critic) : sim_pearson(critics, person, critic)
		
		next if sim <= 0

		#for each of the similar critics' critics
		critics[critic].each do |title, rating|
			next if critics[person][title] 

			# add a rating based on the similarity of the person to the critic
			# to the sum of critics for the given title
			totals[title] += critics[critic][title] * sim
			# and add the similarity to the total similarity sum for that title
			sim_sums[title] += sim
		end
	end

	# create an array of rankings by...
	#	dividing each total ranking by the total similarity of all critics of that movie
	#	to normalize the rankings, so that movies reviewed by a lot of critics
	#	aren't given a big advantage
	rankings = totals.map {|movie, total| [total/sim_sums[movie], movie] }
	rankings.sort.reverse
end

new_example
test = get_recommendations(@critics, 'Toby')
puts "#{test.join(", ")} should equal [(3.3477895267131013, 'The Night Listener'), (2.8325499182641614, 'Lady in the Water'), (2.5309807037655645, 'Just My Luck')]"



#########################################################################################
#########################################################################################




