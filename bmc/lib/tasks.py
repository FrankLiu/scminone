#!/usr/bin/env python

import sys
import os
from subprocess import Popen,PIPE,STDOUT
import re
import logging
import bmcapi as bmc
import clearcase

logger = logging.getLogger("bmc.task")

def cCheckView(viewTag):
	clearcase.isViewExist(viewTag)

def cCheckViewDS(viewTag, limit):
	logger.info("{myquota} {view} | grep {limit}".format(myquota=bmc.config.get('myquota'),view=viewTag,limit=limit))
	p1 = Popen([bmc.config.get('myquota'), viewTag], stdout=PIPE, stderr=PIPE)
	p2 = Popen(['grep', limit], stdin=p1.stdout, stdout=PIPE, stderr=STDOUT)
	output = p2.communicat()[0]
	logger.debug(output)
	

def cCheckDDirDS(dailyDir, limit):
	pass
def cCheckLogDir(logDir, limit):
	pass

#check if the branch is locked
def isBranchLocked(brtype):
	pass

#get next build version
def getNextBuildVersion(ins):
	nbView = ins.getNBView()
	
#update nightly build version
def updateNBVer(ins):
	nbView = ins.getNBView()

#check whether the label exists or not
def cCheckLabel(label):
	pass
#check whether the given branches/config-spec is changed in nightly build view
def cCheckBranches(instance):
	passs
	
	
"""
Create a branch based on the given baseline.
This can be used for feature branch creation, mainline branch creation and patch branch creation.
"""
def branchOf(branch, baseline, share_vw=True):
	print("Create branch %s from baseline %s"%(branch,baseline))
	print(cfg['cmbpBin']+"/mkview")
	
def mkLbtype(lbtype):
	pass
def descLbtype(lbtype):
	pass
def mkLabel(lbtype, path, recursively = True):
	pass
def mkPrj(prj):
	pass
def mkPrjAttrForLabel(label):
	pass
def nextBuildVersion(nBView):
	pass
def nextBaselineVersion(nBView):
	pass
def setConfigSpec(nBView):
	pass
		
