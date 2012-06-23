#!/usr/bin/env python

from ncs.core.component import Component
from ncs.exceptions import *
import sys
import os
from ftplib import FTP
import telnetlib

class Ftp(Component):
	"""
	Ftp is a wrapper for ftp command shell
	"""
	def __init__(self, server, user=None, passwd=None):
		Component.__init__(self, 'ncs.core.net.Ftp', ['connect','login','ls','cwd','pwd','mkdir','rmdir','rm','download','upload','quit'])
		self.server = server
		self.user = user
		self.pwd = passwd
		self.ftp = FTP(self.server, self.user, self.pwd)
		
	def connect(self, server):
		self.ftp.connect(server)
		
	def login(self, user, passwd):
		self.ftp.login(user, pwd)
	
	def ls(self, pattern=None):
		files = self.ftp.nlst(pattern)
		return files
		
	def cd(self, dir):
		return self.ftp.cwd(dir)
		
	def pwd(self):
		return self.ftp.pwd()
		
	#ftp command: create dir
	def mkdir(self, dir):
		return self.ftp.mkd(dir)
	
	def rmdir(self, dir):
		return self.ftp.rmd(dir)
		
	def rm(self, file):
		return self.ftp.delete(file)
	
	def download(self, remote_file, local_file=None, mode='ascii'):
		openmode = 'w'
		if mode == "binary": openmode = 'wb'
		if not local_file: 
			local_file = os.path.basename(remote_file)
		self.ftp.retrlines("RETR {0}".format(remote_file), open(local_file, 'wb').write)
	
	def get(self, remote_file, local_file=None, mode='ascii'):
		return self.download(remote_file, local_file, mode)
		
	def upload(self, local_file, remote_file=None, mode='ascii'):
		openmode = 'r'
		if mode == "binary": openmode = 'rb'
		if not remote_file:
			remote_file = os.path.basename(local_file)
		self.ftp.storbinary("STOR {0}".format(remote_file), open(local_file, openmode))
	
	def put(self, local_file, remote_file=None, mode='ascii'):
		return self.upload(remote_file, local_file, mode)
		
	def quit(self):
		self.ftp.quit()
	
class Telnet(Component):
	"""
	Telnet is a wrapper for telnet command shell
	"""
	def __init__(self, server, port=23):
		Component.__init__(self, 'ncs.core.net.Telnet', ['login','cmd','quit'])
		self.telnet = telnetlib.Telnet(server, port)
		
	def login(self, user, passwd):
		self.telnet.read_until("login as: ")
		self.telnet.write(user + "\n")
		self.telnet.read_until("Password: ")
		self.telnet.write(pwd + "\n")
	
	def cmd(self, command):
		self.telnet.write(command + "\n")
		return self.read_all()
	
	def close(self):
		self.telnet.close()
	
	
