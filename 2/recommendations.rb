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


# Returns a distance-based similarity score for person1 and person2
# Defines a 2-d pref space, then calculates the distance.
def sim_distance(ratings, person1, person2)
	rating_diff = lambda {|title| ratings[person1][title] - ratings[person2][title]}

	sum_of_squares = ratings[person1].inject(0.0) do |sum, rating| 
		ratings[person2][rating.first] ? sum + (rating_diff[rating.first] ** 2) : sum
	end
	return "Sum was 0" if sum_of_squares == 0.0

	1 / (1 + sum_of_squares)
end

test = sim_distance(@critics, 'Lisa Rose', 'Gene Seymour')
puts "#{test} should equal 0.148148148148"
# puts sim_distance(@critics, 'Lisa Rose', 'Claudia Puig')


# Returns the Pearson correlation coefficient for p1 and p2
# Pearson corrects for 'grade inflation'
# values closer to 1 mean higher correlation
def sim_pearson(ratings, p1, p2)
	
	# Iterate through each rating in common,
	# Building for each user
	#  1) the sum of all the preferences
	#  2) the sum of all the squares
	# As well as the sum of all the products
	sum1 = sum2 = sum1_sq = sum2_sq = length = 0

	sum_of_products = ratings[p1].inject(0) do |product_sum, rating|
		if ratings[p2][rating.first] 
			sum1 += ratings[p1][rating.first]
			sum2 += ratings[p2][rating.first]
			sum1_sq += ratings[p1][rating.first] ** 2
			sum2_sq += ratings[p2][rating.first] ** 2
			length += 1
			product_sum + ratings[p1][rating.first] * ratings[p2][rating.first]
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

test = sim_pearson(@critics, 'Lisa Rose', 'Gene Seymour')
puts "#{test} should equal 0.396059017191"

