#!/usr/bin/env python

class Component:
	"""
	Base class for all NCS modules
	"""
	def __init__(self, name, actions=[]):
		self._NAME = name
		self._ACTIONS = [actions]
		self._DEBUG = False
	
	def name(self, name):
		if name is not None:
			self._NAME = name
		else:
			return self._NAME
	
	def actions(self, actions=[]):
		if actions:
			self._ACTIONS = [actions]
		else:
			return self._ACTIONS
			
	def invoke_action(self, action, *params):
		pass
	
	def debug(self, FLAG=False):
		self._DEBUG = FLAG
	def debugon(self):
		self.debug(True)
	def debugoff(self):
		self.debug(False)
	def isdebugon(self):
		return self._DEBUG
	
	