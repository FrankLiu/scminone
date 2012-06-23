#!/usr/bin/env python

import os
import logging
from ncs.exceptions import *

class Compiler:
	def __init__(self, name):
		self.name = name
		self.logger = logging.getLogger(self.__class__.__name__)
		
	def compiletool(self, tool):
		self.compile_tool = tool
	def compilepath(self, path):
		self.compile_path = path
	def compileparams(self, params):
		self.compile_params = params
	def compilelog(self, logfile):
		self.compile_log = logfile
	def docompile(self):
		self.logger.info("{0} {1} {2} > {3}".format(self.compile_tool, self.compile_path, self.compile_params, self.compile_log))
		os.system("{0} {1} {2} > {3}".format(self.compile_tool, self.compile_path, self.compile_params, self.compile_log))
		
class IslCompiler(Compiler):
	def __init__(self):
		Compiler.__init__('ISL')
	
	def docompiler(self):
		pass
		
class ModelCompiler(Compiler):
	def __init__(self):
		Compiler.__init__('MODEL')
	
	def docompiler(self):
		pass
		
class TtcnCompiler(Compiler):
	def __init__(self):
		Compiler.__init__('TTCN')
	
	def docompiler(self):
		pass
