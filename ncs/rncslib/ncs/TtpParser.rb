#!/usr/bin/env ruby -w

require 'ncs/LoggerFactory'

class TtpParser
	attr_accessor :ttp_file
	
	def initialize(ttp_file)
		raise ArgumentError,"Invalid argument: ttp_file" if ttp_file.nil? or not File.exist?(ttp_file)
		@ttp_file = ttp_file
		@ttp_content = IO.readlines(@ttp_file)
		@definitions = {}
		@values = {}
	end
	
	def parse
		is_def_block = false
		is_val_block = false
		def_name = ''
		val_name = ''
		@ttp_content.each{ |line|
			#remove \n
			line.chomp! 
			#blank line
			next if line =~ /^\s*$/
			#puts line
			
			#parse definition block
			#definition block start
			if line =~ /(\w+) ::= SEQUENCE OF \{/ 
				is_def_block = true
				def_name = $1
				@definitions.store(def_name, [])
			end
			if is_def_block and not def_name.empty?
				#puts "#{def_name} : #{line}\n"
				@definitions[def_name].push(line)
			end
			#definition block end
			if line =~ /^\}$/ and not def_name.empty?
				is_def_block = false
				def_name = ''
			end
			
			#parse value block
			#value block start
			if line =~ /(\w+) ::= \{/
				is_val_block = true
				val_name = $1
				@values.store(val_name, [])
			end
			if is_val_block and not val_name.empty?
				#puts "#{val_name} : #{line}\n";
				@values[val_name].push(line)
			end
			#value block end
			if line =~ /^\}$/ and not val_name.empty?
				is_val_block = false
				val_name = ''
			end
		}
	end

	def getDefinitionAsArray(name)
		return @definitions.fetch(name, [])
	end

	def getDefinition(name)
		definition = self.getDefinitionAsArray(name)
		return "" if @definition.empty?
		return @definition.join("\n")
	end

	def getValueAsArray(name)
		return @values.fetch(name, [])
	end

	def getValue(name)
		value = self.getValueAsArray(name)
		return "" if @value.empty?
		return @value.join("\n")
	end

	def getProp(name)
		prop = self.getValueAsArray('prop')
		prop.each{ |p|
			if p =~ /$name/
				val = p.split(',', 5)
				if val.length >= 5
					val = val[4]
					#puts "#{val}\n";
					#remove {" and "}},
					val.gsub!(/\{"/, '').gsub!(/"\}\},?/,'')
					return val
				end
			end
		}
		return ""
	end

	def getTtcns
		files = self.getValueAsArray('file_ref')
		ttcns = []
		files.each{ |file|
			if file =~ /\.ttcn/
				val = file.split(/\,/, 3)
				if val.length >= 3
					val = val[2]
					#puts "#{val}\n";
					#remove {" and "}},
					val.gsub!(/\{"/,'').gsub!(/"\},?/,'')
					#remove " and } and \\, replace \\\\ with /
					val.gsub!(/\"/,'').gsub!(/\}/,'').gsub!(/\\\\/,'/').gsub!(/^ /,'')
					#puts "#{val}\n"
					ttcns.push(val)
				end
			end
		}
		return ttcns
	end

	def getMakefile
		return self.getProp('MAKE_FILE')
	end

	def getMakeCommand
		return self.getProp('MAKE_COMMAND')
	end

	def getRootModule
		return self.getProp('ROOT_MODULE')
	end

	def getProduct
		return self.getProp('PRODUCT')
	end

	def getOutputDirectory
		return self.getProp('OUTPUT_DIRECTORY')
	end

end
