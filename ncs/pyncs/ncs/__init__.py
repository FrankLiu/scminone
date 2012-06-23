#!/usr/bin/env python
"""
NCS: The Nightly CoSim Script.

core components: properties mailer ftp mapreduce
template: mail
ncs components: initializer compiler runner parser
ncs process: 
			initialize
				|
			initialize project  -> get latest project, create project folder, download config-spec
				|
			compile -> compile isl, compile model(sm,sfm,...), compile ttcn
				|
			run test suite -> send out test suite to client machine based on mapreduce algorithm
				|
			combine test result -> receive test suite result based on mapreduce algorithm
				|
			record project
				|
			send mail
				|
			teminate
"""

__all__ = ['initializer','compiler','runner','model','tools','parser','exceptions']

# Ensure the user is running the version of python we require.
import sys
if not hasattr(sys, "version_info") or sys.version_info < (2,3):
    raise RuntimeError("NCS requires Python 2.3 or later.")
del sys

