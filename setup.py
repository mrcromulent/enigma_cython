from setuptools import setup, Extension
from Cython.Build import cythonize

setup(
    name="enigma_machine",
    ext_modules=
    cythonize(
        [
            Extension("enigma",
                      sources=["src/cython_example/enigma.pyx"])
        ],
        compiler_directives={'language_level': "3"},
        annotate=True
    ),
)
