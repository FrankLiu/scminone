#!/usr/bin/env python

from ncs.exceptions import *

class Runner:
	def __init__(self):
		pass
		
	def runcommand(self, command):
		self.command = command
	def runparams(self, params):
		self.params = params
	def logfile(self, log):
		self.log = log
	
	def start(self):
		pass
	
	