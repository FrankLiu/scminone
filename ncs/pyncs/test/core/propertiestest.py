#!/usr/bin/env python
"""
properties test suite.
"""

import sys, os
import unittest

# adding current directory to path to make sure local modules can be imported
sys.path.insert(0, '.')

from ncs.core.properties import Properties

NCS_HOME=os.getcwd()+"/../ncshome"
os.environ["NCS_HOME"] = NCS_HOME

class PropertiesTest(unittest.TestCase):
    def setUp(self):
        self.props = Properties()
        #self.props.debugon()
        
    def test_load(self):
        self.props.load(NCS_HOME + "/conf.init/ncs_sm5.0.properties")
        self.assert_(self.props.size() > 0)
        self.props.dump()
    
    def test_get(self):
        self.props.load(NCS_HOME + "/conf.init/ncs_sm5.0.properties")
        self.assert_(self.props.get('ncs.test.compile_path'), '/vob/wibb_bts/msm/test/sm_test/cosim')
    
    def test_set(self):
        self.props.set('ncs.test.compile_path', '/vob/wibb_bts/msm/test/sm_test/cosim')
        self.assert_(self.props.get('ncs.test.compile_path'), '/vob/wibb_bts/msm/test/sm_test/cosim')
    
    def test_search(self):
        self.props.load(NCS_HOME + "/conf.init/ncs_sm5.0.properties")
        prjs = self.props.search('prj')
        self.assert_(len(prjs) == 5)
        for (key,value) in prjs.items():
            print("{0} = {1}".format(key,value))
    
    def test_getrange(self):
        self.props.load(NCS_HOME + "/conf.init/ncs_sm5.0.properties")
        cases = self.props.getrange('ncs.test.suite.openr6')
        self.assert_(len(cases) > 0)
        for case in cases: print(case)
        
        cases = self.props.getrange('ncs.test.suite.rrm_motor6')
        self.assert_(len(cases) == 1)
        self.assert_(cases[0] == 3150)
        
        cases = self.props.getrange('ncs.test.suite.motor6')
        self.assert_(len(cases) == 7)
        for case in cases: print(case)
        
if __name__ == "__main__":
    unittest.main()
    