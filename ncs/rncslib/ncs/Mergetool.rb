#/usr/bin/env ruby

class Mergetool
	class << self
		def merge(*files)
			merged = {}
			files.each{ |file|
				to_be_merged = IO.readlines(file)||[]
				merged.store(File.basename(file), to_be_merged)
			}
			return merged
		end
		def merge2(startpattern=/.*/,stoppattern=/.*/,*files)
			merged = {}
			#puts "startpattern=#{startpattern},stoppattern=#{stoppattern}"
			files.each{ |file|
				to_be_merged = []
				betweenpattern = false
				IO.foreach(file){ |line|
					#puts line
					if line =~ startpattern
						betweenpattern = true
						#puts "matched startpattern"
					end
					if betweenpattern
						#puts "matched line: "+line
						to_be_merged.push(line)
					end
					if betweenpattern == true and line =~ stoppattern
						betweenpattern = false
						#puts "matched stoppattern"
					end
				}
				merged.store(File.basename(file), to_be_merged)
			}
			return merged
		end
	end
end
