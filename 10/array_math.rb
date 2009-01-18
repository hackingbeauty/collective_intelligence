class Array
  def *(other)
    r = []
    self.each_with_index do |e, i|
      r[i] = (e * other[i])
    end
    r
  end

  def /(other)
    r = []
    self.each_with_index do |e, i|
      r[i] = (e / other[i])
    end
    r
  end
end


describe "multiplying arrays" do

	it "should do simple stuff" do
		([1,2] * [3,4]).should == [3,8] 
	end

end

