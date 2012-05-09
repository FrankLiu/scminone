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
	
	def runWorkflow(self, flowname, phase):
		"""
		Run a workflow based on the configuration, a workflow contains several steps/tasks, and the definition should be as below.
		e.g
		<workflow name="mainline">
			<phase name="initial" ref="pInitializeMainline"/>
			<phase name="baseline" ref="pIntBLAllInOne"/>
		</workflow>
		<workflow name="patch">
			<phase name="initial" ref="pInitializePatch"/>
			<phase name="baseline" ref="pIntAllInOne"/>
		</workflow>
		<workflow name="feature">
			<phase name="initial" ref="pInitializeFeature"/>
			<phase name="baseline" ref="pIntAllInOne"/>
		</workflow>
		"""
		pass
		
	def runStep(self, stepname, mode="noUse", view="noUse"):
		step = self.instance.getStep(stepname)
		if step.isatomic():
			self.logger.info("run step [%s] with tool [%s]." %(step.name, step.tool))
			#run step
			if not step.tool == "noUse": #configured step tool(external shell script)
				if not os.path.exists(step.tool.split(' ')[0]):
					self.logger.fatal("Step tool [%s] not exists"%(step.tool.split(' ')[0]))
					sys.exit(1)
				try:
					retcode = subprocess.call(step.tool)
					if retcode < 0:
						self.logger.error("Child was terminated by signal with return code: " + retcode)
					else:
						self.logger.error("Child returned: " + retcode)
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
		self.logger.info("task [%s] start..."%taskname)
		ret = False
		if hasattr(tasks, taskname) and callable(getattr(tasks, taskname)):
			t = getattr(tasks, taskname)
			ret = t(*args, **kwargs)
		else:
			self.logger.warn("Invalid task [%s]!" %taskname)
		self.logger.info("task [%s] end."%taskname)
		return ret
	
	def runCleartool(self, cmd, *args, **kwargs):
		clearcase.ct(cmd, *args, **kwargs)
	
	def runCommand(self, cmd, *args, **kwargs):
		command.run(cmd, *args, **kwargs)
