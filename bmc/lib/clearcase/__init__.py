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

logger = logging.getLogger("bmc.clearcase")

class ViewNotExist(Exception):
	def __init__(self, view):
		self.view = view
	def __str__(self):
		return repr(self.view)

#execute cleartool sub-command not in a view
def cleartool(command, *args, **kwargs):
	logger.info("cleartool [%s] start..."%command)
	cleartool = bmc.config.get('cleartool')
	splitpattern = r'\s+'
	splitchar = ' '
	cmdarr = re.split(splitpattern, command)
	if len(cmdarr) > 1:
		cmd = cmdarr[0].strip()
		arguments = splitchar.join(cmdarr[1:]).strip() + splitchar + splitchar.join([arg for arg in args]).strip()
		arguments = arguments.strip()
	else:
		cmd = command.strip()
		arguments = splitchar.join([arg for arg in args]).strip()
	logger.info("{ct} {cmd} {args}".format(ct=cleartool, cmd=cmd, args=arguments))
	if len(kwargs) > 0:
		p1 = Popen([cleartool, cmd]+ re.split(splitpattern, arguments), stdout=PIPE, stderr=PIPE)
		lastPipe = p1
		items = kwargs.items()
		logger.debug("kwargs length: {length}".format(length=len(items)))
		for (i,(k,v)) in enumerate(items):
			logger.debug("{i}: {k}={v}".format(i=i,k=k,v=v))
			if i == len(items)-1:
				logger.debug("{i} == {len}-1, it is the latest one".format(i=i,len=len(items)))
				stderrPipe = STDOUT
			else:
				stderrPipe = PIPE
			p = Popen([k, v], stdin=lastPipe.stdout, stdout=PIPE, stderr=stderrPipe)
			lastPipe = p
		output = lastPipe.communicate()[0]
	else:
		output = Popen([cleartool, cmd]+ re.split(splitpattern, arguments), stdout=PIPE, stderr=STDOUT).communicate()[0]
	logger.debug(output.strip())
	logger.info("cleartool [%s] end."%command)
	return output

def ct(command, *args, **kwargs):
	return cleartool(command, *args, **kwargs)

#execute command in a view
def cleartoolInView(view, command, *args, **kwargs):
	logger.info("cleartool setview -exe \"{command}\" {view} start...".format(view=view,command=command))
	if not isViewExist(view):
		raise ViewNotExist(view)
	cleartool = bmc.config.get('cleartool')
	splitpattern = r'\s+'
	splitchar = ' '
	cmdarr = re.split(splitpattern, command)
	if len(cmdarr) > 1:
		cmd = cmdarr[0].strip()
		arguments = splitchar.join(cmdarr[1:]).strip() + splitchar + splitchar.join([arg for arg in args]).strip()
		arguments = arguments.strip()
	else:
		cmd = command.strip()
		arguments = splitchar.join([arg for arg in args]).strip()
	logger.info("{ct} setview -exe '{cmd} {args}' {view}".format(ct=cleartool, cmd=cmd, args=arguments, view=view))
	output = Popen([cleartool, 'setview', '-exe', "{cmd} {args}".format(cmd=cmd,args=arguments), view], stdout=PIPE, stderr=STDOUT).communicate()[0]
	logger.debug(output.strip())
	logger.info("cleartool setview -exe \"{command}\" {view} end.".format(view=view,command=command))
	return output
	
def ctInView(view, command, *args, **kwargs):
	return cleartoolInView(view, command, *args, **kwargs)

def isViewExist(view):
	logger.info("cleartool lsview {view} 2>&1".format(view=view))
	output = cleartool("lsview", "-s", view)
	logger.debug(output)
	if re.search(r'^cleartool: Error', output) is not None:
		logger.error("View [%s] not exist"%view)
		return False
	else:
		logger.info("View [%s] exist"%view)
		return True

def getBuildVersion(view):
	logger.info("get build version for view {view}".format(view=view))
	output = ctInView(view, bmc.config.get("cmbpLabel"), "apsac", tail='-1')
	logger.debug(output)
	return output
def getLabel(view):
	return getBuildVersion(view)
def getNextBuildVersion(view):
	pass
def getNextLabel(view):
	return getNextBuildVersion(view)

	

	