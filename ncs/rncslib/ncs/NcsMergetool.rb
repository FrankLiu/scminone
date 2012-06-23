#/usr/bin/env ruby

class NcsMergetool
	class << self
		def merge(output='',split='-'*20, *files)
			merged = []
			files.each{ |file|
				merged.push(IO.readlines(file)||[])
				merged.push(split) if not file.eql?(files.last)
			}
			File.open(output){ |f|
				merged.each do |line|
					f.write(line)
				end
			} if File.exists?(output)
			return merged
		end
		
		def merge2(output='', split='-'*20, startpattern=/.*/, stoppattern=/.*/, *files)
			merged = []
			#puts "startpattern=#{startpattern},stoppattern=#{stoppattern}"
			files.each{ |file|
				betweenpattern = false
				IO.foreach(file){ |line|
					#puts line
					if line =~ startpattern
						betweenpattern = true
						#puts "matched startpattern"
					end
					if betweenpattern
						#puts "matched line: "+line
						merged.push(line)
					end
					if betweenpattern == true and line =~ stoppattern
						betweenpattern = false
						#puts "matched stoppattern"
					end
				}
				merged.push(split) if not file.eql?(files.last)
			}
			File.open(output){ |f|
				merged.each do |line|
					f.write(line)
				end
			} if File.exists?(output)
			return merged
		end
	end
end
