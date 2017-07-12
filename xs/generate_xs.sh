#!/bin/bash
CMAKE_CURRENT_LISTS_DIR=$1
CMAKE_CURRENT_BINARY_DIR=$2
perl -MExtUtils::Typemaps -MExtUtils::Typemaps::Basic -e "\$typemap = ExtUtils::Typemaps->new(file => \"${CMAKE_CURRENT_LISTS_DIR}/xsp/my.map\"); \$typemap->merge(typemap => ExtUtils::Typemaps::Basic->new); \$typemap->write(file => \"typemap\")"
cat ${CMAKE_CURRENT_LISTS_DIR}/template.xs > main.xs
for file in ${CMAKE_CURRENT_LISTS_DIR}/xsp/*.xsp; do
  echo "INCLUDE_COMMAND: $^X -MExtUtils::XSpp::Cmd -e xspp -- -t \"${CMAKE_CURRENT_LISTS_DIR}/xsp/typemap.xspt\" \"$file\"" >> main.xs
done
xsubpp -typemap typemap -output ${CMAKE_CURRENT_BINARY_DIR}/XS.cpp -hiertype main.xs
rm typemap main.xs