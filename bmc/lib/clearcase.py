#!/usr/bin/env python

__doc__ = """
bmc.clearcase functions
"""

import os
import sys
import re
import logging
from subprocess import Popen, PIPE, STDOUT
import bmcapi as bmc
import command as cmd

logger = logging.getLogger("bmc.clearcase")

class ViewNotExist(Exception):
	def __init__(self, view):
		self.view = view
	def __str__(self):
		return "View [{view}] not exist!!!".format(view=self.view)
class InvalidView(Exception):
	def __init__(self, view):
		self.view = view
	def __str__(self):
		return "View [{view}] is invalid!!!".format(view=self.view)
class LockFailure(Exception):
	def __init__(self, obj):
		self.obj = obj
	def __str__(self):
		return "Cannot lock object [{obj}]".format(obj=self.obj)

#execute cleartool sub-command not in a view
def cleartool(command, *args, **kwargs):
	logger.info("run cleartool command {command}".format(command=command))
	logger.debug("cleartool [{command}] start...".format(command=command))
	cleartool = bmc.config.get('cleartool')
	output = cmd.run("{ct} {command}".format(ct=cleartool, command=command), *args, **kwargs)
	logger.debug("cleartool [{command}] end.".format(command=command))
	return output

def ct(command, *args, **kwargs):
	return cleartool(command, *args, **kwargs)

#execute command in a view
def cleartoolInView(view, command, *args, **kwargs):
	logger.debug("cleartool setview -exe \"{command}\" {view} start...".format(view=view,command=command))
	if not isViewExist(view):
		raise ViewNotExist(view)
	cleartool = bmc.config.get('cleartool')
	output = cmd.run("{ct} setview -exec \"{command}\" {view}".format(ct=cleartool,command=command,view=view), *args, **kwargs)
	logger.debug("cleartool setview -exe \"{command}\" {view} end.".format(view=view,command=command))
	return output
	
def ctInView(view, command, *args, **kwargs):
	return cleartoolInView(view, command, *args, **kwargs)

def lsObject(metaType, objectSelector, *args, **kwargs):
	"""
	show metaType:objectSelector information
	metaType should be view,vob,branch,label,lock....
	"""
	logger.debug("lsObject {metaType}[{objectSelector}] invoked".format(metaType=metaType,objectSelector=objectSelector))
	if metaType in ('view','vob','lock'):
		output = cleartool("ls{metaType}".format(metaType=metaType), (' '.join(args)+' ' + objectSelector), **kwargs)
	else:
		output = cleartool("lstype", (' '.join(args)+' ' + "{metaType}:{objectSelector}".format(metaType=metaType,objectSelector=objectSelector)), **kwargs)
	logger.debug("lsObject {metaType}[{objectSelector}] output:{output}".format(metaType=metaType,objectSelector=objectSelector,output=output))
	return output
	
def isObjectExist(metaType, objectSelector):
	"""
	Check whether the given metaType:objectSelector exists
	metaType should be view,vob,branch,label,lock....
	"""
	logger.debug("isObjectExist invoked")
	logger.info("Check whether {metaType}[{objectSelector}] exists?".format(metaType=metaType,objectSelector=objectSelector))
	output = lsObject(metaType, objectSelector, '-s')
	objExceptVob = objectSelector.split('@')[0]
	if objExceptVob.find(':') > 0:
		objExceptVob = objExceptVob.split(':')[1]
	if re.search(r'^cleartool: Error', output) is not None or re.search(objExceptVob, output) is None:
		logger.error("{metaType} [{objectSelector}] not exist!".format(metaType=metaType,objectSelector=objectSelector))
		return False
	else:
		logger.info("{metaType} [{objectSelector}] exists!".format(metaType=metaType,objectSelector=objectSelector))
		return True
		
def isViewExist(view):
	return isObjectExist("view", view)
def isVobExist(vob):
	return isObjectExist("vob", vob)
def isLockExist(lock):
	return isObjectExist("lock", lock)
def isBranchExist(branch, invob):
	return isObjectExist("brtype", "{branch}@{vob}".format(branch=branch,vob=invob))
def isLabelExist(label, invob):
	return isObjectExist("lbtype", "{label}@{vob}".format(label=label,vob=invob))
