:: Build on windows
echo on

rd /s /q build
mkdir build
cd build

cmake ^
      -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX% ^
      -DCMAKE_INSTALL_PREFIX:PATH=%LIBRARY_PREFIX% ^
      -DUSE_LLVM="llvm-config --link-static" ^
      -DUSE_RPC=ON ^
      -DUSE_CPP_RPC=ON ^
      -DUSE_SORT=ON ^
      -DUSE_RANDOM=ON ^
      -DUSE_GRAPH_RUNTIME_DEBUG=ON ^
      -DINSTALL_DEV=ON ^
      %SRC_DIR%

cd ..
