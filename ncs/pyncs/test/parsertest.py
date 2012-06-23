#!/usr/bin/env python
"""
parser test suite.
"""
import sys, os
import unittest

# adding current directory to path to make sure local modules can be imported
sys.path.insert(0, '.')
sys.path.insert(0, 'lib')
from ncs.parser import *

class SrParserTest(unittest.TestCase):
	def setUp(self):
		self.srparser = SrParser('test/WMX_CoSim_SR.xls')
		
	def test_headline(self):
		headline = self.srparser.headline('WMX5.0')
		print(">>>>>>>>>>>>>WMX5.0 headline>>>>>>>>>>>>")
		print(headline)

	def test_srlist(self):
		srlist = self.srparser.srlist('WMX5.0')
		self.assert_(len(srlist), 31)
		print(">>>>>>>>>>>>>WMX5.0 SR list: {0} >>>>>>>>>>>>".format(len(srlist)))
		for sr in srlist:
			pass#print("{0}".format(sr.__dict__))
		
	def test_srlistBy(self):
		srlistBy = self.srparser.srlistBy('WMX5.0', '#Status', ['Study'])
		print(">>>>>>>>>>>>>WMX5.0 SR list by [#Status = Study]: {0} >>>>>>>>>>>>".format(len(srlistBy)))
		for sr in srlistBy:
			pass#print("{0}".format(sr.__dict__))
		srlistBy = self.srparser.srlistBy('WMX5.0', '#Status', ['performed'])
		print(">>>>>>>>>>>>>WMX5.0 SR list by [#Status = Performed]: {0} >>>>>>>>>>>>".format(len(srlistBy)))
		for sr in srlistBy:
			pass#print("{0}".format(sr.__dict__))
	
	def test_srlistNot(self):
		srlistBy = self.srparser.srlistNot('WMX5.0', '#Status', ['Closed'])
		print(">>>>>>>>>>>>>WMX5.0 SR list by [#Status != Closed]: {0} >>>>>>>>>>>>".format(len(srlistBy)))
		for sr in srlistBy:
			pass#print("{0}".format(sr.__dict__))
			
	def test_srById(self):
		sr = self.srparser.srById('WMX5.0', 'MOTCM01335839')
		self.assert_(getattr(sr, '#Function'), 'Model Error')
		self.assert_(getattr(sr, '#Open Date'), '6/30/2010 11:11:28AM')
	
	def test_latestSrlist(self):
		srlist = self.srparser.latestSrlist('WMX5.0')
		print(">>>>>>>>>>>>>WMX5.0 latest SR list by [#Status != Closed and Performed]: {0} >>>>>>>>>>>>".format(len(srlist)))
		for sr in srlist:
			print("{0}".format(sr.__dict__))
	
	def test_srsummary(self):
		srsummary = self.srparser.srsummary('WMX5.0')
		print("SR Summary: {0}".format(srsummary))
		
	def test_srmappings(self):
		srmappings = self.srparser.srmappings('WMX5.0 CASE-SR Mapping')
		print(">>>>>>>>>>>>>WMX5.0 CASE-SR Mappings: {0} >>>>>>>>>>>>".format(len(srmappings)))
		#print(srmappings)
	
	def test_srno(self):
		srno = self.srparser.srno('WMX5.0 CASE-SR Mapping', 1201)
		print(">>>>>>>>>>>>>WMX5.0 CASE-SR Mapping: {0} - {1} >>>>>>>>>>>>".format(1201, srno))
		self.assert_(srno, 'MOTCM01321578')
		srno = self.srparser.srno('WMX5.0 CASE-SR Mapping', 9)
		print(">>>>>>>>>>>>>WMX5.0 CASE-SR Mapping: {0} - {1} >>>>>>>>>>>>".format(9, srno))
		self.assert_(srno, 'MOTCM01321629')
	
	def test_tclist(self):
		tclist = self.srparser.tclist('WMX5.0 CASE-SR Mapping', 'MOTCM01324981')
		print(">>>>>>>>>>>>>WMX5.0 CASE-SR Mapping: {0} - {1} >>>>>>>>>>>>".format('MOTCM01324981', tclist))
		tclist = self.srparser.tclist('WMX5.0 CASE-SR Mapping', 'MOTCM01324980')
		print(">>>>>>>>>>>>>WMX5.0 CASE-SR Mapping: {0} - {1} >>>>>>>>>>>>".format('MOTCM01324980', tclist))
		
class TtpParserTest(unittest.TestCase):
	def setUp(self):
		self.ttpparser = TtpParser('test/CoSim.ttp')
		self.ttpparser.parse()
		
	def test_getTtcns(self):
		ttcns = self.ttpparser.getTtcns()
		self.assert_(31, len(ttcns))
		print("Ttcns total {0}".format(len(ttcns)))
		for ttcn in ttcns:
			print(ttcn)
	
	def test_getMakefile(self):
		makefile = self.ttpparser.getMakefile()
		self.assert_(makefile, 'build/TestModule.mak')
		print("Makefile {0}".format(makefile))
	
	def test_getMakeCommand(self):
		makecommand = self.ttpparser.getMakeCommand()
		self.assert_(makecommand, 'make -f')
		print("Make command {0}".format(makecommand))
		
	def test_getRootModule(self):
		rootmodule = self.ttpparser.getRootModule()
		self.assert_(rootmodule, 'SM_OpenR6')
		print("Root module {0}".format(rootmodule))
	
	def test_getProduct(self):
		product = self.ttpparser.getProduct()
		self.assert_(product, 'ttcn3')
		print("Product {0}".format(product))
		
	def test_getOutputDirectory(self):
		outputdir = self.ttpparser.getOutputDirectory()
		self.assert_(outputdir, 'build')
		print("Output Directory {0}".format(outputdir))
		
if __name__ == "__main__":
    unittest.main()
    