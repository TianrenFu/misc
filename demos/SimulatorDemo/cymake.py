from distutils.core import setup
from Cython.Build import cythonize

files = ['Simulator.pyx', 'SimPhysical.pyx']

for file in files:
    setup(
        ext_modules=cythonize(file, language='c++')
    )

import Simulator