#!/usr/bin/env ruby -w

require 'ncs/Common'
require 'ncs/LoggerFactory'
require 'ncs/ExcelLib'

class SrParser < ExcelLib
	def initialize(srmappingfile)
		@srmappingfile = srmappingfile||'WMX_CoSim_SR.xls'
		super(@srmappingfile)
	end
	
	def headline(sheetname)
		headline = []
		sheet = self.worksheet(sheetname)
		(col_min,col_max) = self.colrange(sheetname)
		puts "col_range: #{col_min}-#{col_max}"
		col_min.upto(col_max) do |i|
			headline.push(self.data(sheetname, 0, i))
		end
		return headline
	end
	
	def srlist(sheetname, bytype='', byvals=[], excludes=false)
		srlist = []
		sheet = self.worksheet(sheetname)
		(col_min,col_max) = self.colrange(sheetname)
		(row_min,row_max) = self.rowrange(sheetname)
		headline = self.headline(sheetname);
		(row_min+1).upto(row_max-1) do |row|
			line = {}
			col_min.upto(col_max) do |col|
				data = (self.data(sheetname, row, col)||'').to_s.strip
				line.store(headline[col], data)
			end
			srlist.push(line)
		end
		#srlib by type & values
		if not bytype.empty? and not byvals.empty?
			srlistBy = []
			srlist.each{ |sr|
				if excludes
					srlistBy.push(sr) if not byvals.include?(sr.fetch(bytype))
				else 
					srlistBy.push(sr) if byvals.include?(sr.fetch(bytype))
				end
			}
			return srlistBy
		end
		
		return srlist
	end
	
	def srlistBy(sheetname, bytype, byvals)
		return  self.srlist(sheetname, bytype, byvals)
	end
	
	def srlistNot(sheetname, bytype, byvals)
		return  self.srlist(sheetname, bytype, byvals, true)
	end
	
	def latestSrlist(sheetname)
		srlist = self.srlistNot(sheetname, '#Status', ['Closed', 'Performed'])
		latestSrlist = []
		srlist.each { |sr|
			(openDate,openTime) = sr.fetch('#Open Date').split(/\s+/, 2)
			#puts "open date: #{openDate}"
			if latestSrlist.empty?
				latestSrlist.push(sr)
				next
			end
			(latestOpenDate,latestOpenTime) = latestSrlist[0].fetch('#Open Date').split(/\s+/, 2)
			#puts "latest open date: #{latestOpenDate}"
			comp_date = compare_date(openDate,latestOpenDate)
			if comp_date>0
				#delete all elements & insert new one
				#puts "#{openDate} > #{latestOpenDate}"
				latestSrlist.replace([sr])
			elsif comp_date==0
				#puts "#{openDate} = #{latestOpenDate}"
				latestSrlist.push(sr)
			#comp_date<0
			else
				#puts "#{openDate} < #{latestOpenDate}"
				#do nothing, just ignore the sr
			end
		}
		return latestSrlist
	end
	
	def srById(sheetname, srid)
		srlist = self.srlistBy(sheetname, '#SR', [srid])
		return {} if srlist.empty?
		return srlist[0]
	end
	
	def srMappings(sheetname)
		srlist = self.srlist(sheetname)
		srMappings = {}
		srlist.each{ |sr|
			tcno = sr.fetch('#Failed Case No.','').strip.to_i.to_s
			srno = sr.fetch('#SR No.','').strip
			#puts "#{tcno} = #{srno}"
			srMappings.store(tcno,srno)
		}
		return srMappings
	end
	
	def srMapping(sheetname, tcno)
		srMappings = self.srMappings(sheetname)
		return srMappings.fetch(tcno.to_s, '')
	end
end
