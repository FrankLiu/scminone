#!/usr/bin/env python

import sys
import os
import logging
import xml.dom.minidom
import model
from utils import storage

__all__ = [
  "config",  
  "XmlLoader", "JsonLoader"
]

config = storage()

def hasAttr(node, attr):
	return node.hasAttribute(attr)
def getAttr(node, attr):
	if node.hasAttribute(attr):
		return node.getAttribute(attr)
	return ""
def setAttr(node, attr, attrval):
	node.setAttribute(attr, attrval)
	
def getText(node):
	if node.nodeType == node.TEXT_NODE:
		return node.data
	return ""

def getNodelist(node, tagname):
	return node.getElementsByTagName(tagname)

def getNode(node, tagname, uniattr, uniattrval):
	nodes = getNodeList(node, tagname)
	for n in nodes:
		if getAttr(n, uniattr) == uniattrval:
			return n
	return {}

class Loader(object):
	"""Configuration Load for BMC"""
	def getInstance(self): pass
	
class XmlLoader(Loader):
	"""
	XML Configuration for BMC
	"""
	def __init__(self, insname):
		self.instancename = os.environ['BMC_HOME']+"/conf/%s.ins"%insname
		self.logger = logging.getLogger("bmc")
		if not os.path.exists(self.instancename):
			self.logger.fatal("Invalid instance [%s], please contact your SCM admin for help."%insname)
			sys.exit(1)
		self.ins = model.Instance(self.instancename)
		self.__load(self.instancename)
	
	def __load(self, inspath):
		self.logger.info("Load instance configuration...")
		self.idom = xml.dom.minidom.parse(inspath).documentElement
		#all steps defined in the instance file
		if not hasAttr(self.idom, "template"): 
			steps = getNodelist(self.idom, "step")
			if len(steps) <= 1:
				self.logger.fatal("Invalid instance [%s], step not defined."%insname)
				sys.exit(1)
		
		#load steps from template file
		template = os.environ['BMC_HOME']+"/conf/%s" % getAttr(self.idom, "template")
		if not os.path.exists(template):
			self.logger.fatal("Template [%s] not exists for instance [%s]."%(template, insname))
			sys.exit(1)
			
		#parse template file
		self.tdom = xml.dom.minidom.parse(template).documentElement
		
		#instance variables
		self.ins.setattr('name', getAttr(self.idom, "name") or getAttr(self.tdom, "name"))
		self.ins.setattr('state', getAttr(self.idom, "state") or getAttr(self.tdom, "state"))
		self.ins.setattr('nBView', getAttr(self.idom, "nBView") or getAttr(self.tdom, "nBView"))
		self.ins.setattr('targetRelMain', getAttr(self.idom, "targetRelMain") or getAttr(self.tdom, "targetRelMain"))
		self.ins.setattr('vobFamilyLower', getAttr(self.idom, "vobFamilyLower") or getAttr(self.tdom, "vobFamilyLower"))
		self.ins.setattr('vobFamilyUpper', self.ins.vobFamilyLower.upper())
		self.ins.setattr('wuceProduct', getAttr(self.idom, "wuceProduct") or getAttr(self.tdom, "wuceProduct"))
		self.ins.setattr('buildPool', getAttr(self.idom, "buildPool") or getAttr(self.tdom, "buildPool"))
		self.ins.setattr('builder', getAttr(self.idom, "builder") or getAttr(self.tdom, "builder"))
		self.ins.setattr('dailyDir', getAttr(self.idom, "dailyDir") or getAttr(self.tdom, "dailyDir"))
		#build mode
		buildModes = getNodelist(self.idom, "buildMode")
		for bm in buildModes:
			self.ins.addBuildMode(getAttr(bm, "bn"), getAttr(bm, "bv"))
		#vob
		vobs = getNodelist(self.idom, "vob")
		for v in vobs:
			self.ins.addVob(getAttr(v, "vn"), getAttr(v, "vTag"), getAttr(v, "vMerge"), getAttr(v, "vLabel"), getAttr(v, "vLockExp"))
		#steps
		steps = set(getNodelist(self.idom, "step")).union(getNodelist(self.tdom, "step"))
		for s in steps:
			sn = getAttr(s, "sn")
			self.logger.info("step [%s]"%sn)
			if getAttr(s, "sType") == "atomic":
				self.ins.addAtomicStep(sn, getAttr(s, "sTool"))
				self.logger.debug("step [%s]"%self.ins.getStep(sn))
			elif getAttr(s, "sType") == "composite":
				self.ins.addCompositeStep(sn, getAttr(s, "sTool"), getAttr(s, "sTarget").split(' '))
				self.logger.debug("step [%s]"%self.ins.getStep(sn))
			else:
				self.logger.warn("Step [%s] is invalid, ignore it!"%sn)
				continue
			#pre-action for the step
			preActions = getNodelist(s, "pre-action")
			for c in preActions:
				cn = getAttr(c,"cn")
				self.logger.info("\tpre-action [%s]"%cn)
				self.ins.addPreActionToStep(sn, cn, tuple(getAttr(c, "args")), dict(getAttr(c, "kwargs")))
				self.logger.debug("\tpre-action [%s]"%self.ins.getPreActionFromStep(sn,cn))
			#post-action for the step
			postActions = getNodelist(s, "post-action")
			for c in postActions:
				cn = getAttr(c,"cn")
				self.logger.info("\tpost-action [%s]"%cn)
				self.ins.addPostActionToStep(sn, cn, tuple(getAttr(c, "args")), dict(getAttr(c, "kwargs")))
				self.logger.debug("\tpost-action [%s]"%self.ins.getPostActionFromStep(sn,cn))
		#composite steps
		phases = set(getNodelist(self.tdom, "phase")).union(getNodelist(self.idom, "phase"))
		for p in phases:
			sn = getAttr(p, "sn")
			self.logger.info("phase [%s]"%sn)
			if getAttr(p, "sType") == "atomic":
				self.logger.warn("step [%s]"%self.ins.getStep(sn))("Step [%s] is invalid, the type should be 'composite', ignore it!"%sn)
				continue
			elif getAttr(p, "sType") == "composite":
				self.logger.info("\tTargets [%s]"%getAttr(p, "sTarget"))
				self.ins.addCompositeStep(sn, getAttr(p, "sTool"),  getAttr(p, "sTarget").split(' '))
				self.logger.debug("Phase [%s]"%self.ins.getStep(sn))
			else:
				self.logger.warn("Step [%s] is invalid, ignore it!"%sn)
				continue
		return self.ins
		
	def getInstance(self):
		return self.ins

class JsonLoader(Loader):
	'''
	JSON Configuration for BMC
	'''
	pass
	