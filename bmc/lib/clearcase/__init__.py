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
		return repr(self.view)

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

def isViewExist(view):
	logger.info("check whether view[{view}] exists?".format(view=view))
	output = cleartool("lsview", "-s", view)
	logger.debug(output)
	if re.search(r'^cleartool: Error', output) is not None:
		logger.error("View [{view}] not exist".format(view=view))
		return False
	else:
		logger.info("View [{view}] exist".format(view=view))
		return True
		
def isVobExist(vob):
	logger.info("check whether vob[{vob}] exists?".format(vob=vob))
	output = cleartool("lsvob", "-s", vob)
	logger.debug(output)
	if re.search(r'^cleartool: Error', output) is not None:
		logger.error("Vob [{vob}] not exist".format(vob=vob))
		return False
	else:
		logger.info("Vob [{vob}] exist".format(vob=vob))
		return True

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

def mkview(tagorbid, baseline, isDev=True):
	if isDev:
		logger.info("make dev view with bid {bid} based on {baseline}".format(bid=tagorbid, baseline=baseline))
		output = cmd.run("{mkview} -bid {bid} -b {baseline}".format(mkview=bmc.config.get('cmbpBin')+"/mkview",bid=tagorbid,baseline=baseline))
	else:
		logger.info("make integration view with tag {tag} based on {baseline}".format(tag=tagorbid, baseline=baseline))
		output = cmd.run("{mkview} -tag {tag} -share_vw -b {baseline}".format(mkview=bmc.config.get('cmbpBin')+"/mkview",tag=tagorbid,baseline=baseline))
	
	
def mklbtype(lbtype, vob, view):
	logger.info("create label type: {lbtype}".format(lbtype=lbtype))
	ctInView(view, "cd {vob}; {ct} mklbtype -nc {lbtype} 2>&1".format(vob=vob,lbtype=lbtype))
def mklabel(lbtype, vob, view, logfile):
	logger.info("mklabel with lbtype: {lbtype}".format(lbtype=lbtype))
	ctInView(view, "cd {vob}; {ct} mklabel -nc -recurse {lbtype} . >{logfile} 2>&1".format(vob=vob,lbtype=lbtype,logfile=logfile))


	