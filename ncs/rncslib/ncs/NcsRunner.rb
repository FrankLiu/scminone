#!/usr/bin/env ruby -w

require 'ncs/LoggerFactory'
require 'ncs/Constant'
require 'ncs/Properties'

class NcsRunner
	attr_accessor :prj_label
	
	def initialize(prj_label)
		@prj_label = prj_label
		@logger = LoggerFactory.getLogger(self.class.name)
	end
	
	#dependencies services
	#attr_accessor :properties
	#attr_accessor :project
	#attr_accessor :mailer
	def register_dependencies(properties,project,mailer,compiler)
		raise ArgumentError,"Invalid argument: properties" if properties.nil?
		@properties = properties
		@log_dir = @properties.get('ncs.log.dir')
		@project = Project.new(properties) if project.nil?
		@mailer = NcsMailer.new(properties) if mailer.nil?
		@mailer.project_release_label = @prj_label
		raise ArgumentError,"Invalid argument: compiler" if compiler.nil?
		@compiler = compiler
	end
	
	def check_dependencies
		raise ArgumentError,"Properties service is needed" if @properties.nil?
		raise ArgumentError,"Project service is needed" if @project.nil?
		raise ArgumentError,"NcsMailer service is needed" if @mailer.nil?
		raise ArgumentError,"NcsCompiler service is needed" if @compiler.nil?
	end
	
	def check_executable_file(type, suite_type)
		@compiler.check_executable_file(type, suite_type)
	end

	def switch_necb(suite_type="openr6")
		@logger.info("switch necb file start...")
		model_exec_path = @properties.get("ncs.model.output_path")
		necb_path = @properties.get("ncs.necb.path")
		necb_file = @properties.get("ncs.necb.file")
		necb_ftfile = @properties.get("ncs.necb.ftfile")
		@logger.debug("get necb file from key: ncs.necb."+suite_type)
		necb_suite = @properties.get("ncs.necb."+suite_type)
		@logger.debug("got necb file: #{necb_suite}")
		system("cp -f #{necb_path}/#{necb_suite} #{model_exec_path}/#{necb_file}")
		system("cp -f #{necb_path}/#{necb_ftfile} #{model_exec_path}/#{necb_ftfile}")
		@logger.info("swithed necb file to #{necb_suite}")
		@logger.info("switch necb file end.")
	end
	
	def run_model(testcase)
		@logger.info("run model at: "+Time.now)
		model_exec_path = @properties.get("ncs.model.output_path")
		model_params = @properties.get("ncs.model.test_params")
		model_exec = @properties.get("ncs.model.output_file")
		test_params_file = @properties.get("ncs.model.test_params_file")
		test_log_prefix = @properties.get("ncs.model.test_log_prefix")
		model_test_log = "#{@log_dir}/#{@prj_label}/testlog/#{test_log_prefix}#{testcase}.log"
		if File.exist?(model_test_log)
			@logger.info("remove previous test log: #{model_test_log}")
			system("rm -f #{model_test_log}")
		end
		def mk_test_params_file
			if not File.exist?(test_params_file)
				system("touch #{test_params_file}")
				params = model_params.split(/,|;/)
				params.each{ |param|
					system("echo 'echo #{param}' >> #{test_params_file}")
					system("echo 'sleep 1' >> #{test_params_file}")
				}
				system("chmod +x #{test_params_file}")
			end
		end
		mk_test_params_file()
		@logger.info("cd #{model_exec_path}")
		Dir.chdir(model_exec_path)
		@logger.debug("#{test_params_file} | #{model_exec_path}/#{model_exec} 1>#{model_test_log} 2>/dev/null &")
		system("#{test_params_file} | #{model_exec_path}/#{model_exec} 1>#{model_test_log} 2>/dev/null &")
		@logger.info("model running now, waiting for connect...")
	end
	
	def run_test(testcase, suite_type, nwg_mode)
		@logger.info("run testcase #{testcase} at: "+Time.now)
		test_flag = @properties.get("ncs.test.test_flag")
		test_params = @properties.get("ncs.test.test_params")
		test_params_nonwg = @properties.get("ncs.test.test_params_nonwg")
		test_timeout_flag = @properties.get("ncs.test.test_timeout_flag")
		test_path = @properties.get("ncs.test.output_path")
		test_exec = @properties.get("ncs.test"+suite_type+".executable")||@properties.get("ncs.test.output_file")
		test_timeout = @properties.get("ncs.test.test_timeout")
		test_log_prefix = @properties.get("ncs.test.test_log_prefix")
		test_log = "#{@log_dir}/#{@prj_label}/testlog/#{test_log_prefix}#{testcase}.log"
		if File.exist?(test_log)
			@logger.info("remove previous test log: #{test_log}")
			system("rm -f #{test_log}")
		end
		
		if nwg_mode 
			test_params = "#{test_flag} \"#{test_params} #{testcase}\""
		else
			test_params = "#{test_flag} \"#{test_params_nonwg} #{testcase}\""
		end
		@logger.debug("#{test_path}/#{test_exec} #{test_timeout_flag} #{test_timeout} #{test_params} 1>#{test_log} 2>&1 &")
		system("#{test_path}/#{test_exec} #{test_timeout_flag} #{test_timeout} #{test_params} 1>#{test_log} 2>&1 &")
	end
	
	def run_model_and_test(testcase, suite_type, nwg_mode=true)
		@logger.info("");
		@logger.info("run model and test for testcase: #{testcase}")
		self.run_model(testcase)
		self.run_test(testcase, suite_type, nwg_mode)
	end
	
	#kill model & test processes
	def kill_process(suite_type)
        m_pname = @properties.get("ncs.model.output_file")
        system("killall -s 9 #{m_pname} 2>/dev/null")
        @logger.warn("killed model process: #{m_pname}")
        t_pname = @properties.get("ncs.test"+suite_type+".executable")||@properties.get("ncs.test.output_file")
        system("killall -s 9 #{t_pname} 2>/dev/null")
        @logger.warn("killed test process: #{t_pname}")
	end
	
	def need_retest(test_result)
		@logger.info("check if testcase need to be retested?")
		@logger.info("testcase result: #{test_result}")
		if (
			test_result == $TESTCASE_RESULTS['time_out'] or
			test_result == $TESTCASE_RESULTS['model_is_not_startup'] or
			test_result == $MODEL_RESULTS['address_already_in_use'] or
			test_result == $MODEL_RESULTS['cmi_register_req'] or
			test_result == $TESTCASE_RESULTS['log_is_not_opened'] or
			test_result == $MODEL_RESULTS['log_is_not_opened'] or
			test_result == $TESTCASE_RESULTS['address_not_mapped']
		)
			@logger.info("testcase need to be retested!!")
			return true
		end
		@logger.info("testcase need not to be retested!!");
		return false
	end
	
	def parse_result(testcase)
		@logger.info("parse result for testcase: #{testcase}")
		#get variables
		test_log_prefix = @properties.get("ncs.test.test_log_prefix")
		test_log = "#{@log_dir}/#{@prj_label}/testlog/#{test_log_prefix}#{testcase}.log"
		model_log_prefix = @properties.get("ncs.model.test_log_prefix")
		model_test_log = "#{@log_dir}/#{@prj_label}/testlog/#{model_log_prefix}#{testcase}.log"
		
		#check if testcase finished
		test_timeout = @properties.getint("ncs.test.test_timeout")||600
		i = 0
		last_string = 0
		start_time = Time.now
		loop = 1
		while true
			if not File.exist?(test_log) or not File.stat(test_log).readable?
				@logger.error("cannot open test log: #{test_log}")
				return $TESTCASE_RESULTS['log_is_not_opened']
			end
			if not File.exist?(model_test_log) or not File.stat(model_test_log).readable?
				@logger.error("cannot open model log: #{model_test_log}")
				return $MODEL_RESULTS['log_is_not_opened']
			end
			#parse test log
			IO.foreach(test_log){ |line|
				if line =~ /#{$TESTCASE_RESULTS['finished_normally']}/
					@logger.info("Testcase #{testcase} finished normally.")
					pass  = %x{grep "setverdict(pass)" #{test_log} | wc -l}.to_i
					fail  = %x{grep "setverdict(FAIL)" #{test_log} | wc -l}.to_i
					error = %x{grep "setverdict(ERROR)" #{test_log} | wc -l}.to_i
					if error > 0
						@logger.info("Testcase #{testcase}... ERROR")
						@mailer.addtestresult(testcase, 'ERROR', 'error')
						return 'ERROR'
					elsif fail > 0
						@logger.info("Testcase #{testcase}... FAILED");
						@mailer.addtestresult(testcase, 'FAILED', 'failed')
						return 'FAILED'
					elsif pass >0
						@logger.info("Testcase #{testcase}... PASS");
						@mailer.addtestresult(testcase, 'PASS', 'pass')
						return 'PASS'
					end
					return $TESTCASE_RESULTS['finished_normally']
				end
				if line =~ /#{$TESTCASE_RESULTS['address_not_mapped']}/
					@logger.error("Testcase #{testcase} crashed: Address not mapped to object.")
					return $TESTCASE_RESULTS['address_not_mapped']
				end
				if line =~ /#{$TESTCASE_RESULTS['model_is_not_startup']}/
					@logger.error("Testcase #{testcase}... NOT CONNECT: Model is not startup correctly!")
					return $TESTCASE_RESULTS['model_is_not_startup']
				end
			}
			sleep(1)
			
			#parse model log
			last_string = i
			i = 0
			IO.foreach(model_test_log){ |line|
				if line =~/#{$MODEL_RESULTS['uml_error']}/
					@logger.info("Testcase #{testcase}... ERROR: UML Error.")
					@mailer.addtestresult(testcase, 'UML Error', 'error')
					return $MODEL_RESULTS['uml_error']
				elsif line =~ /#{$MODEL_RESULTS['uml_warning']}/
					@logger.info("Testcase #{testcase}... ERROR: UML Warning.")
					@mailer.addtestresult(testcase, 'UML Warning', 'error')
					return $MODEL_RESULTS['uml_warning']
				elsif line =~ /#{$MODEL_RESULTS['address_already_in_use']}/
					@logger.error("Testcase Error: Address already in use.")
					return $MODEL_RESULTS['address_already_in_use']
				end
				i = i + 1
				if last_string == i
					if line =~ /#{$MODEL_RESULTS['cmi_register_req']}/
						@logger.error("Testcase Error: CMI_REGISTER_REQ")
						return $MODEL_RESULTS['cmi_register_req']
					end
				end
			}
			sleep(1)
			#check timeout
			end_time = Time.now
			if (end_time - start_time) >= test_timeout
				@logger.warn("Testcase #{testcase}... timeout - #{test_timeout}, need retest!!")
				return $TESTCASE_RESULTS['time_out']
			end
			@logger.info("waiting for testcase #{testcase} finished loop: #{loop}")
			sleep(5)
			loop=loop+1
		end
		@logger.info("parsed result for testcase: #{testcase}")
	end
	
	#TODO: how to run testcase based on master-cluster mode?
	def get_next_case
	
	end
	def send_test_result
	
	end
	
	def run_suite(suite_type, nwg_mode, test_suite=[])
		@logger.info("Run test suite: #{test_suite}")
		#killed sleep time
		killed_sleep_time = @properties.getint("ncs.model.killed_sleep_time", 61)
		#ignore test level
		ignore_test = @properties.get("ncs.option.ignore_test", "NONE")
		#trtry on need
		retry_on_need = @properties.getint("ncs.option.retry_on_need", 10);
		#retry on timeout
		retry_on_timeout = @properties.getint("ncs.option.retry_on_timeout", 3)
		#run test suite
		@logger.info("NCS run with ignore level: #{ignore_test}")
		@logger.info("NCS run with retry on need: #{retry_on_need}")
		@logger.info("NCS run with retry on timeout: #{retry_on_timeout}")
		test_suite.each{ |testcase|
			retried_times = 1
			retried_timeout = 0
			test_result = ''
			need_retest = false
			#testcase no is blank, will be ignored!
			next if testcase.nil? or testcase.empty?
			if ignore_test =~ /ALL/
				@logger.info("NCS ignored testcase: #{testcase}")
				test_result = self.parse_result(testcase)
				need_retest = self.need_retest(test_result)
				@mailer.addtestresult(testcase, 'FAILED', 'failed') if need_retest
				next
			elsif ignore_test =~ /TESTED/
				test_result = self.parse_result(testcase)
				need_retest = self.need_retest(test_result)
				if not need_retest
					@logger.info("NCS ignored #{ignore_test} testcase: #{testcase}")
					next
				end
			elsif ignore_test =~ /PASS/
				test_result = self.parse_result(testcase)
				if test_result == "PASS"
					@logger.info("NCS ignored #{ignore_test} testcase: #{testcase}");
					next
				end
			end
			#retry 10 times for each case
			while retried_times == 1 or 
				(need_retest and retried_times<=retry_on_need and retried_timeout<=retry_on_timeout)
				@logger.info("run testcase #{testcase} times: #{retried_times}")
				begin
					self.run_model_and_test(testcase, suite_type, nwg_mode)
					test_result = self.parse_result(testcase)
					if test_result == $TESTCASE_RESULTS['time_out']
						retried_timeout=retried_timeout+1
					end
					need_retest = self.need_retest(test_result)
					self.kill_process(suite_type)
					
				rescue StandardError => err
					@logger.error("NCS broken when test case: #{testcase}")
					@logger.error("Caused by: #{err}")
					@logger.error("The testcase #{testcase} will be ignored")
					next
				end
				#reset the test port
				@logger.info("reset BASEPORT to a new one!")
				system("#{ENV['COSIM_DIR']}/tools/portCatch.pl >/dev/null")
				#wait 60 seconds for next test
				@logger.info("sleep #{killed_sleep_time} seconds for next test.")
				sleep(killed_sleep_time)
				retried_times=retried_times+1
			end
			#tried 10 times and still failed, give up
			if need_retest
				@logger.warn("give up testcase: #{testcase}")
				@logger.warn("It may caused by the following 2 reasons: ")
				@logger.warn("1. retried #{retry_on_need} times but testcase still not connected or not finished!")
				@logger.warn("2. retried #{retry_on_timeout} times but testcase still timeout!")
				if test_result == $TESTCASE_RESULTS['time_out']
					@logger.warn("Testcase #{testcase}... TIMEOUT")
					@mailer.addtestresult(testcase, 'TIMEOUT', 'error')
				#test_result == $TESTCASE_RESULTS{'model_is_not_startup'}||...
				else
					@logger.warn("Testcase #{testcase}... FAILED");
					@mailer.addtestresult(testcase, 'FAILED', 'failed')
				end
			end
			@logger.info("\n")
		}
	end
	
	def run_all_suite
		self.check_dependencies()
		@logger.info("")
		@logger.info("run all test suite start...")
		suite_types = @properties.get('ncs.test.suite','openr6,rrm,motor6,rrm_motor6').split(/\s+|,/)
		@logger.info("suite types: #{suite_types}\n")
		def get_test_suite(test_suite_label)
			ori_suite = @properties.get(test_suite_label, "")
			ori_suite.gsub!(/-/,'..')
			suite = eval(ori_suite)
			return suite
		end
		suite_types.each{ |suite_type|
			@logger.info("");
			@logger.info("run test suite #{suite_type} start...")
			test_suite = get_test_suite("ncs.test.#{suite_type}_suite")
			if test_suite.length == 0
				@logger.warn("suite type may not valid: #{suite_type}")
				@logger.warn("cannot found any case under suite: ncs.test.#{suite_type}_suite")
				next
			end
			
			#openr6|rrm|...
			nwg_mode = true
			#motor6
			nwg_mode = false if suite_type == "motor6"
			#check executable file
			self.check_executable_file('model')
			self.check_executable_file('test',suite_type)
			#run test suite
			self.switch_necb(suite_type);
			self.run_testsuite(suite_type, nwg_mode, test_suite)
			@logger.info("run test suite #{suite_type} end...")
			@logger.info("sleep 10 seconds to run next suite......")
			sleep(10)
		}
		@logger.info("run all test suite end...")
	end
end
