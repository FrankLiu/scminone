#!/usr/bin/env python

from ncs.core.component import Component
from ncs.exceptions import *

import sys
import os
import re
import logging

class PropertiesNotExist(Exception):
	def __init__(self, properties_file):
		self.properties_file = properties_file
	
	def __str__(self):
		return repr("properties file {0} not exist!".format(self.properties_file)) 
		
class PropertiesNotLoad(Exception):
	def __init__(self, properties_file):
		self.properties_file = properties_file
	
	def __str__(self):
		return repr("properties file {0} is not loaded!".format(self.properties_file)) 
		
class Properties(Component):
    """
    This is a python portion for java Properties file
    """
    
    def __init__(self):
        Component.__init__(self, 'ncs.core.properties.Properties', ['load','get','set','search'])
        self.properties_file = ''
        self.raw_properties = {}
        self.properties = {}
        self.logger = logging.getLogger(self.__class__.__name__)
        
    def load(self, resource):
        if not os.path.exists(resource):
            self.logger.error("{0} not exists".format(resource))
            raise PropertiesNotExist(resource)
            
        if not os.path.isfile(resource):
            self.logger.error("{0} is not a file!".format(resource))
            raise PropertiesNotLoad(resource)
        
        self.properties_file = resource
        self.raw_properties = self.properties = self._parse(resource)
        #check if there is import properties or file
        import_file = self.get("ncs.import", self.get("import"))
        if import_file: 
            import_file = self._unescape_property(import_file)
            if not os.path.exists(import_file):
                self.logger.warn("import file {0} not exists".format(import_file))
                self.logger.warn("ignored import file {0}".format(import_file))
            if self.isdebugon(): print("import properties file: {0}".format(import_file)) 
            self.import_from_file(import_file)
        self._unescape_properties()
        return self.properties
    
    def _parse(self, resource):
        props = dict()
        fp = open(resource, 'r')
        (k,v) = ('','')
        is_multi_line = False
        for line in fp.readlines():
            line = line.strip()
             #space line or commentted line will be ignored
            if len(line) == 0 or line.startswith('#'):
                continue
            #end with character(\), multi-line start line
            if not is_multi_line and line.endswith('\\'):
                is_multi_line = True
                #remove the end character(\) and split with character(=)
                (k,v) = line.replace('\\','').split('=', 1)
                continue
            if is_multi_line:
                #not end with character(\), multi-line end line
                if not line.endswith('\\'):
                    v = v + ' ' + line
                    props[k.strip()] = v.strip()
                    k = v = ''
                    is_multi_line = False
                #multi-line
                else:
                    v = v + ' ' + line.replace('\\','')
                continue
            #normail line(key=value)
            (k,v) = line.replace('\\','').split('=', 1)
            if len(k.strip()) == 0:
                continue
            props[k.strip()] = v.strip()
            (k,v) = ('','')
        return props
        
    def _unescape_property(self, value):
        #white space
        if len(value.strip()) == 0: return
        
        #match ${ncs.log.dir}
        extract_vars = lambda s: [v[1] for v in re.findall(r'^(.*)\${([^}]+)}(.*)$', s)]
        while extract_vars(value):
            for var in extract_vars(value):
                if self.isdebugon(): print("matched key: {0}".format(var))
                if not self.properties.has_key(var):
                    print("[warn] matched key not exists: {0}".format(var))
                    break
                #matched key exits
                val = self.properties.get(var)
                if self.isdebugon(): print("{0} = {1}".format(var, val))
                value = value.replace('${'+var+'}', val)
            
            
        #match $ENV{HOME}
        extract_envs = lambda s: [e[1] for e in re.findall(r'^(.*)\$ENV{([^}]+)}(.*)$', s)]
        while extract_envs(value):
            for env in extract_envs(value):
                if self.isdebugon(): print("matched environ: {0} = {1}".format(env, os.getenv(env,'')))
                value = value.replace('$ENV{'+env+'}', os.getenv(env,''))
            
        return value
        
    def _unescape_properties(self):
        for (key,value) in self.properties.items():
            self.properties[key] = self._unescape_property(value)
        
    def get(self, key, default=None):
        return self.properties.get(key, default)
    def getint(self, key, default=0):
        int(self.get(key,default))
    def getlong(self, key, default=0):
        long(self.get(key,default))
    def getfloat(self, key, default=0.0):
        float(self.get(key,default))
    def getboolean(self, key, default=False):
        value = self.get(key)
        if value: 
            return True
        return default or False
    def getrange(self, key):
        result = []
        value = self.get(key)
        if value:
            for val in value.split(','):
                #val as range
                if '-' in val:
                    (start,end) = val.split('-', 1)
                    result.extend(range(int(start),int(end)+1))
                else:
                    result.append(int(val))
        return result

    def set(self, key, value=None):
        self.properties[key] = value

    def search(self, keywords):
        props = {}
        for (key,value) in self.properties.items():
            if keywords in key:
                props[key] = value
        return props
	
    def size(self):
        return len(self.properties.items())
        
    def dump(self):
        for key in sorted(self.properties.keys()): print("{0} = {1}".format(key,self.properties.get(key)))
            
    def import_properties(self, properties, override=False):
        for (key,value) in properties.items():
            if self.properties.has_key(key) and not override: continue 
            self.properties[key] = value
            
    def import_from_file(self, resource, override=False):
        properties = self._parse(resource)
        self.import_properties(properties, override)
	