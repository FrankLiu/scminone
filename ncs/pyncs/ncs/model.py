#!/usr/bin/env python
"""
NCS Model: ProjectTestSummary, SR, SrMapping
"""
import os
import re
import time
import socket
import pickle
from decimal import *
from ncs.exceptions import *
from ncs.parser import *

class CopmileResult:
	OK = 'OK'
	FAILED = 'FAILED'
	IGNORED = 'IGNORED'
class TestResult:
	PASS = 'PASS'
	FAIL = 'FAIL'
	UML_ERROR = 'UML Error'
	UML_WARNING = 'UML Warning'
	TIMEOUT = 'Timeout'
	
class Project(object):
	def __init__(self, label):
		self.label = label
		self.projectrunners = []
	
	def loadversion(self, loadversion): self.loadversion = loadversion
	def title(self, title): self.title = title
	def srlink(self, sr_link): self.sr_link = sr_link
	def reportlink(self, report_link): self.report_link = report_link
	def projectstestsummary(self, pts_file): self.projects_test_summary = ProjectTestSummary.loadallasjson(pts_file)
	def srtable(self, srfile, sheet_name):
		srparser = SrParser(srfile)
		self.srheadline = srparser.headline(sheet_name)
		srs = srparser.latestSrlist(sheet_name)
		srhtml = []
		for sr in srs:
			srtr = []
			for h in self.srheadline:
				srtr.append(getattr(sr, h))
			srhtml.append(srtr)
		self.srhtml = srhtml
		self.srsummary = srparser.srsummary(sheet_name)
	def mergestat(self, mergestat_file):
		mergestat = []
		fh = open(mergestat_file)
		[mergestat.append(line.strip()+"<br/>") for line in fh.readlines()]
		self.mergestat = reduce((lambda x,y: x+y), mergestat)
	
	def addrunner(self, project_runner):
		self.projectrunners.append(project_runner)
	
	def testresultsummary(self):
		def get_number(type):
			number = 0
			for pr in self.projectrunners:
				number += int(pr.testresultsummary().get(type,0))
			return number
		total = get_number('total')
		passed = get_number('pass')
		fail = 	get_number('fail')
		error = get_number('error')
		myothercontext = Context(prec=4, rounding=ROUND_HALF_DOWN)
		setcontext(myothercontext)
		passrate = Decimal(passed)/Decimal(total)*100
		#print("total - {0}, pass - {1}, passrate - {2}%".format(total, passed, passrate))
		failrate = Decimal(100) - passrate
		self.testsummary = {
				'total': total,
				'pass': passed,
				'fail': fail,
				'error': error,
				'passrate': passrate,
				'failrate': failrate
			}
		return self.testsummary
		
	def dump(self, file):
		output = open(file, 'wb')
		pickle.dump(self, output)
		output.close()
	
	@staticmethod
	def load(file):
		pkl_file = open(file, 'rb')
		data = pickle.load(pkl_file)
		pkl_file.close()
		return data

