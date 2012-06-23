#!/usr/bin/env ruby -w

require 'ncs/Common'

class Template
	def initialize(template, outputpath=nil)
		@template = template
		@template_output_path = outputpath||File.dirname(template)+"/../output"
		@template_output = @template_output_path + "/" + File.basename(template)+".tmp"
		@includes = []
	end
	
	
	def buildBindings(attributes)
		return attributes if attributes.instance_of?(Binding) or attributes.instance_of?(Proc)
		proc = Proc.new{
			context_vars = []
			attributes.each{|key,val|  context_vars.push("#{key} = #{val.inspect}") }
			eval(context_vars.join(';'))
			binding
		}
		return proc.call
	end
		
	def render(attributes,outputfile='')
		output = []
		iscomment = false
		isloop = false
		blocksrc = []
		blockstart = blockend = ''
		#wrapper template as ruby code fragment
		IO.foreach(@template){ |line| 
			#puts line 
			#ignore html comments
			iscomment=true if line =~ /^<!--/
			iscomment=false if line =~ /^-->/
			next if iscomment || line =~ /^<!--/ || line =~ /^-->/
			#handle includes
			if line =~ /<%\s*include\s*([\w_]+)\s*%>/
				include = $1
				puts "includes #{include}"
				include_template = File.dirname(@template)+"/#{include}.html"
				include_output = @template_output_path + "/" + File.basename(include_template)+".tmp"
				include_content = Template.new(include_template).render(attributes, include_output)
				@includes.push({
					'include' => include,
					'template' => include_template,
					'content' => include_content
				})
				include_content.each{ |ic|
					#puts "#{include} include line:" + ic
					ic.chop!().gsub!(/"/,'\\"')
					blocksrc.push("f.write(\"#{ic}\n\")")
				}
				next
			end
			#replace " with \"
			line.chop!().chomp!()
			#puts "line: " + line
			line.gsub!(/"/,'\\"') if not line.nil?
			#ruby code
			if line =~ /<%/ and line =~ /%>/ and line =~ /\s*(if|elsif|else|end|\{|\})\s*/
				#puts "ruby: " + line
				block = line[2..-3]
				#puts block
				blocksrc.push(block)
				next
			else
				#puts "normal line:" + line
				blocksrc.push("f.write(\"#{line}" + '\n' + "\")")
			end
			
			#parse normal content holder
			# if line =~ /#\{[^}]+\}/ and not isloop
				# line.gsub!(/#\{([^}]+)\}/){ |match|
					# eval $1,attributes
				# }
			# end
		}

		#eval the blocksrc
		begin
			Dir.mkdir(File.dirname(@template_output)) if not File.exists?(File.dirname(@template_output))
			blocksrc.unshift("File.open('#{@template_output}', 'w'){|f|")
			blocksrc.push("}")
			#puts blocksrc
			bindings = buildBindings(attributes)
			eval blocksrc.join(';'),bindings
		rescue => err
			raise "cannot evel #{blocksrc} due to: #{err}"
		end
		#render to output
		IO.foreach(@template_output){ |lr|
			output.push(lr)
		}

		#store to tmp file or user given file
		if not outputfile.empty?
			Dir.mkdir(File.dirname(outputfile)) if not File.exists?(File.dirname(outputfile))
			File.rename(@template_output,outputfile)
		else
			File.unlink(@template_output) if File.exists?(@template_output)
		end
		return output
	end
end
