#!/usr/bin/env python

import sys
import os
import re
from subprocess import Popen,PIPE,STDOUT
import logging

logger = logging.getLogger("bmc.command")

pipe_split_pattern = '|'
arg_split_pattern = re.compile(r'\s+')
pipe_join_pattern = '|'
arg_join_pattern  = ' '

def parse(command, *args, **kwargs):
	logger.debug("parse command [{cmd},{args},{kwargs}]".format(cmd=command,args=args,kwargs=kwargs))
	#put all in one command [ls -l|grep test], will ignore *args and **kwargs
	cmds = ()
	if command.find(pipe_split_pattern) > 0:
		logger.debug("command str includes pipe character ['|']")
		cmds = command.split(pipe_split_pattern)
		logger.debug("command str includes {len} sub-commands".format(len=len(cmds)))
	else:
		logger.debug("command str doesn't includes pipe character ['|']")
		cmds = list()
		cmds.append(command + arg_join_pattern + arg_join_pattern.join(args))
		if len(kwargs) == 0:
			logger.debug("no extra-kwargs given.")
		for (k,v) in kwargs.items():
			logger.debug("pipe command: {k} {v}".format(k=k,v=v))
			cmds.append("{k} {v}".format(k=k,v=v))
	logger.debug("command includes {len} sub-commands".format(len=len(cmds)))
	cmds = [cmd.strip() for cmd in cmds]
	[logger.debug("sub-command: {cmd}".format(cmd=cmd)) for cmd in cmds]
	logger.debug("parse command [{cmd}] end.".format(cmd=command))
	return cmds

def parseAsStr(command, *args, **kwargs):
	if command.find(pipe_split_pattern) > 0:
		return command
	cmds = parse(command, *args, **kwargs)
	return pipe_join_pattern.join(cmds)
	
def run(command, *args, **kwargs):
	"""
	Run an external command
	the command can be one of below
		- system command, e.g. 
			run("ls -l")
			run("ls", "-l")
			run("ls", "-l", "-a")
			run("ls", "-l", head="-1")
			
		- external script, e.g. 
			run("/apps/public/bin/myquota", "view")
			run("/mot/proj/wibb_bts/daily/bin/apbuild.ksh", "apbld_tmp-testview", "noWinCleanPkg")
	"""
	logger.info("command [%s] start..."%command)
	command = parseAsStr(command, *args, **kwargs)
	output = ""
	try:
		output = Popen(command, stdout=PIPE, stderr=STDOUT, shell=True).communicate()[0]
		# if len(cmds) == 1:
			# p = Popen(arg_split_pattern.split(cmds[0]), stdout=PIPE, stderr=STDOUT)
		# elif len(cmds) == 2:
			# p1 = Popen(arg_split_pattern.split(cmds[0]), stdout=PIPE, stderr=STDOUT)
			# p = Popen(arg_split_pattern.split(cmds[1]), stdin=p1.stdout, stdout=PIPE, stderr=STDOUT)
		# else: #len(cmds) >= 3
			# p = Popen(arg_split_pattern.split(cmds[0]), stdout=PIPE, stderr=STDOUT)
			# for cmd in cmds[1:len(cmds)-2]:
				# logger.debug("sub-command: {cmd}".format(cmd=cmd))
				# p = Popen(arg_split_pattern.split(cmd), stdin=p.stdout, stdout=PIPE, stderr=PIPE)
			# p = Popen(arg_split_pattern.split(cmds[len(cmds)-1]), stdin=p.stdout, stdout=PIPE, stderr=STDOUT)
		# output = p.communicate()[0]
		logger.debug("command output:")
		logger.debug(output.strip())
	except IOError as e:
		self.logger.fatal("Execution failed:"+e)
	logger.info("command [%s] end."%command)
	return output.strip()

	