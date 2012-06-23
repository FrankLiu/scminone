#!/usr/bin/env python

import re
import logging
from ncs.core.net import *
from ncs.exceptions import *
from ncs.model import ProjectTestSummary
import ncs.tools

class ProjectInitializer:
	def __init__(self, props):
		self.props = props
		self.logger = logging.getLogger(self.__class__.__name__)
		
	def doinitialize(self):
		self.logger.info("project initialize...")
		#load configuration
		ftpserver=self.props.get('ncs.ftp.server')
		ftpuser=self.props.get('ncs.ftp.username')
		ftppwd=self.props.get('ncs.ftp.password')
		daily_prj_dir=self.props.get('ncs.prj.daily_prj_dir')
		latestprj_pattern=self.props.get('ncs.prj.latestprj_pattern')
		excludes_pattern=self.props.get('ncs.prj.excludes_pattern')
		
		#get latest project name
		self.logger.info("get latest project and config-spec")
		ftp = Ftp(ftpserver, ftpuser, ftppwd)
		ftp.cd(daily_prj_dir)
		prj = ftp.ls(latestprj_pattern)[0][:-4]
		self.logger.info("project name is {0}".format(prj)
		if re.search(excludes_pattern, prj):
			err = ProjectSameAsPreviousOne(prj)
			self.logger.error(str(err))
			raise err
		pts = ProjectTestSummary(prj)
		tested_prjs = self.props.get('ncs.store.tested_projects')
		if pts.isrecorded(tested_prjs):
			err = ProjectIsTestedBefore(prj)
			self.logger.error(str(err))
			raise err
			
		#prepare project dir
		def preparedir(*dirs):
			for dir in dirs:
				if not os.path.exists(dir):
					os.mkdir(dir)
		logdir=self.props.get('ncs.log.dir')+"/"+prj
		storedir=self.props.get('ncs.store.dir')+"/"+prj
		self.logger.info("prepare project dir...")
		preparedir(logdir,storedir)
		
		#get project config spec
		self.logger.info("download config spec...")
		os.chdir(logdir)
		daily_build_dir=self.props.get('ncs.prj.daily_build_dir')
		ftp.cd(daily_build_dir)
		ftp.download(prj+".cs", prj+"_AH.cs")
		
		#update config spec for workview
		self.logger.info("update config spec for current view")
		ncs.tools.setcs(logdir+"/"+prj+"_AH.cs")
		return prj
	