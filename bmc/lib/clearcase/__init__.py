#!/usr/bin/env python

__doc__ = """
bmc.clearcase functions
"""

__all__ = ["Branch", "DevProject", "Metadata", "NamingPolicy", "View", "ViewCache", "Vob"]

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

def isObjectExist(metaType, objectSelector):
	"""
	Check whether the given metaType:objectSelector exists
	metaType should be view,vob,branch,label,lock....
	"""
	logger.debug("isObjectExist invoked")
	logger.info("Check whether {metaType}[{objectSelector}] exists?".format(metaType=metaType,objectSelector=objectSelector))
	if metaType in ('view','vob','lock'):
		output = cleartool("ls{metaType}".format(metaType=metaType), "-s", objectSelector)
	else:
		output = cleartool("lstype", "-s", "{metaType}:{objectSelector}".format(metaType=metaType,objectSelector=objectSelector))
	logger.debug(output)
	if re.search(r'^cleartool: Error', output) is not None:
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

def getViewPath(view):
	logger.info("get global path for view {view}".format(view=view))
	if not isViewExist(view):
		raise ViewNotExist(view)
	cleartool = bmc.config.get('cleartool')
	output = cmd.run("{ct} lsview -long {view}|grep 'Global path'|cut -d' ' -f5".format(ct=cleartool, view=view))
	logger.info("Global path: "+output)
	return output
	
def getNextVersion(view, product):
	logger.info("get next build version/label for view {view}".format(view=view))
	output = ctInView(view, bmc.config.get("cmbpLabel")+" " + product, tail='-1')
	logger.debug("Next version/label:" + output)
	return output
def getNextLabel(view, product):
	return getNextVersion(view, product)
def getLastVersion(view, product):
	logger.info("get last build version/label for view {view}".format(view=view))
	output = ctInView(view, bmc.config.get("cmbpPrevLabel")+" " + product, tail='-1')
	logger.info("Last version/label:" + output)
	return output
def getLastLabel(view, product):
	return getLastVersion(view, product)

def mkview(tagorbid, baseline, isDevBranch=True):
	logger.info("mkview start")
	logger.info("="*60)
	if isDevBranch:
		logger.info("make dev view with bid {bid} based on {baseline}".format(bid=tagorbid, baseline=baseline))
		output = cmd.run("{mkview} -bid {bid} -b {baseline}".format(mkview=bmc.config.get('mkview',bid=tagorbid,baseline=baseline))
	else:
		logger.info("make integration view with tag {tag} based on {baseline}".format(tag=tagorbid, baseline=baseline))
		output = cmd.run("{mkview} -tag {tag} -share_vw -b {baseline}".format(mkview=bmc.config.get('mkview',tag=tagorbid,baseline=baseline))
	logger.info("="*60)
	logger.info("mkview end")
	
def mklbtype(lbtype, vob, view):
	logger.info("create label type: {lbtype}".format(lbtype=lbtype))
	ctInView(view, "cd {vob}; {ct} mklbtype -nc {lbtype} 2>&1".format(ct=bmc.config.get('cleartool'), vob=vob,lbtype=lbtype))
def mklabel(lbtype, vob, view, logfile):
	logger.info("mklabel with lbtype: {lbtype}".format(lbtype=lbtype))
	ctInView(view, "cd {vob}; {ct} mklabel -nc -recurse {lbtype} . >{logfile} 2>&1".format(vob=vob,lbtype=lbtype,logfile=logfile))
def lockObject(objectSelector, vob, view, nusers):
	logger.info("lock object [{objectSelector}] in vob [{vob}], except for user [{nuser}]".format(vob=vob,objectSelector=objectSelector,nusers=nusers))
    output = ctInView(view, "cd {vob}; {ct} lock -nuser {nusers} {objectSelector}".format(ct=bmc.config.get('cleartool'), vob=vob,nusers=nusers,objectSelector=objectSelector))
    if re.search(r'^cleartool: Error', output) is not None and re.search(r'Object is already locked', output) is None:
		raise LockFailure(objectSelector)
    ctInView(view, "cd {vob}; {ct} lslock {objectSelector}".format(ct=bmc.config.get('cleartool'), vob=vob,objectSelector=objectSelector))
def grantOkToMerge(branch,tBranch, vobFamily):
	logger.info("grant ok_to_merge: branch [{branch}] to integration branch [{tBranch}]".format(branch=branch,tBranch=tBranch))
	output = cmd.run("{scMergeList} -add -f {b} -tbranch {tb} -v {vf}".format(scMergeList=bmc.config.get('scMergeList',b=branch,tb=tBranch,vf=vobFamily))
def subtractOkToMerge(branch,tBranch,vobFamily):
	logger.info("subtract ok_to_merge: branch [{branch}] from integration branch [{tBranch}]".format(branch=branch,tBranch=tBranch))
	output = cmd.run("{scMergeList} -sub -f {b} -tbranch {tb} -v {vf}".format(scMergeList=bmc.config.get('scMergeList',b=branch,tb=tBranch,vf=vobFamily))
def merge(branch,integrationView,vobFamily,mergeLog):
	logger.info("merge code from branch [{branch}] to integration branch [{ib}]".format(branch=branch,ib=integrationView))
	ctInView(integrationView, "{scBRMerge} -f {b} -nong -v {vf} > {ml} 2>&1".format(scBRMerge=bmc.config.get('scBRMerge'),b=branch,vf=vobFamily,ml=mergeLog))
	
	