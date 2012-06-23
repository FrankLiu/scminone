#!/usr/bin/env python

"""
system commands used for ncs
"""
import os

clearcase_home=os.getenv('CLEARCASE_HOME','/opt/rational/clearcase')
cleartool=clearcase_home+"/bin/cleartool"
clearmake=clearcase_home+"/bin/clearmake"

mousetrap_home=os.getenv('MOUSETRAP_HOME','/opt/apps/MT')
pduconverter=mousetrap_home+"/bin/pduconvert"

taug2_home=os.getenv('TAU_UML_DIR','/opt/apps/Tau')
taubatch=taug2_home+"/bin/taubatch"

tester_home=os.getenv('TAU_TTCN_DIR','/opt/apps/Tester')
t3cg=tester_home+"/bin/t3cg"

mergestat_home=os.getenv('MERGESTAT_HOME','/opt/apps/mergestat')
mergestat=mergestat_home+"/bin/mergestat"

def setcs(configspec):
	os.system("{0} setcs {1}".format(cleartool, configspec))
