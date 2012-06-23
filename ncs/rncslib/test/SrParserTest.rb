#!/usr/bin/env ruby -w

require 'test/unit'
require 'spreadsheet'
require 'ncs/SrParser'

class SrParserTest < Test::Unit::TestCase
	@@ClassName = 'SrParserTest'
	def setup
	end
	
	def test_excel1
		@srparser = SrParser.new(File::dirname(__FILE__) + '/test_changes.xls')
		worksheet = @srparser.worksheet('licenses')
		assert_instance_of Spreadsheet::Excel::Worksheet, worksheet
		rowcount = @srparser.rowcount('licenses')
		colcount = @srparser.colcount('licenses')
		assert_equal(rowcount,20)
		assert_equal(colcount,4)
		assert_equal('KFC',@srparser.data('licenses', 1, 0))
		assert_equal('00-1F-3C-93-BB-28', @srparser.data('licenses',1,1))
	end
	
	def test_worksheet
		@srparser = SrParser.new(File::dirname(__FILE__) + '/WMX_CoSim_SR97.xls')
		worksheet = @srparser.worksheet('WMX4.0')
		assert_instance_of Spreadsheet::Excel::Worksheet, worksheet
		rowcount = @srparser.rowcount('WMX4.0')
		colcount = @srparser.colcount('WMX4.0')
		assert_equal(rowcount,12)
		assert_equal(colcount,8)
		assert_equal('MOTCM01329463',@srparser.data('WMX4.0', 1, 0).strip)
		assert_equal('NE', @srparser.data('WMX4.0',1,1))
	end
	
	def test_headline
		@srparser = SrParser.new(File::dirname(__FILE__) + '/WMX_CoSim_SR97.xls')
		headline = @srparser.headline('WMX4.0')
		puts headline
		assert_equal('#SR', headline[0])
		assert_equal('#Function', headline[1])
		assert_equal('#SR Headline', headline[2])
		assert_equal('#Assigned to', headline[3])
		assert_equal('#Status', headline[4])
		assert_equal('#Open Date', headline[5])
		assert_equal('#Close Date', headline[6])
		assert_equal('#Load Info', headline[7])
	end
	
	def test_srlist
		@srparser = SrParser.new(File::dirname(__FILE__) + '/WMX_CoSim_SR97.xls')
		srlist = @srparser.srlist('WMX4.0')
		assert_equal(11, srlist.length)
		assert_instance_of Hash, srlist[10]
		assert_equal('MOTCM01296608', srlist[10].fetch('#SR'))
		assert_equal('MODEL ERROR', srlist[10].fetch('#Function'))
	end
	
	def test_srlistBy
		@srparser = SrParser.new(File::dirname(__FILE__) + '/WMX_CoSim_SR97.xls')
		srlistBy = @srparser.srlistBy('WMX4.0','#Status', ['Assessed','Originated'])
		assert_equal(9, srlistBy.length)
		assert_instance_of Hash, srlistBy[8]
		assert_equal('MOTCM01296608', srlistBy[8].fetch('#SR'))
		assert_equal('MODEL ERROR', srlistBy[8].fetch('#Function'))
	end
	
	def test_srlistNot
		@srparser = SrParser.new(File::dirname(__FILE__) + '/WMX_CoSim_SR97.xls')
		srlistBy = @srparser.srlistNot('WMX4.0','#Status', ['Closed'])
		assert_equal(9, srlistBy.length)
		assert_instance_of Hash, srlistBy[8]
		assert_equal('MOTCM01296608', srlistBy[8].fetch('#SR'))
		assert_equal('MODEL ERROR', srlistBy[8].fetch('#Function'))
	end
	
	def test_latestSrlist
		@srparser = SrParser.new(File::dirname(__FILE__) + '/WMX_CoSim_SR97.xls')
		latestSrlist = @srparser.latestSrlist('WMX4.0')
		assert_equal(1, latestSrlist.length)
		assert_instance_of Hash, latestSrlist[0]
		assert_equal('MOTCM01341419', latestSrlist[0].fetch('#SR'))
		assert_equal('NE', latestSrlist[0].fetch('#Function'))
	end
	
	def test_srById
		@srparser = SrParser.new(File::dirname(__FILE__) + '/WMX_CoSim_SR97.xls')
		sr = @srparser.srById('WMX4.0','MOTCM01341419')
		assert_instance_of Hash,sr
		assert_equal('NE', sr.fetch('#Function'))
		assert_equal('Assessed', sr.fetch('#Status'))
		assert_equal('7/15/2010 6:07:40 AM', sr.fetch('#Open Date'))
		assert_equal('WMX-AP_R4.0_BLD-1.48.01', sr.fetch('#Load Info'))
	end
	
	def test_srMappings
		@srparser = SrParser.new(File::dirname(__FILE__) + '/WMX_CoSim_SR97.xls')
		srMappings = @srparser.srMappings('WMX4.0 CASE-SR Mapping')
		rowcount = @srparser.rowcount('WMX4.0 CASE-SR Mapping').to_s
		(rowmin,rowmax) = @srparser.rowrange('WMX4.0 CASE-SR Mapping')
		puts "WMX4.0 CASE-SR Mapping row count: #{rowcount}"
		puts "WMX4.0 CASE-SR Mapping row range: #{rowmin}-#{rowmax}"
		assert_equal(669, srMappings.length)
		puts srMappings.values_at('18000','18005','18006','18007','18008')
		assert_equal('MOTCM01337041', srMappings.fetch('18008'))
	end
	
	def test_srMapping
		@srparser = SrParser.new(File::dirname(__FILE__) + '/WMX_CoSim_SR97.xls')
		srMapping = @srparser.srMapping('WMX4.0 CASE-SR Mapping','18008')
		srMapping2 = @srparser.srMapping('WMX4.0 CASE-SR Mapping',18008)
		assert_equal('MOTCM01337041', srMapping)
		assert_equal('MOTCM01337041', srMapping2)
	end
	
	def teardown
		@srparser = nil
	end
end
