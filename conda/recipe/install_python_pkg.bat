echo on

cd %SRC_DIR%\python
%PYTHON% setup.py install --single-version-externally-managed --record=%SRC_DIR%\record.txt
