#!/usr/bin/env python

"""
A simple XLS tool
"""
from ncs.core.component import Component
from ncs.exceptions import *
import xlrd
import sys
import os

class Xls(Component):
	def __init__(self, workbook_name):
		self.workbook_name = workbook_name
		
	def parse(self):
		if not os.path.exists(self.workbook_name):
			raise SrMappingNotExist(self.workbook_name)
		self.workbook = xlrd.open_workbook(self.workbook_name)
	
	def sheets(self):
		return self.workbook.sheets()
	
	def sheet_names(self):
		return self.workbook.sheet_names()
		
	def get_sheet(self, sheet_name):
		for sheet in self.workbook.sheets():
			if sheet.name == sheet_name:
				return sheet
		return None
	
	def _is_sheet_exists(self,sheet_name):
		if self.get_sheet(sheet_name) is None:
			raise WorkSheetNotExist(self.workbook_name, self.sheet_name)
			
	def get_rows(self, sheet_name):
		self._is_sheet_exists(sheet_name)
		return self.get_sheet(sheet_name).nrows
		
	def get_cols(self, sheet_name):
		self._is_sheet_exists(sheet_name)
		return self.get_sheet(sheet_name).ncols
		
	def get_data(self, sheet_name, row_idx, col_idx):
		self._is_sheet_exists(sheet_name)
		return self.get_sheet(sheet_name).cell_value(rowx=row_idx, colx=col_idx)
		