def isAttributeExist(attr, invob):
	return isObjectExist("attype", "{attr}@{vob}".format(attr=attr,vob=invob))
def isHyperLinkExist(hyperLink, invob):
	return isObjectExist("hltype", "{hyperLink}@{vob}".format(hyperLink=hyperLink,vob=invob))
def isTriggerExist(trigger, invob):
	return isObjectExist("trtype", "{trigger}@{vob}".format(trigger=trigger,vob=invob))

#defatul pattern is WMX-AP_R5.0_REL-45.00.00[.EXTRATEST]
def parseLabel(label, pattern=r'^(\w+)-(\w+)_R(\d\.\d\.?\d?)_(\w+)-(\d+)\.(\d+)\.(\d+)\.?(\w+)?$'):
	logger.info("parse label for the given {label}".format(label=label))
	m = re.search(pattern, label) 
	if m is not None:
		logger.info("matched string: {m}".format(m=m.group(0)))
		sys = m.group(1)
		prod = m.group(2)
		sysrel = m.group(3)
		bld = m.group(4)
		iter = m.group(5)
		prodver = m.group(6)
		bldrev = m.group(7)
		extra = m.group(8) or None
		logger.debug("matched objects: {sys} {prod} {sysrel} {bld} {iter} {prodver} {bldrev} {extra}".format(sys=sys, prod=prod, sysrel=sysrel, bld=bld, iter=iter, prodver=prodver, bldrev=bldrev, extra=extra))
		return (sys,prod,sysrel,bld,iter,prodver,bldrev,extra)
	logger.warn("Invalid label {label}".format(label=label))
	return tuple()
	
def getViewPath(view):
	logger.info("get global path for view {view}".format(view=view))
	if not isViewExist(view):
		raise ViewNotExist(view)
	cleartool = bmc.config.get('cleartool')
	output = cmd.run("{ct} lsview -long {view}|grep 'Global path'|cut -d' ' -f5".format(ct=cleartool, view=view))
	logger.info("Global path: "+output)
	return output
def getViewConfigSpec(view):
	logger.info("get config spec for view {view}".format(view=view))
	return getViewPath(view) + "/config_spec"

###########################################################################################################
### below are the version related functions
def getNextVersion(view, product):
	logger.info("get next build version/label for view {view}".format(view=view))
	output = ctInView(view, bmc.config.get("cmbpLabel")+" " + product, tail='-1')
	logger.debug("Next version/label:" + output)
	return output
def getNextLabel(view, product):
	return getNextVersion(view, product)
def getVersion(view, product):
	logger.info("get build version/label for view {view}".format(view=view))
	output = ctInView(view, bmc.config.get("cmbpPrevLabel")+" " + product, tail='-1')
	logger.info("version/label:" + output)
	return output
def getLabel(view, product):
	return getLastVersion(view, product)
def getPreviousBaselineLabel(view, product):
	currBlLabel = getBaselineLabel(view, product)
	l = parseLabel(currBlLabel)
	if float(l[2]) >= 5.0: #mainline release greater than 5.0
		iter = str(int(l[4])-1).zfill(2)
		output = "{sys}-{prod}_R{sysrel}_{bld}-{iter}.00.00".format(sys=l[0],prod=l[1],sysrel=l[2],bld=l[3],iter=iter)
	else:
		prodver = str(int(l[5])-1).zfill(2)
		output = "{sys}-{prod}_R{sysrel}_{bld}-{iter}.{prodver}.00".format(sys=l[0],prod=l[1],sysrel=l[2],bld=l[3],iter=l[4],prodver=prodver)
	logger.info("previous baseline label is {label}".format(label=output))
	return output
def getPreviousScmBaselineLabel(view, product):
	return getPreviousBaselineLabel(view,product).replace('BLD','REL')
