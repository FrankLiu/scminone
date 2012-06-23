#!/usr/bin/ruby -w

class Properties
	def initialize
		@properties = {}
	end
	
	def load(properties_file, escape=true)
		raise "#{properties_file} not exists!" if not File.exists?(properties_file)
		@properties_file = properties_file
		k = v = ""
		is_multiline = false
		IO::foreach(@properties_file) {|line|
			line = line.strip
			#skip blank-space line or comments 
			next if line =~/^\s*$/ or line =~/^\s*#/
			#puts "line: #{line}"
			#end with \
			if line =~ /\\$/
				#puts "line end with \\: #{line}"
				line.chomp!().chop!()
				if is_multiline #not first line,not end line
					v = v + ' ' + line
				else #first line
					k,v=line.split(/=/, 2)
					is_multiline = true
				end
				next;
			end
			if is_multiline
				#puts "line is one of multiline: #{is_multiline}"
				v = v+' '+line
				if line =~ /[^\\]$/ #end line
					@properties.store(k.strip, v.strip)
					#puts "#{k}=#{v}"
					k = v = ""
					is_multiline = false
				end
				next;
			end
			k,v=line.split(/=/, 2)
			next if(k.strip.empty?)
			#puts "#{k}=#{v}"
			@properties.store(k.strip, v.strip)
			k = v = ""
		}
		self.import_files()
		self._escapeprops() if escape
		return self
	end
	
	def _escapeprops
		@properties.each do |key,val|
			self._escapeprop(key,val)
		end
	end
	def _escapeenv(env)
		env = env.delete('$').sub('{','["').sub('}','"]')
		#puts "env: #{matched}"
		(eval(env) or "")
	end
	def _escapeprop(key,val)
		return if val =~ /^\s*$/ #ignore empty value
		while val =~ /^(.*)\$\{([^}]+)\}(.*)$/ #match ${ncs.log.dir}
			prefix = $1 or ""; matched = $2; suffix = $3 or ""
			#puts "matched key: #{matched}"
			if not @properties.key?(matched)
				puts "matched key not exists: #{matched}"
				break
			end
			#matched key exits
			#puts "#{matched}="+ @properties.fetch(matched)
			@properties.store(key, prefix+@properties.fetch(matched)+suffix)
			val = @properties.fetch(key)
		end
		
		while(val =~ /^(.*)(\$ENV\{[^}]+\})(.*)$/) #match $ENV{HOME}
			prefix = $1 or ""; matched = $2; suffix = $3 or ""
			matched = self._escapeenv(matched)
			#puts "matched env value:#{matched}"
			#puts "prefix=#{prefix}, matched=#{matched}, suffix=#{suffix}"
			@properties.store(key, prefix+matched+suffix)
			val = @properties.fetch(key)
		end
		#puts "#{key}=#{@properties[key]}"
		return val;
	end
	
	def get(key, default='')
		if(@properties.key?(key)): return @properties.fetch(key) end
		if(!default.nil?): return default end
	end
	
	def getint(key, default=0)
		self.get(key,default).to_i
	end
	def getfloat(key, default=0.0)
		self.get(key,default).to_f
	end
	
	alias getlong getint
	alias getdouble getfloat
	
	def getboolean(key)
		return true if self.getint(key, 0) > 0
		return false
	end
	
	def set(key,value)
		@properties.store(key,value)
	end
	
	def size
		@properties.size
	end
	
	def merge(props_to_be_merged, override=false)
		props_to_be_merged.each do |k,v|
			next if k.strip.empty?
			next if @properties.key?(k) and !override
			@properties.store(k, v.strip)
		end
		self
	end

	def import_files(override=false)
		import = self.get("ncs.import")
		if defined?(import) and not import.empty?
			puts "found import properties: #{import}"
			import = self._escapeprop("ncs.import",import)
			if not import.nil? and File.exist?(import)
				return self.merge(Properties.new.load(import,false).to_hash, override)
			end
		end
		self
	end

	def to_hash
		@properties
	end
	def keys
		@properties.keys
	end
	def values
		@properties.values
	end
	def dump
		keys = @properties.keys.sort
		keys.each do |key|
			val = self.get(key)
			puts "#{key}=#{val}"
		end
	end
	protected :_escapeprop,:_escapeenv,:_escapeprops
end
