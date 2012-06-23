#!/usr/bin/env python
"""
mail builder test suite.
"""

import sys, os
import unittest

# adding current directory to path to make sure local modules can be imported
sys.path.insert(0, '.')
sys.path.insert(0, 'lib')
from ncs.mail.builder import Builder
from ncs.model import *

class BuilderTest(unittest.TestCase):
	def setUp(self):
		pass
	
	def init_project(self, loadversion):
		project = Project(loadversion)
		project.loadversion(loadversion)
		project.title("[SM Cosim Nightly Script 5.0] {0}".format(loadversion))
		project.srlink('http://compass.mot.com/doc/353641209/WMX_CoSim_SR.xls')
		project.reportlink('http://compass.mot.com/doc/354461914/CoSim-NCS-WMX5.0.ppt')
		project.projectstestsummary('test/projects.txt')
		project.srtable('test/WMX_CoSim_SR.xls', 'WMX5.0')
		project.mergestat('test/mergestat_wmx-ap_r5.0_bld-20.00.00')
		return project
	
	def init_project_runner(self, loadversion):
		runner = ProjectRunner(loadversion)
		runner.hostinfo()
		runner.workview('ncs_sm5.0_part1')
		runner.buildlogdir('http://10.192.185.187/ncslog/{0}/buildlog'.format(loadversion))
		runner.testlogdir('http://10.192.185.187/ncslog/{0}/testlog'.format(loadversion))
		runner.addbuildresult('Generate ISL', CopmileResult.IGNORED)
		runner.addbuildresult('Buiding SM', CopmileResult.OK)
		runner.addbuildresult('Buiding Test', CopmileResult.OK)
		#runner.adderror('Load WMX-AP_R5.0_BLD-17.07.00 is tested before!')
		runner.addtestresult('1002', TestResult.PASS)
		runner.addtestresult('1003', TestResult.PASS)
		runner.addtestresult('1005', TestResult.PASS)
		runner.addtestresult('1006', TestResult.FAIL, 'New failed case, need to be analyzed')
		runner.addtestresult('1007', TestResult.PASS)
		runner.addtestresult('1008', TestResult.TIMEOUT)
		return runner
		
	def init_project_runner2(self, loadversion):
		runner = ProjectRunner(loadversion)
		runner.hostinfo()
		runner.workview('ncs_sm5.0_part2')
		runner.buildlogdir('http://10.192.185.188/ncslog/{0}/buildlog'.format(loadversion))
		runner.testlogdir('http://10.192.185.188/ncslog/{0}/testlog'.format(loadversion))
		runner.addbuildresult('Generate ISL', 'IGNORED')
		runner.addbuildresult('Buiding SM', 'OK')
		runner.addbuildresult('Buiding Test', 'OK')
		#project.adderror('Load WMX-AP_R5.0_BLD-17.07.00 is tested before!')
		runner.addtestresult('20001', TestResult.PASS)
		runner.addtestresult('20002', TestResult.UML_WARNING)
		runner.addtestresult('20003', TestResult.PASS)
		runner.addtestresult('20004', TestResult.PASS)
		runner.addtestresult('20005', TestResult.PASS)
		runner.addtestresult('20233', TestResult.FAIL, 'MOTCM01369001')
		runner.addtestresult('20235', TestResult.UML_ERROR)
		runner.addtestresult('21129', TestResult.PASS)
		return runner
		
	def test_render(self):
		loadversion = 'WMX-AP_R5.0_BLD-17.07.00'
		project = self.init_project(loadversion)
		project.addrunner(self.init_project_runner(loadversion))
		project.addrunner(self.init_project_runner2(loadversion))
		builder = Builder();
		builder.render(project)
		builder.output('test/mail_test.html')
		
if __name__ == "__main__":
    unittest.main()
    
