#/usr/bin/env ruby

class Callback
	attr_accessor :before_intercept, :after_intercept
	
	def run
		@before_intercept.call
		puts "callback test"
		@after_intercept.call
	end
	
	def registerbeforeintercept(before_interceptor)
		@before_intercept = before_interceptor
	end
	def registerafterintercept(after_interceptor)
		@after_intercept = after_interceptor
	end
end

def before_interceptor
	puts "before interceptor"
end

def after_interceptor
	puts "after interceptor"
end

callback = Callback.new
callback.registerbeforeintercept(proc{before_interceptor})
callback.registerafterintercept(proc{after_interceptor})
#callback.before_intercept = proc{before_interceptor}
#callback.after_intercept = proc{after_interceptor}
callback.run()
