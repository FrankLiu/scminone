#!/usr/bin/ruby -w

require 'test/unit'
require 'logger'
require 'ncs/NcsMailer'
require 'ftools'

class NcsMailerTest < Test::Unit::TestCase
	@@ClassName = 'NcsMailerTest'
	
	def setup
		ENV['NCS_HOME'] = ncshome = File::dirname(__FILE__) + '/../../ncshome'
		@properties = Properties.new
		@properties.load(File::dirname(__FILE__) + "/ncs_sm5.0.properties")
		@mailer = NcsMailer.new(@properties)
		@mailer.outputdir = "ncsoutput"
		@mailer.tolist = ['cwnj74@motorola.com','cwnj74@motorola.com']
	end
	
	def test_buildmail
		@properties.set("ncs.mail.store",'ncs_mail_test.html')
		mailmsgs = {
			'title' => '[SM Cosim Nightly Script 5.0] WMX-AP_R5.0_BLD-1.31.01',
			'sr_link' => 'http://compass.mot.com/doc/353641209/WMX_CoSim_SR.xls',
			'report_link' => 'http://compass.mot.com/doc/354461914/CoSim-NCS-WMX5.0.ppt',
			'srs' => [{
				'#SR' => 'MOTCM01344913',
				'#Function' => 'Model Error',
				'#SR Headline' => '[COSIM]WMX-AP_R5 0_BLD-1.29.14:SM code build fail due to CR merge',
				'#Assigned to' => 'cds130~Supehia, Dev',
				'#Status' => 'Study(Supehia,Dev)',
				'#Open Date' => '7/26/2010 11:35:00 AM',
				'#Close Date' => '',
				'#Load Info' => 'WMX-AP_R5 0_BLD-1.29.14'
			},
			{
				'#SR' => 'MOTCM01344914',
				'#Function' => 'Model Compile Failed',
				'#SR Headline' => '[COSIM]WMX-AP_R5 0_BLD-1.31.05:SM code build fail due to CR merge',
				'#Assigned to' => 'cds130~Supehia, Dev',
				'#Status' => 'Study(Supehia,Dev)',
				'#Open Date' => '8/20/2010 11:35:00 AM',
				'#Close Date' => '',
				'#Load Info' => 'WMX-AP_R5 0_BLD-1.31.05'
			}],
			'srsummary' => {
				'Originated' => 0,
				'Assessed' => 2,
				'Study' => 14,
				'Performed' => 7,
				'Closed' => 9,
			},
			'host' => 'zch66cosimbld10',
			'ip' => '10.192.178.199',
			'os'   => 'Linux',
			'view' => 'ncs_sm5.0_part1',
			'errors' => ['Baseline WMX-AP_R5.0_BLD-1.31.01 is tested before and will be ignored!'],
			'buildresults' => '',
			'testsummary' => '',
			'testresults' => '',
			'mergestat' => IO.readlines(File.dirname(__FILE__) + '/mergestat_wmx-ap_r5.0_bld-1.22.00').join('<br/>'),
			'testedprojects' => [
				{'label' => 'WMX-AP_R5.0_BLD-1.16.13','passrate' => 100,'failrate' => 0.00,'modtime' => '2010-05-05 05:03:41'},
				{'label' => 'WMX-AP_R5.0_BLD-1.20.01', 'passrate' => 41.67, 'failrate' => 58.33, 'modtime' => '2010-05-25 04:16:59'},
				{'label' => 'WMX-AP_R5.0_BLD-1.22.01','passrate' => 0,'failrate' => 0,'block' => true,'modtime' => '2010-05-28 04:36:29'},
				{'label' => 'WMX-AP_R5.0_BLD-1.25.01','passrate' => 76.27,'failrate' => 23.73,'modtime' => '2010-06-20 04:56:29'}
			]
		}
		@mailer.build_email(mailmsgs)
		@mailer.store_email(File::dirname(__FILE__) + "/test.html")
		assert true, File.compare(File::dirname(__FILE__) + '/test.html', @mailer.outputdir + '/ncs_mail_test.html')
	end
	
	def test_buildmail2
		@mailer.project_release_label = 'WMX-AP_R5.0_BLD-1.31.01'
		@mailer.view = 'ncs_sm5.0_part1'
		@mailer.adderror('Baseline WMX-AP_R5.0_BLD-1.31.01 is tested before and will be ignored!')
		@mailer.addbuildresult('Generate ISL','IGNORED')
		@mailer.addbuildresult('Build SM','OK')
		@mailer.addbuildresult('Build Test','FAILED','error')
		@mailer.mergestat = IO.readlines(File.dirname(__FILE__) + '/mergestat_wmx-ap_r5.0_bld-1.22.00').join('<br/>')
		@properties.set("ncs.mail.store",'ncs_mail_test2.html')
		@mailer.build_email()
		@mailer.store_email(File::dirname(__FILE__) + "/test2.html")
		assert true, File.compare(File::dirname(__FILE__) + '/test2.html', @mailer.outputdir + '/ncs_mail_test2.html')
	end
	
	#how to ignore test, need find a way?
	def ignore_test_sendhtml
		@mailer.subject = 'test ruby smtp lib'
		@mailer.body = [
			'<div style="color:red;">', 
			'test ruby smtp<br/>', 
			'test ruby sendmail',
			'</div>']
		@mailer.sendhtml()
	end
	
	#how to ignore test, need find a way?
	def ignore_test_sendtext
		@mailer.subject = 'test ruby smtp lib'
		@mailer.body = [
			'test ruby smtp', 
			'test ruby sendmail',
			]
		@mailer.sendtext()
	end
	
	def teardown
		@mailer = nil
	end
end