#!/usr/bin/env python

class VOB(object):
	"""
	Describe the VOB in the configuration
	"""
	def __init__(self, name, tag, merge=False, label=False, lockExp=''):
		self.name = name
		self.tag = tag
		self.merge = merge
		self.label = merge
		self.path = self.tag
		self.lockExp = lockExp
	def __str__(self):
		return "VOB{name:%s,tag:%s,merge:%s,label:%s}"%(self.name,self.tag,self.merge,self.label)
		
class BuildMode(object):
	"""
	Describe the build mode in the configuration
	"""
	def __init__(self, name, command):
		self.name = name
		self.command = command
	
	def __str__(self):
		return "BuildMode{name:%s}"%self.name
	
class Condition(object):
	"""
	Describe the condition for a step in the configuration
	"""
	def __init__(self, name, pattern, threshold='noUse'):
		self.name = name
		self.pattern = pattern
		self.threshold = threshold
	
	def __str__(self):
		return "Condition{name:%s,pattern:%s}"%(self.name, self.pattern)
		
class Step(object):
	'''
	Describe one step in the configuration
	'''
	def __init__(self, name, type, tool, targets=[]):
		self.name = name
		self.type = type
		self.tool = tool
		if len(targets) >= 1:
			self.targets = targets
		else:
			self.targets = [self.name]
		self.conditions = []
	def iscomposite(self):
		return self.type == "composite"
	def isatomic(self):
		return self.type == "atomic"
	def addCondition(self, cond):
		self.conditions.append(cond)
	def getConditions(self):
		return self.conditions
	def removeCondition(self, condname):
		for cond in self.conditions:
			if cond.name == condname:
				step.removeCondition(cond)
	def __str__(self):
		return "Step{name:%s,type:%s,tool:%s,targets:%s}"%(self.name, self.type, self.tool, self.targets)
		
class AtomicStep(Step):
	def __init__(self, name, tool, targets=[]):
		Step.__init__(self, name, "atomic", tool, targets)
		
class CompositeStep(Step):
	def __init__(self, name, tool, targets=[]):
		Step.__init__(self, name, "composite", tool, targets)
	def addTarget(self, target):
		self.targets.append(target)
	def getTargets(self):
		return self.targets
	def removeTarget(self, target):
		self.targets.remove(target)
		
class Instance(object):
	def __init__(self, name):
		self.name = name
		self.vobs = []
		self.steps = []
		self.compositeSteps = []
		self.buildModes = []
	def setattr(self, attrn, attrv):
		setattr(self, attrn, attrv)
	def getattr(self, attrn):
		getattr(self, attrn)
	
	##############################
	## Below are the common method for get useful information from instance
	def getName(self):
		return self.getattr('name')
	def getState(self):
		return self.getattr('state')
	def getNBView(self):
		return self.getattr('nBView')
	def getTargetRelMain(self):
		return self.getattr('targetRelMain')
	def getVobFamily(self,lower=True):
		if lower:
			return self.getattr('vobFamilyLower')
		else:
			return self.getattr('vobFamilyUpper')
	def getWuceProduct(self):
		return self.getattr('wuceProduct')
	def getBuildPool(self):
		return self.getattr('buildPool')
	def getBuilder(self):
		return self.getattr('builder')
	def getDailyDir(self):
		return self.getattr('dailyDir')
	
	
	#get build mode related information
	def getBuildModes(self):
		return self.buildModes
	def getBuildMode(self,name):
		for bm in self.getBuildModes():
			if bm.name == name:
				return bm
		return None
	
	#get vob related information	
	def getVobs(self):
		return self.vobs
	def getVob(self, name):
		vobs = self.getVobs()
		for vob in vobs:
			if vob.name == name:
				return vob
		return None
		
	#get step related information		
	def getSteps(self):
		return self.steps
	def getStep(self, name):
		steps = self.getSteps()
		for step in steps:
			if step.name == name:
				return step
		return None
	def getConditionsFromStep(self, name):
		step = self.getStep(name)
		if step:
			return step.getConditions()
		return []
	def getConditionFromStep(self, sname, cname):
		conds = self.getConditionsFromStep(sname)
		for cond in conds:
			if cond.name == cname:
				return cond
		return None
	
	#get atomic steps
	def getAtomicSteps(self):
		[step for step in self.getSteps() if step.isatomic()]
	#get composite steps
	def getCompositePhases(self):
		[step for step in self.getSteps() if step.iscomposite()]
	def getCompositeSteps(phasename):
		phases = self.getCompositePhases()
		for phase in phases:
			if phase.name == phasename:
				return phase.getTargets()
		return []
	
	##############################
	## Below are the common method for construct an instance
	#vob
	def addVob(self, vobn, vtag, merge=False, label=False, lockExp=''):
		self.vobs.append(VOB(vobn, vtag, merge, label, lockExp))
	def removeVob(self, vobn):
		for vob in self.vobs:
			if vob.name == vobn:
				self.vobs.remove(vob)
	#step			
	def addStep(self, name, type, tool, targets):
		self.steps.append(Step(name, type, tool, targets))
	def addAtomicStep(self, name, tool):
		self.steps.append(AtomicStep(name, tool))
	def addCompositeStep(self, name, tool, targets):
		self.steps.append(CompositeStep(name, tool, targets))
	def removeStep(self, name):
		for step in self.steps:
			if step.name == name:
				self.steps.remove(step)
	def addConditionToStep(self, stepname, name, pattern, threshold='noUse'):
		step = self.getStep(stepname)
		step.addCondition(Condition(name, pattern, threshold))
	def removeConditionFromStep(self, stepname, name):
		step = self.getStep(stepname)
		if step:
			step.removeCondition(name)
	#build mode
	def addBuildMode(self, name, command):
		if self.getBuildMode(name) == None:
			self.buildModes.append(BuildMode(name, command))
	def removeBuildMode(self, name):
		for bm in self.buildModes:
			if bm.name == name:
				self.buildModes.remove(bm)
