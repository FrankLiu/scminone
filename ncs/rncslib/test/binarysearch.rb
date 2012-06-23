#/usr/bin/env ruby

def binarysearch(items, value)
	startindex = 0
	stopindex = items.length-1
	middle = ((stopindex-startindex)/2).to_i
	puts "startindex: #{startindex}, stopindex: #{stopindex}, middle: #{middle}"
	while(value != items[middle] and startindex < stopindex)
		#adjust search range
		if value < items[middle]
			stopindex = middle-1
		elsif value > items[middle]
			startindex = middle+1
		end
		middle = ((stopindex+startindex)/2).to_i
		puts "startindex: #{startindex}, stopindex: #{stopindex}, middle: #{middle}"
	end
	
	if value = items[middle]
		puts "items[#{middle}] has the same value with given one: #{items[middle]}"
		middle
	else
		-1
	end
end

puts binarysearch([3,5,6,7,10,14,34,45,54,57,65,73,78,88,98,100,103,107,113,115,152,173,203,332,358,455,541,555,567,672,789,1545], 113)