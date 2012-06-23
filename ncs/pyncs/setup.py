#!/usr/bin/env python

# ...

from distutils.core import setup

setup(name='ncs',
      version='3.0',
      description='NCS: Nightly CoSim Script',
      author='Frank Liu',
      author_email='cwnj74@motorolasolutions.com',
      maintainer='Frank Liu',
      maintainer_email='cwnj74@motorolasolutions.com',
      url=' http://10.192.185.187',
      packages=['ncs', 'ncs.core', 'ncs.mail'],
      long_description="Automatically run CoSim script.",
      license="Public domain",
      platforms=["any"],
     )
