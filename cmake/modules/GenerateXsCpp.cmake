file(READ ../../xs/template.xs MyTemplate)

find_package(Perl)
execute_process(COMMAND ${PERL_EXECUTABLE} -MExtUtils::Typemaps -MExtUtils::Typemaps::Basic -e "\$typemap = ExtUtils::Typemaps->new(file => \"${CMAKE_CURRENT_BINARY_DIR}/../../xs/xsp/my.map\"); \$typemap->merge(typemap => ExtUtils::Typemaps::Basic->new); \$typemap->write(file => \"typemap\")")
file(WRITE main.xs ${MyTemplate})

file(GLOB files ../../xs/xsp/*.xsp)
foreach (file ${files})
    file(APPEND main.xs "INCLUDE_COMMAND: $^X -MExtUtils::XSpp::Cmd -e xspp -- -t \"${CMAKE_CURRENT_BINARY_DIR}/../../xs/xsp/typemap.xspt\" \"${file}\"\n")
endforeach ()
execute_process(COMMAND xsubpp -typemap ${CMAKE_CURRENT_BINARY_DIR}/typemap -output ${CMAKE_CURRENT_BINARY_DIR}/XS.cpp -hiertype main.xs)
