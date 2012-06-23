#!/usr/bin/env python

import os
import sys
import web
from ncs.exceptions import *
from ncs.core.mailer import Mailer
from ncs.mail.builder import *

mailer = Mailer('de01exm68.ds.mot.com')
mailer.fromAddr('hzcosim@wimax-cosim.mot.com')
mailer.toAddr(['cwnj74@motorola.com'])

def send(subject, body, attachs=[]):
	pass

def send_inform(subject, messages=[]):
	pass
