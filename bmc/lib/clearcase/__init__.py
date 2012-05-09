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
	logger.info("cleartool [%s] start..."%command)
	cleartool = bmc.config.get('cleartool')
	output = cmd.run("{ct} {command}".format(ct=cleartool, command=command), *args, **kwargs)
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
	output = cmd.run("{ct} setview -exec \"{command}\" {view}".format(ct=cleartool,command=command,view=view), *args, **kwargs)
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

def getNextVersion(view, product):
	logger.info("get build version for view {view}".format(view=view))
	output = ctInView(view, bmc.config.get("cmbpLabel")+" " + product, tail='-1')
	logger.debug(output)
	return output
def getNextLabel(view):
	return getNextVersion(view)
def getLastVersion(view):
	logger.info("get last build version for view {view}".format(view=view))
	output = ctInView(view, bmc.config.get("cmbpPrevLabel")+" " + product, tail='-1')
	logger.debug(output)
	return output
def getLastLabel(view):
	return getLastVersion(view)

	

	