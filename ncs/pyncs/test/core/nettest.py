#!/usr/bin/env python
"""
net test suite.
"""

import sys, os
import unittest

# adding current directory to path to make sure local modules can be imported
sys.path.insert(0, '.')
from ncs.core.net import *

class FtpTest(unittest.TestCase):
	def setUp(self):
		self.ftp = Ftp('isdmldlinux.comm.mot.com','fcgd46','Lujun296')

	def test_ls(self):
		dir = '/mot/proj/wibb_bts/cmbp/prod/cm-policy/config/WIBB_BTS_projects'
		self.ftp.cd(dir)
		files = self.ftp.ls('-t WMX-AP_R5.0_BLD-*.prj')
		print("There are {0} files under dir {1}".format(len(files), dir))
		for file in files:
			print(">>>>> {0}".format(file))
		dir = '/mot/proj/wibb_load2/daily/{0}'.format(files[0][:-4])
		files = self.ftp.ls(dir)
		print("There are {0} files under dir {1}".format(len(files), dir))
		for file in files:
			print(">>>>> {0}".format(file))

if __name__ == "__main__":
    unittest.main()
    
