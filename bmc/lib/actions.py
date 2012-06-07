#!/usr/bin/env python

import sys
import os
from subprocess import Popen,PIPE,STDOUT
import re
import logging
import bmcapi as bmc
import clearcase
import command

logger = logging.getLogger("bmc.task")

def cCheckView(viewTag):
	clearcase.isViewExist(viewTag)

#----------------------------------------------------------------------
#check label
def check_label(label):
	output = clearcase.ct("lstype lbtype:{label}@/vob/wibb_bts 2>&1".format(label=label))
	if not re.search(r'^cleartool: Error', output):
		subject = "Label {label} exists".format(label=label)
		message = subject
		utils.sendmail(bmc.config.get("MAILFROM"), mailto, subject, message)
		raise Exception(message)
		
#----------------------------------------------------------------------
#check branch
def check_branch(view, target=clearmake):
	smartbuilddir="/mot/proj/wibb_bts/daily/tmpsmartbuild/{view}".format(view=view)
	os.umask(0002)
	if not os.path.exists(smartbuilddir): os.makedirs(smartbuilddir, 0775)
	os.utime(smartbuilddir+"/prev_cs_"+target,None)
	os.utime(smartbuilddir+"/prev_cr_"+target,None)
	
	# Compare config spec. If identical, exit 0; else non-zero
	prevcs=smartbuilddir+"/prev_cs_"+target
	currcs=smartbuilddir+"/curr_cs_"+target
	clearcase.ct("catcs -tag {view} > {currcs}".format(view=view,currcs=currcs))
	csdiff = filecmp.cmp(prevcs,currcs)
	
	# Compare CR list. If identical, exit 0; else non-zero
	prevcr=smartbuilddir+"/prev_cr_"+target
	currcr=smartbuilddir+"/curr_cr_"+target
	command.run(". {scstart} wibb_bts".format(scstart=bmc.config.get("scstart")))
	clearcase.ctInView("{mergestat} -a|grep -E '.*yes.*yes.*|.*no.*yes.*' > {currcr}".format(mergestat=bmc.config.get("mergestat"),currcr=currcr))
	crdiff = filecmp.cmp(prevcr,currcr)

	# Update the log entry
	os.rename(currcs,prevcs)
	os.rename(currcr,prevcr)
	
	# If both config spec and merged CR log are unchanged, then exit 0; else, exit 1.
	if not (csfiff and crdiff):
		logger.warn("Nightly build under view {view} for {target} was not kicked off because there's no change to the code or config spec.".format(view=view, target=target))
		subject = "Nightly build under view {view} for {target} was not kicked off because there's no change to the code or config spec.".format(view=view, target=target)
		message = subject
		utils.sendmail(bmc.config.get("MAILFROM"), mailto, subject, message)
		raise Exception(message)

