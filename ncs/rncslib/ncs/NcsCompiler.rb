#!/usr/bin/ruby -w

require 'ncs/Common'
require 'ncs/LoggerFactory'
require 'ncs/Compiler'
require 'ncs/TtpParser'
require 'ncs/NcsMailer'
require 'ncs/Project'

class NcsCompiler < Compiler
	attr_accessor :prj_label
	attr_reader :supported_compiler
	
	def initialize(prj_label)
		@prj_label = prj_label
		@supported_compiler = ['isl','model','ttcn']
		super
	end
	
	#dependencies services
	#attr_accessor :properties
	#attr_accessor :project
	#attr_accessor :mailer
	def register_dependencies(properties,project,mailer)
		raise ArgumentError,"Invalid argument: properties" if properties.nil?
		@properties = properties
		@log_dir = @properties.get('ncs.log.dir')
		@project = Project.new(properties) if project.nil?
		@mailer = NcsMailer.new(properties) if mailer.nil?
		@mailer.project_release_label = @prj_label
	end
	
	def check_dependencies
		raise ArgumentError,"Properties service is needed" if @properties.nil?
		raise ArgumentError,"Project service is needed" if @project.nil?
		raise ArgumentError,"NcsMailer service is needed" if @mailer.nil?
	end
	
	def docompile(type)
		raise ArgumentError,"type should be in the [isl|model|ttcn]" if type.nil? or not @supported_compiler.include?(type)
		@compile_path = @properties.get("ncs."+type+".compile_path")
		@compile_tool = @properties.get("ncs."+type+".compile_tool")
		@compile_params = @properties.get("ncs."+type+".compile_params")
		@output_path = @properties.get("ncs."+type+".output_path")
		@output_file = @properties.get("ncs."+type+".output_file")
		@mk_file = @properties.get("ncs."+type+".mk_file")
		@compile_message = @properties.get("ncs."+type+".compile_message")
		@compile_log = @properties.get("ncs."+type+".compile_log")
		@mk_log = @properties.get("ncs."+type+".mk_log", @compile_log)
		@compile_log = "#{@log_dir}/#{@prj_label}/buildlog/#{@compile_log}"
		@mk_log = "#{@log_dir}/#{@prj_label}/buildlog/#{@mk_log}"
		#check compile option
		@logger.info("compilation start...")
		#invoke compile method
		super
		#check license issue
		while(File.contains(@compile_log, 'TAU-G2-UML-BASE|TAU-G2-TTCN3-BASE'))
			super
		end
		#check compile result
		self.compile_fail_handler() if not @compile_result
		@logger.info("compilation end.")
		return @compile_result
	end
	
	def compile_fail_handler
		@logger.error("#{@compile_message}...FAILED")
		@mailer.addbuildresult(@compile_message,'FAILED','error')
		@mailer.adderror("please check log file @ ")
		@mailer.build_email()
		@mailer.send_html()
		@project.record_project(@prj_label,nil,nil,true)
		raise "Error due to #{@compile_message}...FAILED"
	end
	
	def need_compile(type)
		enable_compile = @properties.getboolean("ncs.option.compile_"+type)
		compile_message = @properties.get("ncs."+type+".compile_message")
		return true if enable_compile
		#ignored compilation
		@logger.warn("ncs.option.compile_"+type+"=0, NCS will ignore #{type} compilation!")
		@mailer.addbuildresult(compile_message, 'IGNORED')
		return false
	end
	
	#always check executable file to make sure it exists before run testcase
	#otherwise, send out a inform email, 
	#this means it need handle by development team!
	def check_executable_file(type, suite_type='')
		compile_message = @properties.get("ncs.#{type}.compile_message")
		exec_path = @properties.get("ncs.#{type}.output_path")
		exec = @properties.get("ncs.#{type}.output_file")
		exec = @properties.get("ncs.#{type}.#{suite_type}.executable", exec) if not suite_type.empty?
		@logger.info("check #{type} executable file: #{exec_path}/#{exec}")
		@logger.info("suite type: #{suite_type}") if not suite_type.empty?
		if File.exist?("#{exec_path}/#{exec}")
			@logger.error("executable file not exists: #{exec_path}/#{exec}")
			@logger.error("please turn on compile #{type} option as: ncs.option.compile_#{type}=1")
			@mailer.addbuildresult(compile_message, 'FAILED', 'error')
			@mailer.adderror("executable file not exist: #{exec_path}/#{exec}")
			@mailer.adderror("please turn on compile #{type} option as below if it is not turned on:")
			@mailer.adderror("&nbsp;&nbsp;ncs.option.compile_#{type}=1")
			@mailer.adderror("please check your config spec or code if the compile option already turned on")
			#TODO: should we need check the depends emails?
			@mailer.build_email()
			@mailer.send_inform()
			raise "Error due to executable file not exists!"
		end
		@logger.info("found #{type} executable file: #{exec_path}/#{exec}")
	end
	
	def compile_isl
		check_dependencies()
		compile_message = @properties.get("ncs.isl.compile_message")
		output_path = @properties.get("ncs.isl.output_path", "#{@log_dir}/#{@prj_label}")
		output_file = @properties.get("ncs.isl.output_file");
		def set_output_path(compiler)
			compiler.output_path = output_path
			compiler.mk_times = 0
			#not need cleanup here
			compiler.cleanup_previous_output = false
		end
		def cp_output
			target_file = @properties.get("ncs.isl.target_file")
			if not target_file.nil? and not target_file.empty?
				@logger.debug("cp #{output_path}/#{output_file} #{target_file}")
				system("cp #{output_path}/#{output_file} #{target_file}")
			end
		end
		if self.need_compile('isl')
			self.do_compile('isl', proc{set_output_path}, proc{cp_output})
			#push compile result
			@mailer.addbuildresult(compile_message, 'OK')
		end
	end
	
	def compile_model
		check_dependencies()
		compile_message = @properties.get("ncs.model.compile_message")
		if self.need_compile('model')
			self.do_compile('model')
			#push compile result
			@mailer.addbuildresult(compile_message, 'OK')
		end
		self.check_executable_file('model')
	end
	
	def compile_ttcn
		check_dependencies()
		compile_message = @properties.get("ncs.test.compile_message")
		isl_check_file_name = @properties.get("ncs.isl.check_file")
		isl_check_file = "#{@log_dir}/#{@prj_label}/#{isl_check_file_name}"
		def correct_pkg_ttcn(isl_check_file)
			dirname = File.dirname(isl_check_file)
			basename = File.basename(isl_check_file)
			@logger.info("correct pkg ttcn file...")
			Dir.chdir(dirname)
			File.open('tmp.ttcn', 'w'){ |f|
				IO.foreach(basename) { |line|
					if (
						line =~ /PCD_REL_CONTAINMENT_TARGET (3)/ or
						line =~ /PCD_REL_CONTAINMENT_SOURCE (4)/ or 
						line =~ /PCD_REL_DEPENDENCY_TARGET (6)/ or 
						line =~ /PCD_REL_DEPENDENCY_SOURCE (7)/
					)
					line = "// #{line}"
					end
					f.write(line)
				}
			}
			sleep(2)
			system("cp #{basename} #{basename}.bak")
			system("mv tmp.ttcn #{basename}")
		end
		
		def prepare_compiler(compiler, ttp_file)
			ttpParser = TtpParser.new(ttp_file)
			ttpParser.parse()
			root_module = ttpParser.getRootModule()||''
			makefile = ttpParser.getMakefile()||''
			#outputDir = ttpParser.getOutputDirectory();
			ttcns = ttpParser.getTtcns()||[]
			#compiler.outputpath = outputDir.strip if not outputDir.empty?
			if not root_module.empty?
				root_module.strip!
				compiler.output_file = root_module
				compileLog = compiler.compile_log
				mkLog = compiler.mk_log
				compiler.compile_log = File.dirname(compileLog)+"/#{root_module}_"+File.basename(compileLog)
				compiler.mk_log = File.dirname(mkLog)+"/#{root_module}_"+File.basename(mkLog)
			end
			if not makefile.empty? and File.exist?(compiler.output_path+"/"+File.basename(makefile))
				compiler.mk_file = makefile.strip
			end
			compiler.ttcns = ttcns if ttcns.length > 0
			#not need cleanup here
			compiler.cleanup_previous_output = false
		end
		
		if self.need_compile('test')
			compiler_result = false
			correct_pkg_ttcn(isl_check_file) if File.exist?(isl_check_file)
			#read ttcn files from ttp files
			ttp_files = @properties.get("ncs.test.ttp_files",'')
			ttcn_files = @properties.get("ncs.test.ttcn_files")
			if not ttp_files.empty?
				@logger.info("read ttcn files from ttp files: #{ttp_files}")
				output_path = @properties.get("ncs.test.output_path")
				@logger.warn("clearnup dir #{output_path}")
				#only cleanup 1 time
				system("rm -Rf #{output_path}/*") if File.exist?(output_path)
				ttp_files.split(",").each{ |ttp_file|
					if not File.exist?(ttp_file)
						@logger.warn("ttp file not exists: #{ttp_file}")
						next
					end
					def pre_ttpfiles_compiler(compiler)
						prepare_compiler(compiler, ttp_file);
					end
					compiler_result = self.do_compile('test', proc{pre_ttpfiles_compiler})
				}
			#read ttcn files from properties file
			elsif not ttcn_file.empty?
				compile_path = @properties.get("ncs.test.compile_path");
				@logger.info("read ttcn files from properties file");
				ttcn_files.split(',').each{ |ttcn|
					if File.exist?(isl_check_file) and ttcn =~ /#{isl_check_file_name}/
						ttcn = isl_check_file
					else
						ttcn = "#{compile_path}/#{ttcn}"
					end
				}
				@logger.debug("ttcn files: #{ttcn_files}\n");
				def pre_ttcnfiles_compile
					compiler.ttcns = ttcn_files.split(',') if ttcn_files.length > 0
				end
				compiler_result = self.do_compile('test', proc{pre_ttcnfiles_compile})
			else
				@logger.error("please configure ncs.test.ttp_files or ncs.test.ttcn_files for compile ttcn!");
				@mailer.adderror("please configure ncs.test.ttp_files or ncs.test.ttcn_files for compile ttcn!")
				@mailer.send_inform()
				raise "Error due to #{compile_message}...FAILED"
			end
			#push compile result
			@mailer.addbuildresult(compile_message, 'OK')
		end
		#check executable file
		suite_types = @properties.get("ncs.test.suite")
		suite_types.split(/\s+|,/).each{ |suite_type|
			self.check_executable_file('test', suite_type)
		}
	end
	
	private :check_dependencies
	
end
