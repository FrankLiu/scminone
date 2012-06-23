#!/usr/bin/env ruby -w

require 'test/unit'
require 'ncs/Template'

class TemplateTest < Test::Unit::TestCase
	@@ClassName = 'TemplateTest'
	
	def setup
		@template = nil
		@srs = [{
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
		}]
		@srsummary = {
			'Originated' => 0,
			'Assessed' => 2,
			'Study' => 14,
			'Performed' => 7,
			'Closed' => 9,
		}
	end
	
	def ignore_test_render_sr_list
		@template = Template.new(File.dirname(__FILE__)+"/../ncs/templates/sr_list.html")
		def getBinding(srs=[], srsummary={})
			return binding()
		end
		output = @template.render(getBinding(@srs,@srsummary), './test/sr_list.html')
		puts output
	end
	
	def test_render_mail_template
		@template = Template.new(File.dirname(__FILE__)+"/../ncs/templates/mail_template.html")
		title = '[SM Cosim Nightly Script 5.0] WMX-AP_R5.0_BLD-1.31.01'
		sr_link = 'http://compass.mot.com/doc/353641209/WMX_CoSim_SR.xls'
		report_link = 'http://compass.mot.com/doc/354461914/CoSim-NCS-WMX5.0.ppt'
		host = 'zch66cosimbld10'
		ip = '10.192.178.199'
		os = 'Linux'
		view = 'ncs_sm5.0_part1'
		errors = ['Baseline WMX-AP_R5.0_BLD-1.31.01 is tested before and will be ignored!']
		buildresults = [
				{'compile_message' => 'Generate ISL', 'compile_result'=> 'OK', 'style'=>''},
				{'compile_message' => 'Compile SM', 'compile_result'=> 'OK', 'style'=>''},
				{'compile_message' => 'Compile TTCN', 'compile_result'=> 'OK', 'style'=>''}
			]
		testsummary = {
			'total' => 1115,
			'passed' => 149,
			'failed' => 966,
			'error' => 0,
			'passrate' => 13.36
		}
		testresults = [
				{'caseno' => 1, 'result' => 'PASS', 'style' => 'pass', 'srdesc' => ''},
				{'caseno' => 1003, 'result' => 'FAILED', 'style' => 'failed', 'srdesc' => 'MOTCM01321578'},
				{'caseno' => 1004, 'result' => 'ERROR', 'style' => 'error', 'srdesc' => 'New failed case, need to be analyzed'},
				{'caseno' => 1005, 'result' => 'FAILED', 'style' => 'failed', 'srdesc' => 'New failed case, need to be analyzed'},
				{'caseno' => 10006, 'result' => 'FAILED', 'style' => 'failed', 'srdesc' => 'MOTCM01345326'},
			]
		testedprojects = [
				{'label' => 'WMX-AP_R5.0_BLD-1.16.13','passrate' => 100,'failrate' => 0.00,'modtime' => '2010-05-05 05:03:41'},
				{'label' => 'WMX-AP_R5.0_BLD-1.20.01', 'passrate' => 41.67, 'failrate' => 58.33, 'modtime' => '2010-05-25 04:16:59'},
				{'label' => 'WMX-AP_R5.0_BLD-1.22.01','passrate' => 0,'failrate' => 0,'block' => true,'modtime' => '2010-05-28 04:36:29'},
				{'label' => 'WMX-AP_R5.0_BLD-1.25.01','passrate' => 76.27,'failrate' => 23.73,'modtime' => '2010-06-20 04:56:29'}
			]
		buildlogdir = '/tmp/ncslog/sm5.0/WMX-AP_R5.0_BLD-1.32.07/buildlog'
		testlogdir = '/tmp/ncslog/sm5.0/WMX-AP_R5.0_BLD-1.32.07/testlog'
		attributes = {
			'title' => title,
			'sr_link' => sr_link,
			'report_link' => report_link,
			'srs' => @srs,
			'srsummary' => @srsummary,
			'host' => host,
			'ip' => ip,
			'os' => os,
			'view' => view,
			#'errors' => errors,
			'buildresults' => buildresults,
			'testsummary' => testsummary,
			'testresults' => testresults,
			'testedprojects' => testedprojects,
			'buildlogdir' => buildlogdir,
			'testlogdir' => testlogdir
		}
		output = @template.render(attributes, './test/ncs_mail.html')
		puts output
	end
	
	def teardown
		@template = nil
	end
end