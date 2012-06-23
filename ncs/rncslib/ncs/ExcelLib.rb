#!/usr/bin/env ruby -w

require 'spreadsheet'

#the spreadsheet only support Excel 97 - 2000 for now
class ExcelLib
	def initialize(excelfile)
		@excelfile = excelfile
		Spreadsheet.client_encoding = 'UTF-8'
		@book = Spreadsheet.open(@excelfile)
	end
	
	def worksheet(name)
		@book.worksheets.find{ |worksheet|
			return worksheet if worksheet.name.eql?(name)
		}
	end
	
	def colcount(sheetname)
		self.worksheet(sheetname).column_count
	end
	
	def rowcount(sheetname)
		self.worksheet(sheetname).row_count
	end
	
	def colrange(sheetname)
		self.worksheet(sheetname).dimensions[2,2]
	end
	
	def rowrange(sheetname)
		self.worksheet(sheetname).dimensions[0,2]
	end
	
	def data(sheetname, row, column)
		self.worksheet(sheetname).cell(row,column)
	end
	alias cell data
	
end
