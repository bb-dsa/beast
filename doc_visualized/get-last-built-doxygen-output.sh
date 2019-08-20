echo "Removing a previous build dir, if it exists..."
rm -rf build
mkdir build
echo "Attempting to copy the Doxygen output from the last 'doc' build; you likely will need to modify my hard-coded source directory..."
cp ../../../bin.v2/libs/beast/doc/msvc-14.2/debug/threadapi-win32/threading-multi/*.xml build
