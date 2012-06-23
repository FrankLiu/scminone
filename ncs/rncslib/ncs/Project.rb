#!/usr/bin/env ruby

require 'net/ftp'
require 'ncs/NcsMailer'

class SameToPreviousReleaseError < RuntimeError
	attr :project_label
	def initialize(project_label)
		@project_label = project_label
	end
	def to_s
		"The project #{@project_label} is same to previous release and will not be tested."
	end
end

class ProjectIsTestedBeforeError < RuntimeError
	attr :project_label
	def initialize(project_label)
		@project_label = project_label
	end
	def to_s
		"The project #{@project_label} is tested before and will not be tested."
	end
end

class Project
	def initialize(properties)
		raise ArgumentError,"Invalid argument: properties" if properties.nil?
		@properties = properties
		@logger = LoggerFactory.getLogger(self.class.name)
		@logdir = @properties.get("ncs.log.dir")
		@storedir = @properties.get("ncs.store.dir")
		#tested projects
		@tested_projects = @properties.get("ncs.store.tested_projects")
	end
	
	def create_project_dir(prj)
		#initialize log dir
		Dir.mkdir("#{@logdir}/#{prj}", 0775) if not FileTest.exists?("#{@logdir}/#{prj}")
		#initialize store dir
		Dir.mkdir("#{@storedir}/#{prj}", 0775) if not FileTest.exists?("#{@storedir}/#{prj}")
	end
	
	def cleanup_prj_dir(prj)
		@logger.info("cleanup project dir: #{prj}")
		#clean up test logs
		cleanup_testlogs = @properties.getboolean("ncs.option.cleanup_testlogs")
		if cleanup_testlogs
			#clean up all of logs under project
			@logger.info("ncs.option.cleanup_testlogs turned on, NCS will clean up all of previous test log!")
			system("rm -rf #{@logdir}/#{prj}/testlog/*.log") if File.exist?("#{@logdir}/#{prj}/testlog/")
		end
		mail_store = @properties.get("ncs.mail.store")
		mail_store = "#{@storedir}/#{prj}/#{mail_store}"
		@logger.info("remove previous mail message: #{mail_store}")
		system("rm -f #{mail_store}") if File.exist?(mail_store)
	end
	
	def label
		@logger.info("get latest project config spec...")
		#load properties
		ftpserver = @properties.get('ncs.ftp.server')
		ftpuser = @properties.get('ncs.ftp.username')
		ftppwd = @properties.get('ncs.ftp.password')
		dailyprjdir = @properties.get('ncs.prj.daily_prj_dir')
		prjpattern = @properties.get('ncs.prj.latestprj_pattern')
		prjexcludepattern = @properties.get('ncs.prj.excludes_pattern')
		dailybuilddir = @properties.get('ncs.prj.daily_build_dir')
		#login ftp server
		ftp = Net::FTP.new(ftpserver)
		ftp.login(ftpuser,ftppwd)
		#get latest project label
		@ftp.chdir(dailyprjdir)
		prj = ftp.nlst("-t #{prjpattern}").first.chomp
		latest_prj_lbl = prj.sub(/\.prj/,'')
		@logger.info("latest project label: #{latest_prj_lbl}")
		#check if it is end with 1.xx.00
		if latest_prj_lbl =~ /#{prjexcludepattern}/
			@logger.error("The project #{latest_prj_lbl} is same to previous release and will not be tested.")
			raise SameToPreviousReleaseError.new(latest_prj_lbl)
		end
		#check if it is tested before
		if is_tested(latest_prj_label)
			@logger.error("The project #{latest_prj_lbl} is tested before and will not be tested.")
			raise ProjectIsTestedBeforeError.new(latest_prj_lbl)
		end
		#get config spec
		create_project_dir(latest_prj_lbl)
		cleanup_prj_dir(latest_prj_lbl)
		Dir.chdir("#{@log_dir}/#{latest_prj_lbl}")
		ftp.chdir(dailybuilddir+'/'+latest_prj_lbl)
		ftp.gettextfile(latest_prj_lbl+".cs",latest_prj_lbl+"_AH.cs")
		@logger.info("store latest project config spec as: #{latest_prj_lbl}_AH.cs")
		#close ftp session
		ftp.close() if not ftp.nil?
		return latest_prj_lbl
	end
	
	def update_cs(prj)
		@logger.info("update config-spec for project #{prj}...")
		#update config-spec
		cosim_label_path = @properties.get("ncs.cosim.path")
		cosim_label = @properties.get("ncs.cosim.label")
		@logger.info("cosim label: #{cosim_label}")
		Dir.chdir("#{@log_dir}/#{prj}")
		newcs = []
		newcs.push("element #{cosim_label_path}/... #{cosim_label}") if not cosim_label.empty?
		newcs.push("element * #{prj}") if not prj.empty?
		newcs.push(IO.readlines(prj+"_AH.cs"))
		File.open(prj+".cs","w"){|f|
			newcs.each do |line|
				f.write(line)
			end
		}
		sleep(2)
		@logger.info("updated config-spec for project #{prj}.")
		return "#{@log_dir}/#{prj}/#{prj}.cs"
	end
	
	def is_tested(prj)
		IO.foreach(@tested_projects){ |line|
			return true if line =~ /prj/
		}
		return false
	end
	
	def record_project(prj,prate,frate,isblock=false)
		if isblock
			@logger.info("project #{prj} is blocked")
			system("echo #{prj} BLOCK >> #{@tested_projects}")
		else
			@logger.info("#{prj} passrate:#{prate}, failrate: #{frate}")
			system("echo #{prj} #{prate} #{frate} >> #{@tested_projects}")
		end
	end
end
