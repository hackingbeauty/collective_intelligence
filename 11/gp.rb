# Ruby 1.9.1

class FunctionWrapper
	attr :name
	attr :function
	attr :childcount

	def initialize(childcount, name, &block)
		@function = block
		@childcount = childcount
		@name = name
	end
end

class Node
	def initialize(function_wrapper, children)
		@function = function_wrapper.function
		@name = function_wrapper.name
		@children = children	
	end

	def evaluate(input)
		results = @children.map{|n| n.evaluate(input)} #start at bottom
		@function.call(results)
	end
	
	def display(indent=0)
		puts(' ' * indent + @name)
		@children.each{|c| c.display(indent + 1)} 
		nil
	end
end

class ParamNode
	def initialize(index)
		@index = index
	end

	def evaluate(input)
		input[@index]
	end

	def display(indent=0)
		puts(' ' * indent + @index.to_s)
	end
end

class ConstNode
	def initialize(value)
		@value = value
	end

	def evaluate(input)
		@value
	end

	def display(indent=0)
		puts(' ' * indent + @value.to_s)
	end
end
class Functions

	ADDW = FunctionWrapper.new(2, 'add'){|l| l[0] + l[1]}
	SUBW = FunctionWrapper.new(2, 'subtract'){|l| l[0] - l[1]}
	MULW = FunctionWrapper.new(2, 'multiply'){|l| l[0] * l[1]}
	IFW = FunctionWrapper.new(3, 'if'){|l| l[0] ? l[1] : l[2]}
	GTW = FunctionWrapper.new(2, 'isgreater'){|l| l[0] > l[1] ? 1 : 0}

	LIST = [ADDW, SUBW, MULW, IFW, GTW]

	def self.example_tree
		Node.new(IFW, [
			Node.new(GTW, [ParamNode.new(0), ConstNode.new(3)]),
			Node.new(ADDW, [ParamNode.new(1), ConstNode.new(5)]),
			Node.new(SUBW, [ParamNode.new(1), ConstNode.new(2)])
		])
	end

end

class RandomTree

	# pc = param count
	# fpr = probability that it will be a function
	# ppr = probability that will be be param node if not function node
	def self.make(pc, options={})
		options[:maxdepth] ||= 4
		options[:fpr] ||= 0.5
		options[:ppr] ||= 0.6

		if rand < options[:fpr] && options[:maxdepth] > 0
			f = Functions::LIST[rand(Functions::LIST.size)]

			children = [*0..f.childcount].map do |i|
				RandomTree.make(pc, :maxdepth => options[:maxdepth] - 1,
												:fpt => options[:fpr], :ppr => options[:ppr])
			end
			
			Node.new(f, children)
		elsif rand < options[:ppr]
			ParamNode.new(rand(pc-1))
		else
			ConstNode.new(rand(10))
		end
	end
end


