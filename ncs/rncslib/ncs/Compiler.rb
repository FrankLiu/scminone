#!/usr/bin/ruby -w

require 'ncs/LoggerFactory'

class Compiler
	attr :compile_path,true
	attr :compile_tool,true 
	attr :compile_params,true
	attr :compile_message,true
	attr :output_path,true
	attr :output_file,true
	attr :mk_file,true 
	attr :mk_times,true
	attr :compile_log,true 
	attr :mk_log,true
	attr :cleanup_previous_output, true
	attr :ttcns,true
	attr :compile_result,true
	
	def initialize
		@logger = LoggerFactory.getLogger(self.class.name)
	end
	
	def registerbeforeprocess(beforeprocess)
		@before_process = beforeprocess
	end
	def registerafterprocess(afterprocess)
		@after_process = afterprocess
	end
	def registererrorhandler(errorhandler)
		@error_handler = errorhandler
	end
	
	def docompile
		#invoke before process
		if not @before_process.nil?
			@logger.debug("before process: @before_process")
			begin
				@before_process.call(self)
			rescue
				@logger.error("Cannot execute before process: $?")
			end
		end
		#compile process
		@cleanup_previous_output = @cleanup_previous_output || true
		@ttcns = @ttcns || []
		@logger.info("#{@compile_message} start...")
		if @cleanup_previous_output
			@logger.info("cleanup previous output: #{@output_path}")
			system("rm -Rf #{@output_path}")
		end
		File.unlink(@compile_log) if FileTest.exists?(@compile_log)
		File.unlink(@mk_log) if FileTest.exists?(@mk_log)
		#
		@logger.debug("cd #{@compile_path}")
		Dir.chdir(@compile_path)
		@compile_params.gsub!(/-r \w+/, "-r #{@output_file}/")
		@compile_params.concat(" " + @ttcns.join(' ')) if @ttcns.length > 0
		begin
			@logger.info("#{@compile_tool} #{@compile_params} 1>#{@compile_log} 2>&1")
			system("#{@compile_tool} #{@compile_params} 1>#{@compile_log} 2>&1")
			@logger.info("#{@compile_message} to #{@output_path}/#{@output_file}")
			sleep(10)
			#start compilation with make file
			if FileTest.exists?("#{@output_path}/#{@output_file}") and @mk_times > 0
				@logger.warn("output file not exist: #{@output_path}/#{@output_file}")
				@logger.warn("Try to build #{@mk_times} times with make file: #{@mk_file}")
				@logger.debug("cd #@output_path")
				Dir.chdir(@output_path); @mk_file = File.basename(@mk_file)
				if FileTest.exists?(@mk_file)
					@mk_times.times do
						# try to build using mk_file
						@logger.info("Try to build using make file: #@mk_file")
						system("touch #@mk_log") if FileTest.exists?(@mk_log)
						@logger.info("make -f #{@mk_file} 1>>#{@mk_log} 2>&1")
						system("make -f #{@mk_file} 1>>#{@mk_log} 2>&1")
						sleep(5)
						break if FileTest.exists?(@output_file)
					end
				else
					@logger.error("make file #@mk_file not exists! give up!")
				end
				@logger.debug("cd #@compile_path")
				Dir.chdir(@compile_path)
				@logger.warn("Finished building using make file: #@mk_file")
			end
			sleep(10)
		rescue => compile_err
			@logger.error("compilation error due to #{compile_err}")
			#invoke error handler
			if not @error_handler.nil?
				@logger.debug("error handler: @error_handler")
				begin
					@error_handler.call(self)
				rescue => err
					@logger.error("Cannot execute error handler: #{err}")
				end
			end
		end
		#check compilation
		@logger.info("check #@compile_message start");
		if FileTest.exists?("#{@output_path}/#{@output_file}")
			@logger.info("find output file: #{@output_path}/#{@output_file}!")
			@logger.info("compilation successful!")
			@compile_result = true
		else
			@logger.error("cannot find output file: #{@output_path}/#{@output_file}!")
			@logger.error("compilation failed!!!")
			@compile_result = false
		end
		@logger.info("check #@compile_message end")
		@logger.info("#@compile_message end")
		#invoke after process
		if not @after_process.nil?
			@logger.debug("after process: @after_process")
			begin
				@after_process.call(self)
			rescue => err
				@logger.error("Cannot execute after process: #{err}")
			end
		end
		return @compile_result
	end
end
