#!/usr/bin/env python

import sys
import os
from subprocess import Popen,PIPE,STDOUT
import re
import io
import logging
import bmcapi as bmc
import clearcase

logger = logging.getLogger("bmc.step")

#mainline integration branch process
def sUpdateNBVer(ins):
	currVer = clearcase.getNextLabel(ins.getNBView(),ins.getWuceProduct())
	nextBlVer = clearcase.getNextBaselineLabel(ins.getNBView(),ins.getWuceProduct())
	l = clearcase.parseLabel(nextBlVer)
	if len(l) < 8:
		raise Exception("Invalid baseline label {label}".format(label=nextBlVer))
	clearcase.ctInView(ins.getNBView(), "cd {vt}/bld/wuce/ver; {ct} co -nc sys prod sysrel bld iter prodver bldrev extra".format(vt=ins.getVobTag(),ct=bmc.config.get('cleartool')))
	clearcase.ctInView(ins.getNBView(), "cd {vt}/bld/wuce/ver; echo {sys}>sys; echo {prod}>prod; echo {sysrel}>sysrel; echo {bld}>bld; echo {iter}>iter; echo {prodver}>prodver; echo {bldrev}>bldrev; echo {extra}>extra;".format(vt=ins.getVobTag(), 
			sys=l[0],prod=l[1],sysrel=l[2],bld=l[3],iter=l[4],prodver=l[5],bldrev=l[6],extra=l[7]))
	clearcase.ctInView(ins.getNBView(), "cd {vt}/bld/wuce/ver; {ct} ci -nc -iden sys prod sysrel bld iter prodver bldrev extra".format(vt=ins.getVobTag(),ct=bmc.config.get('cleartool')))	
	
def sCheckNBVer(ins):
	nextLabel = clearcase.getNextLabel(ins.getNBView(),ins.getWuceProduct())
	logger.info("next label is {label}".format(label=nextLabel))
	if clearcase.isLabelExist(nextLabel):
		raise Exception("label {nextLabel} exists, maybe previous build is not complished".format(nextLabel=nextLabel))
def sLockTargetIntBr(ins):
	vob = ins.getVobTag()
	view = ins.getNBView()
	nusers = ins.getVob(ins.getVobName()).lockExp
	clearcase.lockBranch(clearcase.getIntegrationBranch(view, ins.getWuceProduct()))
def sBuild(ins):
	tool = ins.getStep("sBuild").tool
	buildlog = "{tooln}.log".format(tooln=tool.split('/')[-1])
	logger.info("Kick off build in view {view}".format(view=ins.getNBView()))
	cleartcase.ctInView(ins.getNBView(), "{tool} >> {log} 2>&1".format(tool=tool,log=buildlog))
	
def sGenCrStat(ins):
	return clearcase.mergestat(ins.getNBView())
def sCreateBldLb(ins):
	bl = clearcase.getBaselineLabel(ins.getNBView(), ins.getWuceProduct())
	clearcase.mklbtype(bl, ins.getVobTag(), ins.getNBView())
	logger.info("created label type {lb}".format(lb=bl))
def sLabelTargetIntBr(ins):
	bl = clearcase.getBaselineLabel(ins.getNBView(), ins.getWuceProduct())
	lblog = ins.getDailyDir() + "/{bl}/{bl}.mklabel".format(bl=bl)
	clearcase.mklabel(bl, ins.getVobTag(), ins.getNBView(), lblog)
def sMkPrjDevPrjInt(ins):
	bl = clearcase.getBaselineLabel(ins.getNBView(), ins.getWuceProduct())
	nextBl = clearcase.getNextBaselineLabel(ins.getNBView(), ins.getWuceProduct())
	prj = cmbpConfigDir + "/{vobname}_projects/{lb}.prj".format(vobname=ins.getVobFamily(False),lb=bl)
	nextPrj = cmbpConfigDir + "/{vobname}_projects/{lb}.prj".format(vobname=ins.getVobFamily(False),lb=nextBl)
	prjlist = []
	with open(prj, 'r') as f:
		prjlist = f.readlines()
	[prj.replace(bl, nextBl) for prj in prjlist]
	with open(nextPrj, 'w') as f:
		f.writelines(prjlist)
		
