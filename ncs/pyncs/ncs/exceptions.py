#!/usr/bin/env python
"""
NCS exceptions.
"""

class NcsError(Exception):
	def __init__(self, message):
		self.message = message
	
	def __str__(self):
		return repr(self.message)

class NotImplementedError(NcsError):
	def __init__(self):
		pass
		
	def __str__(self):
		return repr("Not implemented!") 

class TemplateNotExist(NcsError):
	def __init__(self, template_file):
		self.template_file = template_file
	
	def __str__(self):
		return repr("template file {0} not exist!".format(self.template_file)) 

class SrMappingNotExist(NcsError):
	def __init__(self, mapping_file):
		self.mapping_file = mapping_file
	
	def __str__(self):
		return repr("SR mapping file {0} not exist!".format(self.mapping_file)) 
		
class WorkSheetNotExist(NcsError):
	def __init__(self, mapping_file, sheet_name):
		self.mapping_file = mapping_file
		self.sheet_name = sheet_name
		
	def __str__(self):
		return repr("Work sheet {1} not found in SR mapping file {0}!".format(self.mapping_file, self.sheet_name)) 
		
class ProjectIsTestedBefore(NcsError):
	def __init__(self, label):
		self.label = label
	
	def __str__(self):
		return repr("Project {0} is tested before!".format(self.label)) 
		
class ProjectSameAsPreviousOne(NcsError):
	def __init__(self, label, previous_label=''):
		self.label = label
		self.previous_label = previous_label
	
	def __str__(self):
		return repr("Project {0} same as previous one {1}!".format(self.label, self.previous_label))

		