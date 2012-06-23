#!/usr/bin/env python
"""
model test suite.
"""
import sys, os
import unittest

# adding current directory to path to make sure local modules can be imported
sys.path.insert(0, '.')
sys.path.insert(0, 'lib')
from ncs.model import *

class ProjectTestSummaryTest(unittest.TestCase):
	def setUp(self):
		pass
		
	def test_loadall(self):
		projects = ProjectTestSummary.loadall('test/projects.txt', 32)
		print(">>>>>>>>>>>>>WMX5.0 SM projects: {0}>>>>>>>>>>>>".format(len(projects)))
		for project in projects:
			print(project)
	
	def test_loadallasjson(self):
		json = ProjectTestSummary.loadallasjson('test/projects.txt',32)
		print(">>>>>>>>>>>>>WMX5.0 SM projects as json>>>>>>>>>>>>")
		print(json)
		
	def test_isrecorded(self):
		pts = ProjectTestSummary('WMX-AP_R5.0_BLD-19.03.00', 93.18, 6.82)
		if pts.isrecorded('test/projects.txt'):
			print("Project WMX-AP_R5.0_BLD-19.03.00 is recorded")
			
		pts = ProjectTestSummary('WMX-AP_R5.0_BLD-19.05.00', 93.18, 6.82)
		if pts.isrecorded('test/projects.txt'):
			print("Project WMX-AP_R5.0_BLD-19.05.00 is recorded")
			
	def test_record(self):
		pts = ProjectTestSummary('WMX-AP_R5.0_BLD-19.05.00', 93.18, 6.82)
		pts.record('test/projects.txt')
		
if __name__ == "__main__":
    unittest.main()
    