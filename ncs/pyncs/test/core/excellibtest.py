#!/usr/bin/env python
"""
excellib test suite.
"""

import sys, os
import unittest

# adding current directory to path to make sure local modules can be imported
sys.path.insert(0, '.')
sys.path.insert(0, 'lib')
from ncs.core.excellib import Xls

class XlsTest(unittest.TestCase):
	def setUp(self):
		self.xls = Xls('test/WMX_CoSim_SR.xls')

	def test_parse(self):
		self.xls.parse()
		print("total sheets: {0}".format(len(self.xls.sheets())))
		print("sheets: {0}".format(self.xls.sheet_names()))
		sheet_1 = 'WMX5.0'
		print("rows [{0}], cols [{1}]".format(self.xls.get_rows(sheet_1), self.xls.get_cols(sheet_1)))
		
if __name__ == "__main__":
    unittest.main()
    
