#!/usr/bin/ruby -w

require 'test/unit'
require 'logger'
require 'ncs/LoggerFactory'

class LoggerFactoryTest < Test::Unit::TestCase
	@@ClassName = 'LoggerFactoryTest'
	def setup
		
	end
	
	def test_log
		@logger = LoggerFactory.getLogger(self.class.name)
		assert_instance_of Logger,@logger
		@logger.info {"test info"}
		@logger.warn("test warn")
		@logger.error("test error")
		@logger.fatal("test fatal")
	end
	
	def test_debug
		@logger = LoggerFactory.getLogger(self.class.name)
		assert_instance_of Logger,@logger
		@logger.level = Logger::DEBUG
		@logger.debug("test debug")
	end
	
	def teardown
		@logger = nil
	end
end
