class FunctionWrapper
	attr :name
	attr :function

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
		results = @children.map{|n| n.evaluate(input)}
		@function.call(results)
	end
end

class ParamNode
	def initialize(index)
		@index = index
	end

	def evaluate(input)
		input[@index]
	end
end

class ConstNode
	def initialize(value)
		@value = value
	end

	def evaluate(input)
		@value
	end
end


@addw = FunctionWrapper.new(2, 'add'){|l| l[0] + l[1]}
@subw = FunctionWrapper.new(2, 'subtract'){|l| l[0] - l[1]}
@mulw = FunctionWrapper.new(2, 'multiply'){|l| l[0] * l[1]}
@ifw = FunctionWrapper.new(3, 'if'){|l| l[0] ? l[1] : l[2]}
@gtw = FunctionWrapper.new(2, 'isgreater'){|l| l[0] > l[1] ? true : false}

@flist = [@addw, @mulw, @ifw, @gtw, @subw]


def example_tree
	Node.new(@ifw, [
		Node.new(@gtw, [ParamNode.new(0), ConstNode.new(3)]),
		Node.new(@addw, [ParamNode.new(1), ConstNode.new(5)]),
		Node.new(@subw, [ParamNode.new(1), ConstNode.new(2)])
	])
end





