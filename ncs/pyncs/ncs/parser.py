#!/usr/bin/env python
"""
NCS Parser: SrParser, TtpParser
"""
from ncs.model import *
from ncs.core.excellib import Xls
from ncs.exceptions import *
from datetime import date
import re

class SR(object):
	pass
class SrMapping(object):
	def __init__(self, tcno, srno):
		self.tcno = tcno
		self.srno = srno
	
class SrParser:
	def __init__(self, excel_file):
		self.xls = Xls(excel_file)
		self.xls.parse()
		
	def headline(self, sheet_name):
		header = []
		sheet = self.xls.get_sheet(sheet_name)
		ncols = self.xls.get_cols(sheet_name)
		for i in range(0,ncols):
			header.append(self.xls.get_data(sheet_name, 0, i))
		return header
	
	def srlist(self, sheet_name):
		srlist = []
		sheet = self.xls.get_sheet(sheet_name)
		nrows = self.xls.get_rows(sheet_name)
		ncols = self.xls.get_cols(sheet_name)
		headline = self.headline(sheet_name)
		for row in range(1,nrows):
			sr = SR()
			for col in range(0,ncols):
				data = self.xls.get_data(sheet_name, row, col)
				setattr(sr, headline[col], data)
			srlist.append(sr)
		return srlist
	
	def srById(self, sheet_name, srid):
		srlist = self.srlistBy(sheet_name, '#SR', [srid])
		if len(srlist) > 0:
			return srlist[0]
		return None
		
	def srlistBy(self, sheet_name, byType, byVals=[], excludes=False):
		srlistBy = []
		srlist = self.srlist(sheet_name)
		def contains(sr):
			value = getattr(sr, byType)
			if value: value = value.upper()
			for byVal in byVals:
					if byVal.upper() in value: return True
			return False
		def notcontains(sr):
			value = getattr(sr, byType)
			if value: value = value.upper()
			for byVal in byVals:
					if not byVal.upper() in value: return True
			return False
		if excludes:
			srlistBy = filter(notcontains, srlist)
		else:
			srlistBy = filter(contains, srlist)
		return srlistBy
	
	def srlistNot(self, sheet_name, byType, byVals=[]):
		return self.srlistBy(sheet_name, byType, byVals, True)
		
	def latestSrlist(self, sheet_name):
		latestSrlist = []
		srlist = self.srlistNot(sheet_name, '#Status', ['Closed', 'Performed'])
		def parseDate(dateStr):
			if not dateStr: return None
			(month,day,year) = dateStr.split('/')
			return date(int(year),int(month),int(day))
			
		for sr in srlist:
			(openDate, openTime) = getattr(sr, '#Open Date').split(' ',1)
			#print("open date: {0}".format(openDate))
			if len(latestSrlist) == 0:
				latestSrlist.append(sr)
				continue
			
			(latestOpenDate, latestOpenTime) = getattr(latestSrlist[0], '#Open Date').split(' ', 1)
			#print("latest open date: {0}".format(latestOpenDate))
			od = parseDate(openDate)
			lod = parseDate(latestOpenDate)
			if od == lod:
				latestSrlist.append(sr)
			elif od > lod:
				#delete all elements & insert new one
				del latestSrlist[:]
			else: #od < lod 
				pass #do nothing, just ignore the sr
		return latestSrlist
	
	def srsummary(self, sheet_name):
		srsummary = ''
		for status in ['Originated','Assessed','Study','Performed','Closed']:
			srlen = len(self.srlistBy(sheet_name, '#Status', [status]))
			if status == 'Closed':
				srsummary += "{0} [{1}]".format(status, srlen)
			else:
				srsummary += "{0} [{1}], ".format(status, srlen)
		return srsummary
		
	def srmappings(self, sheet_name):
		srlist = self.srlist(sheet_name)
		srMappings = []
		for sr in srlist:
			tcno = getattr(sr, '#Failed Case No.')
			srno = getattr(sr, '#SR No.')
			#print("{0} = {1}".format(tcno, srno)
			srmapping = SrMapping(int(tcno), srno.strip())
			srMappings.append(srmapping)
		return srMappings
	
	def srno(self, sheet_name, tcno):
		srMappings = self.srmappings(sheet_name)
		for srmapping in srMappings:
			if srmapping.tcno == int(tcno): return srmapping.srno
		return ''
	
	def tclist(self, sheet_name, srno):
		tclist = []
		srMappings = self.srmappings(sheet_name)
		for srmapping in srMappings:
			if srmapping.srno == srno.strip(): 
				tclist.append(srmapping.tcno)
		return tclist
		
	#specific functions for WMX_CoSim_SR
	def srlist4SM40(self, byType, byVals=[]):
		if byType and byVals:
			return self.srlistBy('WMX4.0', byType, byVals)
		return self.srlist('WMX4.0')

	def srlist4SM50(self, byType, byVals=[]):
		if byType and byVals:
			return self.srlistBy('WMX5.0', byType, byVals)
		return self.srlist('WMX5.0')

	def srMappings4SM40(self):
		return self.srMappings('WMX4.0 CASE-SR Mapping')

	def srMappings4SM50(self):
		return self.srMappings('WMX5.0 CASE-SR Mapping')

	def srMappings4SFM40(self):
		return self.srMappings('WMX4.0 SFM CASE-SR Mapping')
		
	def srMappings4SFM50(self):
		return self.srMappings('WMX5.0 SFM CASE-SR Mapping')

