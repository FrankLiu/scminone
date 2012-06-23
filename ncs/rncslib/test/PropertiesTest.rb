#!/usr/bin/ruby -w

require 'test/unit'
require 'logger'
require 'ncs/Properties'

class PropertiesTest < Test::Unit::TestCase
	@@ClassName = 'PropertiesTest'
	def setup
		@properties = Properties.new
		ENV['NCS_HOME'] = @ncshome = File::dirname(__FILE__) + '/../../ncshome'
	end
	
	def test_load
		puts "----------test load method----------"
		@properties.load("#{@ncshome}/conf.init/ncs_sm5.0.properties")
		puts "#{@properties.size} key value pairs defined in the properties file"
		assert(@properties.size > 0, "the size should be more than 0")
		assert_equal(0, @properties.getint('ncs.option.compile_isl'))
		assert_equal(1, @properties.getint('ncs.option.compile_model'))
		assert_equal(1, @properties.getint('ncs.option.compile_test'))
		assert_equal('NONE', @properties.get('ncs.option.ignore_test'))
		assert_equal('openr6,rrm,motor6,rrm_motor6', @properties.get('ncs.test.suite'))
	end
	
	def test_setget
		puts "----------test set & get method----------"
		@properties.set('ncs.tmp.test', 'testsetget');
		assert_equal('testsetget', @properties.get('ncs.tmp.test'))
	end
	
	def test_dump
		@properties.load("#{@ncshome}/conf.init/ncs_sm5.0.properties")
		puts "----------test dump method----------"
		@properties.dump
	end
	
	def teardown
		@properties = nil
	end
end