#patch integration branch process
def sCreateTargetIntBr(ins):
	bl = clearcase.getBaselineLabel(ins.getNBView(), ins.getWuceProduct())
	nextIntBr = clearcase.getNextIntegrationBranch(ins.getNBView(), ins.getWuceProduct())
	clearcase.mkview(nextIntBr, bl)
	
def sIncreNBVer(ins):
	"""
	Increase nightly build version,  e.g. if current version is 02, then increase to 03
	"""
	currVer = clearcase.getNextLabel(ins.getNBView(),ins.getWuceProduct())
	l = clearcase.parseLabel(currVer)
	(incfile,ver) = ('bldrev',int(l[6]))
	if float(l[2]) >= 5.0: #mainline release greater than 5.0
		(incfile,ver) = ('prodver',int(l[5]))
	clearcase.ctInView(ins.getNBView(), "cd {vt}/bld/wuce/ver; {ct} co -nc {incfile}".format(vt=ins.getVobTag(),ct=bmc.config.get('cleartool'),incfile=incfile))
	clearcase.ctInView(ins.getNBView(), "cd {vt}/bld/wuce/ver; echo {ver}>{incfile}".format(vt=ins.getVobTag(),ct=bmc.config.get('cleartool'),ver=ver,incfile=incfile))
	clearcase.ctInView(ins.getNBView(), "cd {vt}/bld/wuce/ver; {ct} ci -nc -iden {incfile}".format(vt=ins.getVobTag(),ct=bmc.config.get('cleartool'),incfile=incfile))
	
#scm baseline process
def sGrantOkMergeToInt(ins):
	intBr = clearcase.getIntegrationBranch(ins.getNBView(),ins.getWuceProduct())
	clearcase.grantOkToMerge(intBr, ins.getTargetRelMain(), ins.getVobFamily)
def sMergeIntToRelMain(ins):
	bl = clearcase.getBaselineLabel(ins.getNBView(), ins.getWuceProduct())
	mergelog = ins.getDailyDir() + "/{bl}/{bl}.scBRMerge.{vob}".format(bl=bl,vob=ins.getVobFamily())
	relview = ins.getName() + "-bmc-rel"
	if not clearcase.isViewExist(relview):
		scmbl = clearcase.getScmBaselineLabel(ins.getNBView(), ins.getWuceProduct())
		clearcase.mkview(relview, scmbl)
	cslist = []
	with open(clearcase.getViewConfigSpec(ins.getNBView()), "r") as f:
		cslist = f.readlines()
	intBr = clearcase.getIntegrationBranch(ins.getNBView(), ins.getWuceProduct())
	[cs.replace(intBr, ins.getTargetRelMain()) for cs in cslist]
	logdir = os.environ['BMC_HOME'] + "/log/{ins}".format(ins=ins.getName())
	with open(logdir + "/{lb}.rel.cs".format(lb=nextBl), "w") as f:
		f.writelines(cslist)
	clearcase.merge(intBr, relview, ins.getVobFamily(), mergelog)
	
def sCreateRelLb(ins):
	bl = clearcase.getScmBaselineLabel(ins.getNBView(), ins.getWuceProduct())
	clearcase.mklbtype(bl, ins.getVobTag(), ins.getNBView())
	logger.info("created label type {lb}".format(lb=bl))
def sLabelRelMain(ins):
	bl = clearcase.getScmBaselineLabel(ins.getNBView(), ins.getWuceProduct())
	lblog = ins.getDailyDir() + "/{bl}/{bl}.mklabel".format(bl=bl)
	clearcase.mklabel(bl, ins.getVobTag(), ins.getNBView(), lblog)