class TtpParser:
	def __init__(self, ttp_file):
		self.ttp_file = ttp_file
	
	def parse(self):
		definitions = {}
		values = {}
		is_def_block = False
		is_val_block = False
		def_name = ''
		val_name = ''
		BLANK_LINE = re.compile(r'^$')
		DEF_BLOCK_START = re.compile(r'(\w+) ::= SEQUENCE OF \{')
		DEF_BLOCK_END = re.compile(r'^\}$')
		VAL_BLOCK_START = re.compile(r'(\w+) ::= \{')
		VAL_BLOCK_END = re.compile(r'^\}$')
		fp = open(self.ttp_file, 'r')
		for line in fp.readlines():
			line = line.strip()
			
			#blank line
			if BLANK_LINE.search(line): continue
			
			#parse definition block
			if DEF_BLOCK_START.search(line):
				#definition block start
				is_def_block = True
				def_name = DEF_BLOCK_START.search(line).group(1);
				definitions[def_name] = []
			if is_def_block and def_name:
				#print("{0}: {1}".format(def_name, line))
				definitions[def_name].append(line)
			if is_def_block and def_name and DEF_BLOCK_END.search(line):
				is_def_block = False
				def_name = ''
				
			#parse value block
			if VAL_BLOCK_START.search(line):
				#value block start
				is_val_block = True
				val_name = VAL_BLOCK_START.search(line).group(1)
				values[val_name] = []
			if is_val_block and val_name:
				#print("{0}: {1}".format(val_name, line))
				values[val_name].append(line)
			if is_val_block and val_name and VAL_BLOCK_END.search(line):
				#value block end
				is_val_block = True
				val_name = ''
		self.definitions = definitions
		self.values = values
		
	def getDefinitionAsArray(self, name):
		if self.definitions.has_key(name):
			return self.definitions.get(name)
		return []
	
	def getDefinition(self, name):
		defs = self.getDefinitionAsArray(name)
		definition = ''
		if defs:
			definition = reduce(lambda x,y: x+"\n"+y, defs)
		return ''
	
	def getValueAsArray(self, name):
		if self.values.has_key(name):
			return self.values.get(name)
		return []
	
	def getValue(self, name):
		vals = self.getDefinitionAsArray(name)
		value = ''
		if vals:
			value = reduce(lambda x,y: x+"\n"+y, vals)
		return ''
	
	def getProp(self, name):
		props = self.getValueAsArray('prop')
		for p in props:
			if re.search(name, p):
				vals = p.split(',')
				if len(vals) >= 5:
					val = vals[4]
					#print(val)
					#remove {" and "}},
					return val.replace('{', '').replace('}','').replace('"','')
		return ""
	
	def getTtcns(self):
		files = self.getValueAsArray('file_ref')
		ttcns = []
		for file in files:
			if re.search(r'\.ttcn', file):
				vals = file.split(',', 3)
				if len(vals) >= 3:
					val = vals[2]
					#print(val)
					#remove {" and "}},
					val = val.replace('{', '').replace('}','').replace(',','')
					#remove " and } and \\, replace \\\\ with /
					val = val.replace('"','').replace('}','')
					val = val.replace("\\\\",'/')
					#print(val)
					ttcns.append(val)
		return ttcns
	
	def getMakefile(self):
		return self.getProp('MAKE_FILE')
		
	def getMakeCommand(self):
		return self.getProp('MAKE_COMMAND')
	
	def getRootModule(self):
		return self.getProp('ROOT_MODULE')
	
	def getProduct(self):
		return self.getProp('PRODUCT')
	
	def getOutputDirectory(self):
		return self.getProp('OUTPUT_DIRECTORY')
		
		
	