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
