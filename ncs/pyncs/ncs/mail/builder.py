#!/usr/bin/env python

import os
import sys

from ncs.model import *
from mako.template import Template
from mako.lookup import TemplateLookup

curdir=os.path.dirname(__file__)
DEFAULT_TEMPLATE_DIR=curdir+"/template"
DEFAULT_TEMPLATE=DEFAULT_TEMPLATE_DIR+"/mail.html"
DEFAULT_CACHE_DIR='/tmp/mako_modules'
class Builder:
	def __init__(self, template_dir=DEFAULT_TEMPLATE_DIR, template=DEFAULT_TEMPLATE):
		if not os.path.exists(template_dir):
			raise TemplateNotExist(template_dir)
		tlookup = TemplateLookup(directories=[template_dir], module_directory=DEFAULT_CACHE_DIR)
		self.template = Template(filename=template, lookup=tlookup)

	def render(self, project):
		project.testresultsummary()
		self.raw_content = self.template.render(
			title = project.title,
			loadversion = project.loadversion,
			srheadline = project.srheadline,
			srhtml = project.srhtml,
			srsummary = project.srsummary,
			sr_link = project.sr_link,
			report_link = project.report_link,
			mergestat = project.mergestat,
			projects_test_summary = project.projects_test_summary,
			testsummary = project.testsummary,
			projectrunners = project.projectrunners
		)
		return self.raw_content
		
	def output(self, file):
		if not os.path.exists(os.path.dirname(file)):
			os.system("mkdir",['-p', os.path.dirname(file)])
		fp = open(file, "w+")
		fp.writelines(self.raw_content)
		fp.close()
	
	