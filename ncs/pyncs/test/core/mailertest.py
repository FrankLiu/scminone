#!/usr/bin/env python
"""
mailer test suite.
"""

import sys, os
import unittest

# adding current directory to path to make sure local modules can be imported
sys.path.insert(0, '.')
from ncs.core.mailer import Mailer

class MailerTest(unittest.TestCase):
	def setUp(self):
		self.mailer = Mailer('de01exm68.ds.mot.com')
		self.mailer.fromAddr('hzcosim@wimax-cosim.mot.com')
		self.mailer.toAddr(['cwnj74@motorola.com'])

	def test_send(self):
		self.mailer.subject('test python smtp lib')
		self.mailer.content('test content')
		self.mailer.attach(os.getcwd()+"/test/mail_merged.html")
		self.mailer.attach(os.getcwd()+"/test/Coverage_full.csv")
		self.mailer.send()
        print("mail has been sent out!")
		
if __name__ == "__main__":
    unittest.main()
    