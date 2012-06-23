#!/usr/bin/env python

import sys
import os
import logging
from optparse import OptionParser

curdir=os.getcwd()
sys.path.insert(0, curdir+'/lib')
sys.path.insert(0, '.')
from ncs import *
from ncs.core import *
from ncs.mail import *

def load_configuration():
	props = Properties()
	props.load(curdir+"/conf/ncs_sm5.0.properties")
	
def check_ncs_status():
	pass
def check_system_vars():
	pass
def initialize_ncs():
	pass
def terminate_ncs():
	pass
	
def parse_args():
	usage = "usage: %prog [options] arg1 arg2"
	parser = OptionParser(usage=usage)
	parser.add_option("-p", "--properties-file", dest="properties-file", help="configuration properties file name")
	parser.add_option("-n", "--name", dest="name", help="name")
	parser.add_option("-v", "--version", dest="version", help="version")
	parser.add_option("-b", "--verbose", dest="verbose", help="verbose")
	(options, args) = parser.parse_args()
	
if __name__ == "__main__":
    pass
    