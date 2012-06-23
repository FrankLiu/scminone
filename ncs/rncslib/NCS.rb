#!/usr/lib/ruby -w
#
# NCS is a script built for running Cosim test suite nightly
# 
BEGIN{
	if ENV['NCS_HOME'].nil? or ENV['NCS_HOME'].empty?
		$NCS_HOME = File.dirname(__FILE__)
		ENV['NCS_HOME'] = $NCS_HOME
	end
	$LOAD_PATH << File.join(File.dirname(__FILE__), "lib") if File.exist?("#{ENV['NCS_HOME']}/lib")
	$LOAD_PATH << File.join(File.dirname(__FILE__), "ncs") if File.exist?("#{ENV['NCS_HOME']}/ncs")
}
require 'getoptlong'
require 'ncs/NcsVersion'
require 'ncs/Constant'
require 'ncs/Common'
require 'ncs/Project'
require 'ncs/NcsMailer'
require 'ncs/NcsCompiler'
require 'ncs/NcsRunner'

class NCS
	attr_accessor :ncs_start_time,:ncs_end_time
	attr_accessor :properties_file
	
	def initialize(properties_file='ncs_sm5.0.properties')
		@properties_file = properties_file
		@ncs_start_time=Time.now
		puts("initialize NCS ...\n")
		puts("Initialize NCS at: #{ncs_start_time.to_s}")
		puts("NCS start time is: #{ncs_start_time.to_s}")
		def check_ncs_is_running
			puts("check if there is another NCS running?")
			ps = %x{ps -f -C perl|grep `whoami`|grep #{@properties_file}|wc -l}
			puts"found running NCS instance: #{ps}"
			ps = (ps||0).to_i
			ncslock=$CUR_PATH+"/.ncslock"
			if File.exist?(ncslock)
				puts("NCS found #{ncslock} file...")
				#includes my self process, it should be more than 1
				if ps > 1
					puts("NCS found another process is running")
					system("ps -ef|grep NCS")
					puts("system exit due to another NCS process is running")
					exit(-1)
				end
				puts("Probely NCS is terminated abnormally at last running!")
				puts("No detected running instance, NCS will remove #{ncslock} and continue the process!")
				puts("rm -f #{ncslock}")
				system("rm -f #{ncslock}")
			end
			system("touch #{ncslock}")
		end
		def check_sys_vars
			puts("\ncheck sytem variables ...")
			vars = %w{
				MOUSETRAP_HOME COSIM_DIR COSIM_PATH TEST_CDF
				TAU_TESTER TAU_TESTER_MAJOR_VER TAU_TESTER_MINOR_VER
				TAU_TTCN_DIR TAU_UML_DIR TIPC_DEV_ROOT
				OSTYPE DEBUG_LEVEL G2_GENERATE_MAPFILE AUTOGEN_EXTERNAL_OPS CC};
			for var in vars
				if ENV[var].nil? or ENV[var].empty?
					raise ArgumentError,"variable #{var} not defined!"
				else
					puts("variable #{var} = #{ENV[var]}")
				end
			end
		end
		def load_configure
			puts("\nload configure file ...")
			@properties = Properties.new
			@properties.load(@properties_file)
			#initialize cleartool
			@cleartool = @properties.get("ncs.tool.cleartool")
			@pduconverter = @properties.get("ncs.tool.pduconverter")
			#dirs
			@store_dir = @properties.get("ncs.store.dir")
			@log_dir = @properties.get("ncs.log.dir")
			#tested projects
			@tested_projects = @properties.get("ncs.store.tested_projects")
		end
		def initialize_ncs_dir(dir)
			if not File.exist?(dir)
				puts("#{dir} not exists, NCS will create it automatically")
				system("mkdir -p #{dir}")
				system("chmod 775 #{dir}")
			end
		end
		def initialize_log
			#initialize log
			puts("\ninitialize log ...\n")
			log_file = @properties.get("ncs.log.file")
			puts("ncs log is located at: #{log_file}")
			@logger = LoggerFactory.getLogger(self.class.name)
		end
		#check if ncs is running now
		check_ncs_is_running()
		#check system variables
		check_sys_vars()
		#load configuration file
		load_configure()
		#initialize store dir & log dir
		initialize_ncs_dir(@store_dir)
		initialize_ncs_dir(@log_dir)
		#initialize log service
		initialize_log()
		@logger.info("Initialized NCS at: #{Time.now.to_s}")
		#print out configuration
		@logger.debug("########## system variables ###########")
		ENV.to_hash.each{|key,val| @logger.debug("#{key} = #{val}")}
		@logger.debug("########### system variables ###########")
		@logger.debug("########### cofiguration variables ###########")
		@properties.to_hash.each{|key,val|  @logger.debug("#{key} = #{val}")}
		@logger.debug("########### cofiguration variables ###########")
		#initialize services
		@project = Project.new(@properties)
		@mailer = NcsMailer.new(@properties)
	end

	def initialize_project
		@logger.info("")
		@logger.info("initialize project start...")
		run_with_cs = @properties.get("ncs.option.run_with_cs",'')
		@prj_label = ''
		#run with user specific config-spec
		if not run_with_cs.empty?
			@logger.info("initialize project with config-spec #{run_with_cs}")
			if not File.exist?(run_with_cs)
				@logger.error("Config-spec file not exists: $run_with_cs");
				terminate()
				raise ArgumentError,"system exit due to Config-spec file not exists: #{run_with_cs}!!!"
			end
			cs_name = File.basename(run_with_cs).chomp
			@prj_label = cs_name.gsub(/\.cs/,'')
			@logger.debug("cp #{run_with_cs} #{@log_dir}/#{@prj_label}/#{cs_name}")
			system("cp #{run_with_cs} #{@log_dir}/#{@prj_label}/#{cs_name}")
			#set config-spec
			@logger.debug("@cleartool setcs #{@log_dir}/#{@prj_label}/#{cs_name}")
			system("@cleartool setcs #{@log_dir}/#{@prj_label}/#{cs_name}")
			@logger.info("config-spec file: #{@log_dir}/#{@prj_label}/#{cs_name}")
		#run with latest project's config-spec
		else
			@logger.info("initialize project by nightly build projects");
			@prj_label = @project.label()
			@logger.info("project label is #{@prj_label}")
			cconfigspec = @project.update_cs(@prj_label)
			#set config-spec
			@logger.debug("@cleartool setcs #{cconfigspec}")
			system("@cleartool setcs #{cconfigspec}")
			@logger.info("config-spec file: #{cconfigspec}")
		end
		@logger.info("latest project label: #{@prj_label}")
		@logger.info("initialize project end.");
	end
	
	def compile
		@compiler = NcsCompiler.new(@prj_label)
		@compiler.register_dependencies(@properties,@project,@mailer)
		@compiler.compile_isl()
		@compiler.compile_model()
		@compiler.compile_ttcn()
	end
	
	def run_suite
		@runner = NcsRunner.new(@prj_label)
		@runner.register_dependencies(@properties,@project,@mailer,@compiler)
		@runner.run_all_suite()
	end
	
	def parse_sr_mappings
		@logger.info("parse sr mappings start...")
		sr_file = @properties.get("ncs.test.sr_mapping_file")
		sr_mapping_worksheet = @properties.get("ncs.test.sr_mapping_worksheet")
		sr_mappings = {}
		@logger.info("sr mapping file: #{sr_file}")
		if File.exist?(sr_file)
			@logger.debug("parse sr mapping file: #{sr_file}")
			srparser = SrParser.new(sr_file)
			sr_mappings = srparser.srMappings(sr_mapping_worksheet)
			@logger.debug("parsed sr mapping file: #{sr_file}")
		end

		@mailer.testresults.each{ |tres|
			testcase = tres['caseno']
			result = tres['result']
			style = style || result.downcase
			sr_desc = ''
			if not result == "PASS" and sr_mappings.key?(testcase)
				sr_desc = sr_mappings.fetch(testcase,'')
				sr_desc = "New failed case, need to be analyzed" if sr_desc.empty?
			end
			tres['style'] = style
			tres['sr_desc'] = sr_desc
		}
		@logger.info("parse sr mappings end...");
	end

	def sendmail
		@mailer.build_email()
		@mailer.send_html()
	end
	
	def record_project
		#TODO
		#record project
	end
	
	def terminate
		@logger.info("terminate ncs");
		#close log service
		log_name = @properties.get("ncs.log.name")
		puts("\nterminate log...\n")
		if not @prj_label.empty?
			system("mv #{@log_dir}/#{log_name} #{log_dir}/#{@prj_label}/#{log_name}")
			puts("log is located at: #{log_dir}/#{@prj_label}/#{log_name}\n\n")
		end
		#remove ncslock file for next run
		system("rm -f #{ncslock}") if File.exist?(@ncslock)
		#record ncs running spent time
		@ncs_end_time=Time.now
		puts("NCS is terminated at: #{ncs_end_time.to_s}")
		spent_hr,spent_mm,spent_sec=stat_time(ncs_start_time,ncs_end_time)
		puts("NCS spent #{spent_hr} hours,#{spent_mm} minutes,#{spent_sec} seconds to run all test suite!")
	end
end

def usage
	puts <<EOF
Usage: NCS.rb [-p] <properties_file>
Usage: NCS.rb -help
Mandatory option -p <properties_file> should be the properties file
	eg, ncs_sm5.0.properties,ncs_sm4.0.properties etc.
EOF
end

def parse_args
	ncs_version = NcsVersion.new
	verbose,version,help=nil,nil,nil
	opts = GetoptLong.new(
		[ "--properties_file", "-p", GetoptLong::OPTIONAL_ARGUMENT ],
		[ "--verbose", "-b", GetoptLong::NO_ARGUMENT ],
		[ "--version", "-v", GetoptLong::NO_ARGUMENT ],
		[ "--help", "-h", GetoptLong::NO_ARGUMENT ]
	)
	opts.each{ |opt,arg|
		if opt == '--help'
			usage()
			exit(-1)
		elsif opt == '--verbose'
			ncs_version.print_ncs_verbose()
			exit(-1)
		elsif opt == '--version'
			puts ncs_version.get_ncs_version()
			exit(-1)
		elsif opt == '--properties_file'
			@properties_file = arg
		end
	}
	
	if ARGV.length > 0 && @properties.nil?
		@properties_file = ARGV[0]
	end
	if @properties_file.nil? or not File.exist?(@properties_file)
	    puts "Please correctly input all mandatory options"
        usage()
	    exit(-1)
    end
end

def main
	ncs = NCS.new
	ncs.initialize_project()
	ncs.compile()
	ncs.run_suite()
	ncs.parse_sr_mappings()
	ncs.sendmail()
	ncs.record_project()
	ncs.terminate()
end

parse_args()
main()
exit(0)
