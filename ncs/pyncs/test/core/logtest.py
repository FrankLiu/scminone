#!/usr/bin/env python
"""
logger test suite.
"""

import logging
import sys, os
import unittest

# adding current directory to path to make sure local modules can be imported
sys.path.insert(0, '.')

class LoggerTest(unittest.TestCase):
    def setUp(self):
        self.logger = logging.getLogger("test.logtest")
    
    def test_log(self):
        self.logger.debug("test debug message")
        self.logger.info("test info message")
        self.logger.warn("test warn message")
        self.logger.error("test error message")
        self.logger.fatal("test fatal message")
        
if __name__ == "__main__":
    unittest.main()
    