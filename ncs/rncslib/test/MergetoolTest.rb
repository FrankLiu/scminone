#!/usr/bin/env ruby -w

require 'test/unit'
require 'ncs/Mergetool'

class MergetoolTest < Test::Unit::TestCase
	@@ClassName = 'MergetoolTest'
	def setup
	end
	
	def test_merge2
		dir = File.dirname(__FILE__)
		startpattern = /<span>Below is the quick check for CoSim SR list<\/span>/
		stoppattern =/<\/table>/
		merged = Mergetool.merge2(startpattern,stoppattern,dir+"/sr_list.html",dir+"/test.html")
		puts merged
	end
	
	def teardown
		@excellib = nil
	end
end