def getBaselineLabel(view,product):
	logger.info("get last baseline label for view {view}".format(view=view))
	nl = getLabel(view, product)
	l = parseLabel(nl)
	if len(l)>= 8 and l[7] is not None: #has extra flag, just return the original label
		output = "{sys}-{prod}_R{sysrel}_{bld}-{iter}.{prodver}.{bldrev}.{extra}".format(sys=l[0],prod=l[1],sysrel=l[2],bld=l[3],iter=l[4],prodver=l[5],bldrev=l[6],extra=l[7])
	else:
		if float(l[2]) >= 5.0: #mainline release greater than 5.0
			iter = str(int(l[4])+1).zfill(2)
			output = "{sys}-{prod}_R{sysrel}_{bld}-{iter}.00.00".format(sys=l[0],prod=l[1],sysrel=l[2],bld=l[3],iter=iter)
		else:
			prodver = str(int(l[5])+1).zfill(2)
			output = "{sys}-{prod}_R{sysrel}_{bld}-{iter}.{prodver}.00".format(sys=l[0],prod=l[1],sysrel=l[2],bld=l[3],iter=l[4],prodver=prodver)
	logger.info("baseline label is {label}".format(label=output))
	return output
def getScmBaselineLabel(view,product):
	return getBaselineLabel(view,product).replace('BLD','REL')
def getNextBaselineLabel(view, product):
	logger.info("get next baseline label for view {view}".format(view=view))
	nl = getNextLabel(view, product)
	l = parseLabel(nl)
	if len(l)>= 7 and l[7] is not None: #has extra flag, just return the original label
		output = "{sys}-{prod}_R{sysrel}_{bld}-{iter}.{prodver}.{bldrev}.{extra}".format(sys=l[0],prod=l[1],sysrel=l[2],bld=l[3],iter=l[4],prodver=l[5],bldrev=l[6],extra=l[7])
	else:
		if float(l[2]) >= 5.0: #mainline release greater than 5.0
			iter = str(int(l[4])+1).zfill(2)
			output = "{sys}-{prod}_R{sysrel}_{bld}-{iter}.00.00".format(sys=l[0],prod=l[1],sysrel=l[2],bld=l[3],iter=iter)
		else:
			prodver = str(int(l[5])+1).zfill(2)
			output = "{sys}-{prod}_R{sysrel}_{bld}-{iter}.{prodver}.00".format(sys=l[0],prod=l[1],sysrel=l[2],bld=l[3],iter=l[4],prodver=prodver)
	logger.info("next baseline label is {label}".format(label=output))
	return output
def getNextScmBaselineLabel(view, product):
	return getNextBaselineLabel(view,product).replace('BLD','REL')
	
def getIntegrationBranch(view, product):
	logger.info("get integration branch for view {view}".format(view=view))
	ib = ""
	#firstly, check the view config spec, get the integration branch from config spec rule '^mkbranch <integration_branch>'
	viewCS = getViewConfigSpec(view)
	if not os.path.exists(viewCS):
		raise InvalidView(view)
	with open(viewCS) as f:
		for line in f.readlines():
			if line.find("mkbranch") >= 0:
				ib = line[8:].strip()
				logger.debug("found: mkbranch {branch}".format(branch=ib))
				break
	#cannot get integration branch from config spec??? why??? then get it from baseline label
	if ib.isspace():
		nbl = getNextBaselineLabel(view, product)
		ib = nbl.replace('REL','BLD').lower()
	logger.info("integration branch is {branch}".format(branch=ib))
	return ib
def getNextIntegrationBranch(view, product):
	logger.info("get next integration branch for view {view}".format(view=view))
	ib = getIntegrationBranch(view,product)
	l = parseLabel(ib)
	if float(l[2]) >= 5.0: #mainline release greater than 5.0
		iter = str(int(l[4])+1).zfill(2)
		output = "{sys}-{prod}_r{sysrel}_{bld}-{iter}.00.00".format(sys=l[0],prod=l[1],sysrel=l[2],bld=l[3],iter=iter)
	else:
		prodver = str(int(l[5])+1).zfill(2)
		output = "{sys}-{prod}_r{sysrel}_{bld}-{iter}.{prodver}.00".format(sys=l[0],prod=l[1],sysrel=l[2],bld=l[3],iter=l[4],prodver=prodver)
	logger.info("next integration branch is {branch}".format(branch=output))
	return output

###############################################################################################
## below are cleartool mkxxx functions	
def mklbtype(lbtype, vob, view):
	logger.info("create label type: {lbtype}".format(lbtype=lbtype))
	ctInView(view, "cd {vob}; {ct} mklbtype -nc {lbtype} 2>&1".format(ct=bmc.config.get('cleartool'), vob=vob,lbtype=lbtype))
