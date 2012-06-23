#!/usr/bin/ruby -w

require 'test/unit'
require 'logger'
require 'ncs/AppLogger'

class AppLoggerTest < Test::Unit::TestCase
	@@ClassName = 'AppLoggerTest'
	include AppLogger
	def setup
		@logger = getLogger(@@ClassName)
		@logger.level = Logger::DEBUG
		@logger.datetime_format = "%Y-%m-%d %H:%M:%S"
		@logger.info("test setup...")
	end
	
	def testLog
		@logger.debug("test debug")
		@logger.info("test info")
		@logger.warn("test warn")
		@logger.error("test error")
		@logger.fatal("test fatal")
	end
	
	def teardown
		@logger.info("test teardown...")
	end
end
