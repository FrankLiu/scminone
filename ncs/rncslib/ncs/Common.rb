#!/usr/bin/ruby -w

def sec2dhms(secs)
  time = secs.round          # Get rid of microseconds
  sec = time % 60            # Extract seconds
  time /= 60                 # Get rid of seconds
  mins = time % 60           # Extract minutes
  time /= 60                 # Get rid of minutes
  hrs = time % 24            # Extract hours
  time /= 24                 # Get rid of hours
  days = time                # Days (final remainder)
  [days, hrs, mins, sec]     # Return array [d,h,m,s]
end

def dhms2sec(days,hrs=0,min=0,sec=0)
  days*86400 + hrs*3600 + min*60 + sec
end

def stat_time(start_time, end_time)
	spent_time = end_time-start_time
	spent_mm = spent_time/60
	spent_sec = spent_time%60
	spent_hr = spent_mm >= 60 ? (spent_mm/60).to_i : 0
	spent_mm = spent_mm >= 60 ? (spent_mm%60).to_i : 0
	return [spent_hr,spent_mm,spent_sec]
end

def compare_date(date1, date2)
	(m1,d1,y1) = date1.split(/[-\/]/,3)
	(m2,d2,y2) = date2.split(/[-\/]/,3)
	m1=m1.to_i;d1=d1.to_i;y1=y1.to_i;m2=m2.to_i;d2=d2.to_i;y2=y2.to_i
	#puts "date1: #{m1},#{d1},#{y1}"
	#puts "date2: #{m2},#{d2},#{y2}"
	if y1 > y2
		#puts "#{y1} > #{y2}"
		return 1
	elsif y1 < y2
		#puts "#{y1} < #{y2}"
		return -1
	#$y1==y2
	else
		if m1>m2
			#puts "#{m1} > #{m2}"
			return 1
		elsif m1<m2
			#puts "#{m1} < #{m2}"
			return -1
		#m1==m2
		else
			if d1>d2
				#puts "#{d1} > #{d2}"
				return 1
			elsif d1<d2
				#puts "#{d1} < #{d2}"
				return -1
			else 
				return 0
			end
		end
	end
end

#extends File class
class File
	def File.contains(fn, pattern)
		IO.foreach(fn){ |line|
			return true if line =~ /pattern/
		}
		return false
	end
end

#extends String class
class String
	def ljust(length, padding=' ')
		if self.length >= length
			return self
		else
			return self+padding*(length-self.length)
		end
	end
	
	def rjust(length, padding=' ')
		if self.length >= length
			return self
		else
			return padding*(length-self.length)+self
		end
	end
end

