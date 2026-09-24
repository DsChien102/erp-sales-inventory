#!/usr/bin/env python3
"""Current Theme 7 validation entrypoint.

The original v4.3.1 static package validator remains preserved at
validation/validate-package.py as historical evidence. The current product
baseline is the v3.6.1 executable HTML prototype, so this wrapper validates
that current runtime/prototype authority instead of replaying a stale package
schema against newer artifacts.
"""
import runpy
from pathlib import Path
runpy.run_path(str(Path(__file__).resolve().parent / 'validation' / 'validate-current-prototype-v361.py'), run_name='__main__')
