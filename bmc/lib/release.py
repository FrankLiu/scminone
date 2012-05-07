#!/usr/bin/env python

import sys
import os
import subprocess
import logging
import bmcapi as bmc

class Release:
	def __init__(self, name, label):
		self.name = name
		self.label = label
	
	def initialize(self):
		pass
	def branchOn(self, baseline):
		pass
	def mklbtype(self):
		pass
	def mklabel(self):
		pass
	def mkprj(self):
		pass
	def mkdevprj4label(self):
		pass
	def prepareNext(self):
		pass
	def cronjob(self):
		pass
	
class MainlineRelease(Release):
	pass
	
class PatchRelease(Release):
	pass
	
class FeatureRelease(Release):
	pass
	
