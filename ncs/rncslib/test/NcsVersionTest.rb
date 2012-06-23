#!/usr/bin/ruby -w

require 'test/unit'
require 'logger'
require 'ncs/NcsVersion'

class NcsVersionTest < Test::Unit::TestCase
	@@ClassName = 'NcsVersionTest'
	
	def setup
		@ncsVersion = NcsVersion.new
	end
	
	def test_get_ncs_name
		assert_equal('Nightly Cosim Script', @ncsVersion.get_ncs_name())
	end
	
	def test_get_ncs_sname
		assert_equal('ncs', @ncsVersion.get_ncs_sname())
	end
	
	def test_get_ncs_version
		build_version = `date +%Y%m%d`.chomp()
		assert_equal("2.1-#{build_version}", @ncsVersion.get_ncs_version())
		@ncsVersion.major_version = 3
		@ncsVersion.minor_version = 0
		assert_equal("3.0-#{build_version}", @ncsVersion.get_ncs_version())
		@ncsVersion.version_extra = 'dev'
		assert_equal("3.0-#{build_version}-dev", @ncsVersion.get_ncs_version())
	end
	
	def test_get_ncs_release
		ncs_sname = @ncsVersion.get_ncs_sname()
		build_version = `date +%Y%m%d`.chomp()
		assert_equal("#{ncs_sname}2.1-#{build_version}", @ncsVersion.get_ncs_release())
	end
	
	def test_print_ncs_verbose
		puts "test print_ncs_verbose"
		@ncsVersion.print_ncs_verbose()
	end
	
	def teardown
		@ncsVersion = nil
	end
end