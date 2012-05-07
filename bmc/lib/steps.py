#!/usr/bin/env python

import sys
import os
from subprocess import Popen,PIPE,STDOUT
import re
import logging
import bmcapi as bmc

logger = logging.getLogger("bmc.step")

