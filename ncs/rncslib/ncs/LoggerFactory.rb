#!/usr/bin/env ruby -w

require 'logger'
require 'ncs/Properties'

class LoggerFactory
	attr_accessor :logdir, :logname, :level, :shiftnumber, :shiftsize, :dateformat

	@@loggers = {}
	def loggers
		return @@loggers
	end
	
	def initializeLogger
		Dir.mkdir loggerDir unless File.directory?(@logdir)
		logger = Logger.new("#{@logdir}/#{@logname}", @shiftnumber, @shiftsize)
		logger.level = @level
		logger.datetime_format = @dateformat
		return logger
	end
		
	def configure
		return if @@instance.dateformat
		#load configure file
		if File.exists?('log4r.properties')
			configure = Properties.new().load('log4r.properties')
		else
			configure = Properties.new()
			configure.set('log4r.logdir', 'logs')
			configure.set('log4r.name', 'log4r.log')
			configure.set('log4r.level', 'info')
			configure.set('log4r.shiftnumber', 10)
			configure.set('log4r.shiftsize', 1024000)
			configure.set('log4r.dateformat', "%Y-%m-%dT%H:%M:%S")
		end
		@logdir = configure.get('log4r.logdir', 'logs')
		@logname = configure.get('log4r.name', 'log4r.log')
		loglevel = configure.get('log4r.level', 'info')
		case loglevel
			when /debug/
				@level = Logger::DEBUG
			when /info/
				@level = Logger::INFO
			when /warn/
				@level = Logger::WARN
			when /error/
				@level = Logger::ERROR
			when /fatal/
				@level = Logger::FATAL
			else
				raise "loglevel is not support, please specify [debug,info,warn,error,fatal]"
		end
		@shiftnumber = configure.getint('log4r.shiftnumber', 10)
		@shiftsize = configure.getint('log4r.shiftsize', 1024000)
		@dateformat = configure.get('log4r.dateformat',  "%Y-%m-%dT%H:%M:%S")
	end
	
	@@instance = LoggerFactory.new
	private_class_method :new
	class << self
		#@@invoke_count = 0
		def instance
			return @@instance
		end
		
		def getLogger(name)
			#@@invoke_count = @@invoke_count + 1
			name = name.class if name.is_a?(Class)
			return @@loggers.fetch(name) if @@loggers.key?(name)
			#puts "getLogger invoked #{@@invoke_count}..."
			LoggerFactory.instance().configure()
			logger = LoggerFactory.instance().initializeLogger()
			logger.progname = name
			@@loggers.store(name, logger)
			return logger
		end
		
		def getStdoutLogger(name, level=Logger::INFO)
			name = name.class if name.is_a?(Class)
			logger = Logger.new(STDOUT)
			logger.level = level
			logger.progname = name
			return logger
		end
	end
end
