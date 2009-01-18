require 'linalg'
require 'rubygems'
require 'spec'
require 'array_math'
include Linalg


################# the algorithm

class DMatrix

	# Measure how close the features and weights matrix is
	# def difcost(computed)
	# 	i = 0 
	# 	[*0..vsize-1].inject(0) do |sum, row|
	# 		hsize.times do	|column| 
	# 			# puts i if i%1000 == 0
	# 			i += 1
	# 			sum += ((self[row,column] - computed[row,column]) ** 2) 
	# 		end
	# 		sum
	# 	end
	# end
	# def difcost(a,b):

	def difcost(b)
		a = self
		dif=0
		k=0

		for i in (0..a.vsize-1).to_a
			for j in (0..a.hsize-1).to_a
				k += 1
				dif += (a[i,j]-b[i,j]) ** 2
			end
		end
	#	debugger
		return dif
	end

	# Initialize the weight and feature matrices with random values
	def random_matrix(vs, hs)
		DMatrix[*([*0..vs].map { |i| [*0..hs].map { |j| rand  } })]
	end

	def factorize(pc=10, iterations=50, loud=true)
		
		w = random_matrix(vsize-1, pc-1)
		h = random_matrix(pc-1, hsize-1) 
	
		puts "vsize:#{vsize} hsize: #{hsize} pc:#{pc} #"  #w:#{w.vsize}  h:#{h}"
	#	debugger

		iterations.times do |i|
			seed = w*h
			cost = difcost(seed)

			puts "Diffcost: #{cost}" if i % 10 == 0 && loud
			#	debugger if i%10==0
			
			# Terminate if matrix is fully factorized
			break if cost == 0

			# Update feature matrix
			hn = w.transpose * self
			hd = w.transpose * w * h
			# debugger

			h = DMatrix[*(h.to_a * hn.to_a / hd.to_a)]

			# Update weights matrix 
			wn = self  * h.transpose
			wd = w * h * h.transpose

			w = DMatrix[*(w.to_a * wn.to_a / wd.to_a)]
		end

		[w, h]
	end

end


# Tests from page 263

