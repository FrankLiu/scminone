#!/usr/bin/env python

import sys
import os
import re
import subprocess
import logging
import model
import bmcapi as bmc
import tasks
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
	
	def runCleartool(self, command, *args, **kwargs):
		clearcase.ct(command, *args, **kwargs)
	
	def runCommand(self, command, *args, **kwargs):
		logger.info("command [%s] start..."%command)
		pipesplitpattern = r'\|'
		splitpattern = r'\s+'
		splitchar = ' '
		if re.search(pipesplitpattern, command) is not None: #put all in one command, will not check *args and **kwargs
			cmds = re.split(pipesplitpattern, command)
			p1 = Popen(re.split(splitpattern, cmds[0]), stdout=PIPE, stderr=PIPE)
			lastPipe = p1
			pipecmds = cmds[1:] or list()
			if len(pipecmds) > 0:
				for (i, cmd) in enumerate(pipecmds[1:]):
					logger.debug("{i}: {cmd}".format(i=i,cmd=cmd))
					if i == len(pipecmds)-1:
						logger.debug("{i} == {len}-1, it is the latest one".format(i=i,len=len(pipecmds)))
						stderrPipe = STDOUT
					else:
						stderrPipe = PIPE
					p = Popen([k, v], stdin=lastPipe.stdout, stdout=PIPE, stderr=stderrPipe)
					lastPipe = p
			output = lastPipe.communicate()[0]
		else:
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
		logger.info("command [%s] end."%command)
		return output.strip()
