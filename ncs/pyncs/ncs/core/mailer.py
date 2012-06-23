#!/usr/bin/env python

from ncs.core.component import Component
from ncs.exceptions import *
import sys
import os
import smtplib
import mimetypes
import email
from email import encoders
from email.message import Message
from email.mime.audio import MIMEAudio
from email.mime.base import MIMEBase
from email.mime.image import MIMEImage
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

class Mailer(Component):
	"""
	Mailer is a wrapper for smtp sender
	"""

	def __init__(self, server, user=None, passwd=None):
		Component.__init__(self, 'ncs.core.mailer.Mailer', ['fromAddr','toAddr','subject','attach','send'])
		self.server = server
		self.user = user
		self.pwd = passwd
		#initialize smtp
		self.smtp = smtplib.SMTP()
		#set debug level
		if self.isdebugon(): self.smtp.set_debuglevel(1)
		self.smtp.connect(self.server)
		#self.smtp.login(self.user, self.passwd)
		
		# Create the enclosing (outer) message
		self.outer = MIMEMultipart()
		self.outer.preamble = 'This is a multi-part message in MIME format.'

	def fromAddr(self, fromAddr):
		self.fromAddr = fromAddr
		self.outer['From'] = self.fromAddr
		
	def toAddr(self, toAddr=[]):
		self.toAddr = toAddr
		self.outer['To'] = ', '.join(self.toAddr)
		
	def subject(self, subject):
		self.subject = subject
		self.outer['Subject'] = self.subject
	
	def content(self, content, type="html"):
		self.content = content
		text = MIMEText(content, type)
		self.outer.attach(text)
		
	def attach(self, path):
		if not os.path.isfile(path):
			return
		(ctype, encoding) = mimetypes.guess_type(path)
		if ctype is None or encoding is not None:
			# No guess could be made, or the file is encoded (compressed), so
			# use a generic bag-of-bits type.
			ctype = 'application/octet-stream'
		maintype, subtype = ctype.split('/', 1)
		if maintype == 'text':
			fp = open(path)
			# Note: we should handle calculating the charset
			msg = MIMEText(fp.read(), _subtype=subtype)
			fp.close()
		elif maintype == 'image':
			fp = open(path, 'rb')
			msg = MIMEImage(fp.read(), _subtype=subtype)
			fp.close()
		elif maintype == 'audio':
			fp = open(path, 'rb')
			msg = MIMEAudio(fp.read(), _subtype=subtype)
			fp.close()
		else:
			fp = open(path, 'rb')
			msg = MIMEBase(maintype, subtype)
			msg.set_payload(fp.read())
			fp.close()
			# Encode the payload using Base64
			encoders.encode_base64(msg)
		# Set the filename parameter
		msg.add_header('Content-Disposition', 'attachment', filename=os.path.basename(path))
		self.outer.attach(msg)
		
	def send(self):
		self.smtp.sendmail(self.fromAddr, self.toAddr, self.outer.as_string())
		self.smtp.quit()
