cmake --build build --config Release --target install

:: Copy files into library bin so that they can be found
cp %LIBRARY_LIB%\tvm.dll %LIBRARY_BIN%\tvm.dll
cp %LIBRARY_LIB%\tvm_runtime.dll %LIBRARY_BIN%\tvm_runtime.dll
