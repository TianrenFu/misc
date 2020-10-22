from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize

files = ['cyrand.pyx', 'PieceReader.pyx', 'Actions.pyx', 'Pieces.pyx', 'draft.pyx']
# files = ['actions.pyx']

for i in range(len(files)):
    file = files[i]
    setup(
        ext_modules=cythonize(file, language='c++')
    )

# test
if __name__ == '__main__':
    for i in range(len(files)):
        module = files[i].split('.')[0]
        print('testing <' + module + '> ...')
        __import__(module)
