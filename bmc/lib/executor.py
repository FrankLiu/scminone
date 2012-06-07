#!/usr/bin/env python

import sys
import os
import re
import subprocess
import logging
import model
import bmcapi as bmc
import tasks
import command
import clearcase

class Executor:
	def __init__(self, instance):
		self.instance = instance
		self.logger = logging.getLogger("bmc.executor")
		
	def runStep(self, stepname, mode="noUse", view="noUse"):
		step = self.instance.getStep(stepname)
		if step.isatomic():
			self.logger.info("executor::run step [%s]..." %(step.name))
			#run step
			if not step.tool == "noUse": #configured step tool(external shell script)
				if not os.path.exists(step.tool.split()[0]):
					self.logger.fatal("Step tool [%s] not exists"%(step.tool.split()[0]))
					sys.exit(1)
				try:
					retcode = subprocess.call(step.tool.split())
					if retcode < 0:
						self.logger.error("Child was terminated by signal with return code: " + str(retcode))
					else:
						self.logger.error("Child returned: " + str(retcode))
				except IOError as e:
					self.logger.fatal("Execution failed:"+e)
			elif hasattr(steps, step.target) and callable(getattr(steps, step.target)):
				t = getattr(steps, step.target)
				retcode = t(self.instance, mode, view)
			else: 
				self.logger.warn("Invalid tool or target specified for step [%s]"%(step.name))
				retcode = -1
			self.logger.info("step executcuted with return code: [%s]." %retcode)
		elif step.iscomposite():
			self.logger.info("run composite step [%s] with targets [%s]." %(step.name, step.getTargets()))
			for t in step.getTargets():
				self.runStep(self.instance.getStep(t))
		else:
			self.logger.warn("Invalid step type: %s!" %(step.type))
	
	def runTask(self, taskname, *args, **kwargs):
		self.logger.info("executor::run task [%s]..."%taskname)
		ret = False
		if hasattr(tasks, taskname) and callable(getattr(tasks, taskname)):
			t = getattr(tasks, taskname)
			ret = t(*args, **kwargs)
		else:
			self.logger.warn("Invalid task [%s]!" %taskname)
		self.logger.info("executor::task [%s] end."%taskname)
		return ret
