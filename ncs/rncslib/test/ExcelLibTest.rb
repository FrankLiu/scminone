#!/usr/bin/env ruby -w

require 'test/unit'
require 'logger'
require 'spreadsheet'
require 'ncs/ExcelLib'

class ExcelLibTest < Test::Unit::TestCase
	@@ClassName = 'ExcelLibTest'
	def setup
	end
	
	def test_excel1
		@excellib = ExcelLib.new(File::dirname(__FILE__) + '/test_changes.xls')
		worksheet = @excellib.worksheet('licenses')
		assert_instance_of Spreadsheet::Excel::Worksheet, worksheet
		rowcount = @excellib.rowcount('licenses')
		colcount = @excellib.colcount('licenses')
		assert_equal(rowcount,20)
		assert_equal(colcount,4)
		assert_equal('KFC',@excellib.data('licenses', 1, 0))
		assert_equal('00-1F-3C-93-BB-28', @excellib.data('licenses',1,1))
	end
	
	def test_worksheet
		@excellib = ExcelLib.new(File::dirname(__FILE__) + '/WMX_CoSim_SR97.xls')
		worksheet = @excellib.worksheet('WMX4.0')
		assert_instance_of Spreadsheet::Excel::Worksheet, worksheet
		rowcount = @excellib.rowcount('WMX4.0')
		colcount = @excellib.colcount('WMX4.0')
		assert_equal(rowcount,12)
		assert_equal(colcount,8)
		assert_equal('MOTCM01329463',@excellib.data('WMX4.0', 1, 0))
		assert_equal('NE', @excellib.data('WMX4.0',1,1))
	end
	
	def teardown
		@excellib = nil
	end
end
