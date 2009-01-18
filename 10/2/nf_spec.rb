require 'rubygems'
require 'spec'
require 'newsfeatures'
require 'nnmf'

describe "stripping html" do
	it "should strip html" do
		stripHTML("<a>foo</a>bar<strong><a>baz</a></strong>").should == ' foo bar  baz  '
	end	
end

describe "separating words" do
	it "shoudl separate words" do
		separatewords("hello I am a bunch. of, words").should == ['hello', 'bunch', 'words']
	end
end

describe "dealing with matrices" do
	
	it "should provide two matrices that when multiplied are nearly equal to the original matrix" do
		@m1 = DMatrix[[1,2,3],[4,5,6]]
		@m2 = DMatrix[[1,2],[3,4],[5,6]]
		w,h = factorize(@m1*@m2, 3,100)
		(w * h).to_a.map{|e| e.map{|ei| ei.round}}.should == (@m1 * @m2).to_a
	end

end

allw,artw,artt= getarticlewords
wordmatrix,wordvec= makematrix(allw,artw)
v=DMatrix[*wordmatrix]

weights,feat = factorize(v,pc=20,iter=50)
topp,pn= showfeatures(weights,feat,artt,wordvec)

