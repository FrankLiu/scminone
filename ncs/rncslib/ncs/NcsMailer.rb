#!/usr/bin/env ruby -w

require 'net/smtp'
require 'socket'
require 'ncs/LoggerFactory'
require 'ncs/Mailer'
require 'ncs/Template'
require 'ncs/SrParser'

class NcsMailer < Mailer
	attr_reader :defaultmailtemplate
	attr_accessor :outputdir
	
	attr :project_release_label,true
	attr :title,true
	attr :sr_link,true
	attr :report_link,true
	attr :host,true
	attr :ip,true
	attr :os,true
	attr :view,true
	attr :srs,true
	attr :srsummary,true
	attr :errors,true
	attr :buildresults,true
	attr :testsummary,true
	attr :testresults,true
	attr :testedprojects,true
	attr :buildlogdir,true
	attr :testlogdir,true
	attr :mergestat,true
	
	def initialize(properties)
		raise ArgumentError,"Invalid argument: properties" if properties.nil?
		@properties = properties
		@logger = LoggerFactory.getLogger(self.class.name)
		@defaultmailtemplate = File::dirname(__FILE__)+"/templates/mail_template.html"
		@outputdir = '.'
		#initialize instance variables
		@project_release_label,@title,@sr_link,@report_link,@host,@ip,@os,@view = '','','','','','','',''
		@srs,@srsummary = [],{}
		@errors,@buildresults = [],[]
		@testsummary,@testresults,@testedprojects = {},[],[]
		@buildlogdir,@testlogdir = '',''
		@mergestat = ''
		#initialize self
		mailserver = @properties.get('ncs.mail.server','de01exm68.ds.mot.com')
		from = @properties.get('ncs.mail.from','hzcosim@wimax-cosim.mot.com')
		tolist = @properties.get('ncs.mail.tolist','cwnj74@motorola.com').split(/[\s,;]+/)
		super(mailserver, from, tolist)
	end
	
	def addsr(sr)
		@srs.push(sr)
	end
	def addsr2(srno,function,headline,assignedto,status,opendate,closedate,loadinfo)
		@srs = [] if not defined?(@srs) or @srs.nil?
		@srs.push({
			'#SR' => srno,
			'#Function' => function,
			'#SR Headline' => headline,
			'#Assigned to' => assignedto,
			'#Status' => status,
			'#Open Date' => opendate,
			'#Close Date' => closedate,
			'#Load Info' => loadinfo
		})
	end
	
	def setsrsummary(originated, assessed, study, performed, closed)
		@srsummary = {
			'Originated' => originated,
			'Assessed' => assessed,
			'Study' => study,
			'Performed' => performed,
			'Closed' => closed,
		}
	end
	
	def adderror(err)
		@errors = [] if not defined?(@errors) or @errors.nil?
		@errors.push(err)
	end
	
	def addbuildresult(compile_message, compile_result, style='')
		@buildresults = [] if not defined?(@buildresults) or @buildresults.nil?
		@buildresults.push({
			'compile_message' => compile_message, 'compile_result'=> compile_result, 'style'=>style
		})
	end
	
	def settestsummary(total, passed, failed, error, passrate)
		@testsummary = {
			'total' => total,
			'passed' => passed,
			'failed' => failed,
			'error' => error,
			'passrate' => passrate
		}
	end
	
	def addtestresult(testcase, result, style='', srdesc='')
		@testresults = [] if not defined?(@testresults) or @testresults.nil?
		@testresults.push({
			'caseno' => testcase, 'result' => result, 'style' => style, 'srdesc' => srdesc
		})
	end
	
	def addpassrate4prj(prj, passrate, failrate, isblock, modtime)
		@testedprojects = [] if not defined?(@testedprojects) or @testedprojects.nil?
		prjresult = {
			'label' => prj,
			'passrate' => passrate,
			'failrate' => failrate,
			'modtime' => modtime
		}
		prjresult.store('block', true) if isblock
		@testedprojects.push(prjresult)
	end
	
	# build email with given mailmsgs
	# mailmsgs should be a HASH instance and includes belows keys
	# title
	# sr_link
	# report_link
	# srs, srsummary
	# host, os, view
	# errors
	# buildresults
	# testsummary
	# testresults
	# testedprojects
	# buildlogdir, testlogdir
	# mergestat_info
	def build_email(mailmsgs={}, mailtemplate=@defaultmailtemplate)
		@logger.info("build ncs email start...")
		template = Template.new(mailtemplate,@outputdir)
		outputfile = @properties.get("ncs.mail.store")
		#puts  @outputdir+"/"+outputfile
		if not mailmsgs.empty?
			@body = template.render(mailmsgs, @outputdir+"/"+outputfile)
		else
			raise ArgumentError,"either project_release_label need to be defined!" if @project_release_label.empty?
			#build title
			mailsubject = @properties.get("ncs.mail.subject")
			@title = "#{mailsubject} #{@project_release_label}" if @title.empty?
			#build sr link & report link
			@sr_link = @properties.get("ncs.mail.sr_link") if @sr_link.empty?
			@report_link = @properties.get("ncs.mail.report_link") if @report_link.empty?
			#build latest sr table
			sr_file = @properties.get("ncs.test.sr_mapping_file")
			sr_sheet = @properties.get("ncs.test.sr_worksheet", 'WMX5.0')
			@logger.info("sr mapping file: #{sr_file}")
			srparser = SrParser.new(sr_file)
			if @srs.empty?
				latestSrlist = srparser.latestSrlist(sr_sheet)
				latestSrlist.each{ |sr| 
					self.addsr(sr) 
				}
			end
			#build sr summary
			if @srsummary.empty?
				['Originated','Assessed','Study','Performed','Closed'].each{ |status|
					srlistStatus = srparser.srlistBy(sr_sheet, '#Status', status)
					@logger.info("#{status} sr: "+ srlistStatus.length.to_s)
					@srsummary.store(status, srlistStatus.length)
				}
			end
			#host,os,view
			@host = %x{uname -n}.chomp() if @host.empty?
			@ip = IPSocket.getaddress(@host) if @ip.empty?
			@os = %x{uname}.chomp() if @os.empty?
			cleartool = @properties.get('ncs.tool.cleartool')
			@view = %x{#{cleartool} pwv -s}.chomp() if @view.empty?
			#build log dir & test log dir
			logdir = @properties.get('ncs.log.dir')
			@buildlogdir = logdir + '/' + project_release_label + '/buildlog' if @buildlogdir.empty?
			@testlogdir = logdir + '/' + project_release_label + '/testlog' if @testlogdir.empty?
			#build merge stat info
			if @mergestat.empty?
				begin
					storedir = @properties.get('ncs.store.dir')
					mergestat = @properties.get('ncs.tool.mergestat')
					line_sep = @properties.get('ncs.mail.line_sep','<br/>')
					branch = %x{#{cleartool} catcs|grep '^mkbranch'|cut -f2 -d' '}.chomp
					mergestat_name = "mergestat_#{branch}"
					mergestat_store = storedir + '/' + project_release_label + "/mergestat_#{branch}"
					if not File.exists?(mergestat_store)
						@logger.info("mergestat file not exist, need to generated!")
						@logger.debug("cd /vob/wibb_bts; #{mergestat} -a -l -s -b #{branch} > #{mergestat_name}")
						system("cd /vob/wibb_bts; #{mergestat} -a -l -s -b #{branch} > #{mergestat_name}")
						@logger.debug("cp /vob/wibb_bts/#{mergestat_name} #{mergestat_store}")
						system("cp /vob/wibb_bts/#{mergestat_name} #{mergestat_store}")
					end
					mergestat = IO.readlines(mergestat_store)
					@logger.info("mergestat is store at #{mergestat_store}")
					#@logger.debug("#{mergestat}")
					@mergestat = mergestat.join(line_sep)
				rescue => err
					@logger.error("build mergestat failed, #{err.to_s}")
					@logger.warn("NCS ignored mergestat information!")
					@mergestat = ''
				end
			end
			#build tested projects
			tested_projects = @properties.get('ncs.store.tested_projects')
			if @testedprojects.empty? and File.exists?(tested_projects)
				lines = IO.readlines(tested_projects)
				lines.each{ |line|
					next if line =~ /^\s*$/
					line.chomp!
					#blocked project
					if line =~ /BLOCK/i
						(lbl,block,modtime) = line.split(/[\s:;,]+/, 3)
						self.addpassrate4prj(lbl,'','',true, modtime)
					#tested project
					else
						(lbl,prate,frate,modtime) = line.split(/[\s:;,]+/, 4)
						self.addpassrate4prj(lbl,prate,frate,false, modtime)
					end
				}
			end
			
			#build bindings
			attributes = {
				'title' => @title,
				'sr_link' => @sr_link,
				'report_link' => @report_link,
				'srs' => @srs,
				'srsummary' => @srsummary,
				'host' => @host,
				'ip' => @ip,
				'os' => @os,
				'view' => @view,
				'errors' => @errors,
				'buildresults' => @buildresults,
				'testsummary' => @testsummary,
				'testresults' => @testresults,
				'buildlogdir' => @buildlogdir,
				'testlogdir' => @testlogdir,
				'mergestat' => @mergestat,
				'testedprojects' => @testedprojects
			}
			#render template and store the mail as a file 
			@outputdir = @properties.get('ncs.store.dir') + '/' + project_release_label
			@body = template.render(attributes, @outputdir+"/"+outputfile)
		end
		@logger.info("build ncs email end")
	end

	def getBinding(title, sr_link='', report_link='', host='', ip='', os='', view='', srs=[], srsummary={}, 
		errors=[], buildresults=[], testsummary={}, testresults=[], testedprojects=[],
		buildlogdir='', testlogdir='', mergestat='')
		return binding()
	end
	
	def sendinform
		@logger.info("send ncs inform mail in html format")
		@tolist = @properties.get('ncs.mail.informlist','cwnj74@motorola.com')
		send()
	end
	
	def send(ishtml=true)
		@logger.info("mailserver: #@mailserver")
		@logger.info("to: #{@tolist.join(',')}")
		@logger.info("from: #@from")
		@logger.info("subject: #@subject")
		@logger.info("send mail start...")
		super()
		@logger.info("send mail end")
	end
	
	def sendhtml
		@logger.info("send ncs mail in html format")
		send()
	end
	
	def sendtext
		@logger.info("send ncs mail in text format")
		send()
	end
end

