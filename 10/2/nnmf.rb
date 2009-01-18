require 'linalg'
include Linalg
load '../array_math.rb'

class Linalg::DMatrix
	def shape
		[vsize,hsize]
	end
end

def difcost(a,b)
	dif=0
	a.shape[0].times do |i|
		a.shape[1].times do |j|
      # Euclidean Distance			
			dif += (a[i,j]-b[i,j]) ** 2
		end
	end
	dif
end


def factorize(v, pc=10, iter=50)
	ic = v.shape[0]
	fc = v.shape[1]

  # Initialize the weight and feature matrices with random values	
	w = DMatrix[*[*0..ic-1].map{|i| [*0..pc-1].map{|j| rand}}]
	h = DMatrix[*[*0..pc-1].map{|i| [*0..fc-1].map{|j| rand}}]

	iter.times do |i|
		wh = w * h
		
    # Calculate the current difference		
		cost = difcost(v,wh)

		puts cost if i % 10 == 0

    # Terminate if the matrix has been fully factorized
		break if cost == 0

    # Update feature matrix
		hn = w.transpose * v
		hd = w.transpose * w * h

		h = DMatrix[*(h.to_a * hn.to_a / hd.to_a)]

    # Update weights matrix
		wn = v * h.transpose
		wd = w * h * h.transpose

		w = DMatrix[*(w.to_a * wn.to_a / wd.to_a)]
	end

	[w, h]
end