def sMkPrjDevPrjScm(ins):
	bl = clearcase.getScmBaselineLabel(ins.getNBView(), ins.getWuceProduct())
	nextBl = clearcase.getNextScmBaselineLabel(ins.getNBView(), ins.getWuceProduct())
	prj = cmbpConfigDir + "/{vobname}_projects/{lb}.prj".format(vobname=ins.getVobFamily(False),lb=bl)
	nextPrj = cmbpConfigDir + "/{vobname}_projects/{lb}.prj".format(vobname=ins.getVobFamily(False),lb=nextBl)
	prjlist = []
	with open(prj, 'r') as f:
		prjlist = f.readlines()
	[prj.replace(bl, nextBl) for prj in prjlist]
	with open(nextPrj, 'w') as f:
		f.writelines(prjlist)

#CQCM related process, no longer used now
#deprecated
def sCloseCr(ins):
	targetIntBl = clearcase.getBaselineLabel(ins.getNBView(),ins.getWuceProduct())
	clearcase.ctInView(bmc.config.get('commonView'), "cd {vt}; {cqtool} closecr -bl {targetIntBl}".format(vt=ins.getVobTag(),cqtool=bmc.config.get('cqtool'),targetIntBl=targetIntBl))
def sLinkIntBlP():
	targetIntBl = clearcase.getBaselineLabel(ins.getNBView(),ins.getWuceProduct())
	preIntBl =  clearcase.getPreviousBaselineLabel(ins.getNBView(),ins.getWuceProduct())
	clearcase.ctInView(bmc.config.get('commonView'), "cd {vt}; {cqtool} linkbl {targetIntBl} -a -predecessor {preIntBl}".format(vt=ins.getVobTag(),cqtool=bmc.config.get('cqtool'),targetIntBl=targetIntBl, preIntBl=preIntBl))
def sCloseIntBl():
	targetIntBl = clearcase.getBaselineLabel(ins.getNBView(),ins.getWuceProduct())
	clearcase.ctInView(bmc.config.get('commonView'), "cd {vt}; {cqtool} closebl {targetIntBl}".format(vt=ins.getVobTag(),cqtool=bmc.config.get('cqtool'),targetIntBl=targetIntBl))
def sLinkScmBlP():
	targetScmBl = clearcase.getScmBaselineLabel(ins.getNBView(),ins.getWuceProduct())
	preScmBl =  clearcase.getPreviousScmBaselineLabel(ins.getNBView(),ins.getWuceProduct())
	clearcase.ctInView(bmc.config.get('commonView'), "cd {vt}; {cqtool} linkbl {targetScmBl} -a -predecessor {preScmBl}".format(vt=ins.getVobTag(),cqtool=bmc.config.get('cqtool'),targetScmBl=targetScmBl, preScmBl=preScmBl))
def sLinkScmBlC():
	targetIntBl = clearcase.getBaselineLabel(ins.getNBView(),ins.getWuceProduct())
	targetScmBl = clearcase.getScmBaselineLabel(ins.getNBView(),ins.getWuceProduct())
	clearcase.ctInView(bmc.config.get('commonView'), "cd {vt}; {cqtool} linkbl {targetScmBl} -a -child {targetIntBl}".format(vt=ins.getVobTag(),cqtool=bmc.config.get('cqtool'),targetIntBl=targetIntBl, targetScmBl=targetScmBl))
def sCloseScmBl():
	targetScmtBl = clearcase.getScmBaselineLabel(ins.getNBView(),ins.getWuceProduct())
	clearcase.ctInView(bmc.config.get('commonView'), "cd {vt}; {cqtool} closebl {targetScmtBl}".format(vt=ins.getVobTag(),cqtool=bmc.config.get('cqtool'),targetScmtBl=targetScmtBl))