def mkattr(metaType, metaValue, objectSelector, vob, view):
	logger.info("create attribute: {mt} {mv}".format(mt=metaType,mv=metaValue))
	ctInView(view, "cd {vob}; {ct} mkattr -replace -nc {mt} \"{mv}\" {objsel}@{vob}".format(ct=bmc.config.get('cleartool'), vob=vob,mt=metaType,mv=metaValue,objsel=objectSelector))
def mklabel(lbtype, vob, view, logfile):
	logger.info("mklabel with lbtype: {lbtype}".format(lbtype=lbtype))
	ctInView(view, "cd {vob}; {ct} mklabel -nc -recurse {lbtype} . >{logfile} 2>&1".format(vob=vob,lbtype=lbtype,logfile=logfile))
def lockObject(objectSelector, vob, view, nusers):
	logger.info("lock object [{objectSelector}] in vob [{vob}], except for user [{nusers}]".format(vob=vob,objectSelector=objectSelector,nusers=nusers))
	output = ctInView(view, "cd {vob}; {ct} lock -nuser {nusers} {objectSelector}".format(ct=bmc.config.get('cleartool'), vob=vob,nusers=nusers,objectSelector=objectSelector))
	if re.search(r'^cleartool: Error', output) is not None:
		if re.search(r'Object is already locked', output) is not None:
			logger.warn("Object is already locked!")
		raise LockFailure(objectSelector)
	ctInView(view, "cd {vob}; {ct} lslock {objectSelector}".format(ct=bmc.config.get('cleartool'), vob=vob,objectSelector=objectSelector))
def lockBranch(branch, vob, view, nusers):
	lockObject("brtype:{branch}".format(branch=branch), vob, view, nusers)
def isBranchLocked(branch, vob):
	return isLockExist("brtype:{branch}@{vob}".format(branch=branch,vob=vob))
	
############################################################################################
###Below commands based on cmbp, should we move it out?
def mkview(tagorbid, baseline, isDevBranch=False):
	logger.info("mkview start")
	logger.info("="*60)
	if isDevBranch:
		logger.info("make dev view with bid {bid} based on {baseline}".format(bid=tagorbid, baseline=baseline))
		output = cmd.run("{mkview} -bid {bid} -b {baseline}".format(mkview=bmc.config.get('mkview',bid=tagorbid,baseline=baseline)))
	else:
		logger.info("make integration view with tag {tag} based on {baseline}".format(tag=tagorbid, baseline=baseline))
		output = cmd.run("{mkview} -tag {tag} -share_vw -b {baseline}".format(mkview=bmc.config.get('mkview',tag=tagorbid,baseline=baseline)))
	logger.info("="*60)
	logger.info("mkview end")
	
def grantOkToMerge(branch,tBranch, vobFamily):
	logger.info("grant ok_to_merge: branch [{branch}] to integration branch [{tBranch}]".format(branch=branch,tBranch=tBranch))
	output = cmd.run("{scMergeList} -add -f {b} -tbranch {tb} -v {vf}".format(scMergeList=bmc.config.get('scMergeList',b=branch,tb=tBranch,vf=vobFamily)))
def subtractOkToMerge(branch,tBranch,vobFamily):
	logger.info("subtract ok_to_merge: branch [{branch}] from integration branch [{tBranch}]".format(branch=branch,tBranch=tBranch))
	output = cmd.run("{scMergeList} -sub -f {b} -tbranch {tb} -v {vf}".format(scMergeList=bmc.config.get('scMergeList',b=branch,tb=tBranch,vf=vobFamily)))
	
def merge(branch,integrationView,vobFamily,mergeLog):
	logger.info("merge code from branch [{branch}] to integration branch [{ib}]".format(branch=branch,ib=integrationView))
	ctInView(integrationView, "{scBRMerge} -f {b} -nong -v {vf} > {ml} 2>&1".format(scBRMerge=bmc.config.get('scBRMerge'),b=branch,vf=vobFamily,ml=mergeLog))
	
def mergestat(integrationView):
	logger.info("mergestate in integration branch [{ib}]".format(ib=integrationView))
	return ctInView(integrationView, "{mergestat} -a".format(mergestat=bmc.config.get('mergestat')))
	
