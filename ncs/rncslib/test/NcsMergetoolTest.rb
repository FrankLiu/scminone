#!/usr/bin/env ruby -w

require 'test/unit'
require 'ncs/NcsMergetool'

class NcsMergetoolTest < Test::Unit::TestCase
	@@ClassName = 'NcsMergetoolTest'
	def setup
	end
	
	def test_merge2
		dir = File.dirname(__FILE__)
		startpattern = /<span>Below is the quick check for CoSim SR list<\/span>/
		stoppattern =/<\/table>/
		split = '-'*50
		merged = NcsMergetool.merge2(dir+"/sr_merged.html",split,startpattern,stoppattern,dir+"/sr_list.html",dir+"/test.html")
		puts merged
	end
	
	def teardown
		
	end
end