class ProjectRunner(object):
	def __init__(self, label):
		self.label = label
		self.buildresults = []
		self.errors = []
		self.testresults = []
	
	def hostinfo(self, host='', ipaddr='', osname=''):
		self.host = socket.gethostname()
		self.ipaddr = socket.gethostbyname(self.host)
		self.osname = os.uname()[0]
	def workview(self, workview):
		self.workview = workview
	def buildlogdir(self, buildlogdir):
		self.buildlogdir = buildlogdir
	def testlogdir(self, testlogdir):
		self.testlogdir = testlogdir
	def addbuildresult(self, compile_message, compile_result):
		style = 'fail'
		if compile_result == CopmileResult.OK or compile_result == CopmileResult.IGNORED:
			style = 'pass'
		self.buildresults.append({
			'compile_message': compile_message,
			'compile_result': compile_result,
			'style': style})
	def adderror(self, error_message):
		self.errors.append(error_message)
	def addtestresult(self, testcase, test_result, description=''):
		style = 'fail'
		if test_result == TestResult.PASS:
			style = 'pass'
		self.testresults.append({
			'testcase': testcase,
			'result': test_result,
			'style': style,
			'description': description})
	def testresultsummary(self):
		def choose_test_result(tr, results=[]):
			if tr.get('result') in results:
				return True
		def choose_pass_test(tr): return choose_test_result(tr, [TestResult.PASS])
		def choose_fail_test(tr): return choose_test_result(tr, [TestResult.FAIL])
		def choose_error_test(tr):
			return choose_test_result(tr, [TestResult.UML_ERROR, TestResult.UML_WARNING, TestResult.TIMEOUT])
		total = len(self.testresults)
		passed = len(filter(choose_pass_test, self.testresults))
		fail = len(filter(choose_fail_test, self.testresults))
		error = len(filter(choose_error_test, self.testresults))
		myothercontext = Context(prec=4, rounding=ROUND_HALF_DOWN)
		setcontext(myothercontext)
		passrate = Decimal(passed)/Decimal(total)*100
		#print("total - {0}, pass - {1}, passrate - {2}%".format(total, passed, passrate))
		failrate = Decimal(100) - passrate
		self.testsummary = {
				'total': total,
				'pass': passed,
				'fail': fail,
				'error': error,
				'passrate': passrate,
				'failrate': failrate
			}
		return self.testsummary
	
	def dump(self, file):
		output = open(file, 'wb')
		pickle.dump(self, output)
		output.close()
	
	@staticmethod
	def load(file):
		pkl_file = open(file, 'rb')
		data = pickle.load(pkl_file)
		pkl_file.close()
		return data	
		
class ProjectTestSummary(object):
	def __init__(self, label, passrate=0.00, failrate=0.00, isblock=False, modtime=time.localtime()):
		self.label = label
		self.passrate = passrate
		self.failrate = failrate
		self.isblock = isblock
		self.modtime = modtime or time.localtime()
	
	def passrate(self, passrate): self.passrate = passrate
	def failrate(self, failrate): self.failrate = failrate
	def block(self, isblock): self.isblock = isblock
	def __str__(self):
		return "Project[label:{0},passrate:{1},failrate:{2},isblock:{3},modtime:'{4}']".format(
			self.label, self.passrate, self.failrate, self.isblock, time.strftime("%Y/%m/%dT%H:%M:%S", self.modtime))
	
	def tojson(self):
		if self.isblock: block = 'true'
		else: block = 'false'
		return "{{label:'{0}', passrate:{1}, failrate:{2}, isblock:{3}, modtime:'{4}'}}".format(
			self.label, self.passrate, self.failrate, block, time.strftime("%Y/%m/%dT%H:%M:%S", self.modtime))

	@staticmethod
	def loadall(file, latest=32):
		projects_test_summary = []
		fp = open(file, "r")
		for line in fp.readlines():
			if re.search(r'^\s+$', line): continue
			project = re.split(r'[\s+,;:]', line)
			#print(project)
			if re.search('BLOCK', line):
				pts = ProjectTestSummary(project[0], 0.00, 0.00,True, project[2])
			else:
				pts = ProjectTestSummary(project[0], project[1], project[2], project[3])
			projects_test_summary.append(pts)
		
		if latest and len(projects_test_summary) > latest:
			return projects_test_summary[-latest:]
		return projects_test_summary
	
	@staticmethod
	def loadallasjson(file, latest=32):
		projects = ProjectTestSummary.loadall(file, latest)
		json = '['+"\n"
		json += reduce((lambda x,y: x+",\n"+y), [prj.tojson() for prj in projects])
		json += "\n]"
		return json
	
	def isrecorded(self, file):
		projects = ProjectTestSummary.loadall(file)
		return filter((lambda x: x.label == self.label), projects)
		
	def record(self, file):
		if self.isrecorded(file): return
		fp = open(file, "a")
		if self.isblock:
			project = "{0} BLOCK {1}".format(self.label, self.modtime)
		else:
			project = "{0} {1} {2} {3}".format(self.label, self.passrate, self.failrate, self.modtime)
		fp.write(project)
		fp.write(os.linesep)
		fp.close()
		
