#!/bin/bash

echo "Copying docca XSLT files..." && \
cp ../doc/docca/include/docca/* build && \

echo "Copying shell scripts..." && \
cp extract-xml-pages.sh \
   assemble-quickbook.sh \
   transform-without-visualizations.sh \
build && \

cd build && \

echo "Calling extract-xml-pages.sh..." && \
./extract-xml-pages.sh && \

echo "Running transform-without-visualizations.sh..." && \
./transform-without-visualizations.sh && \

echo "Calling assemble-quickbook.sh..." && \
./assemble-quickbook.sh stage2 && \

echo "Calling the Beast build to run the Quickbook -> BoostBook -> DocBook -> HTML conversion..." && \
cd .. && \
../../../b2.exe
