set (CMAKE_CXX_STANDARD 11)

list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake/modules/)


find_package(Perl)
set(MyTypemap ${CMAKE_CURRENT_BINARY_DIR}/typemap)
add_custom_command(
        OUTPUT ${MyTypemap}
        COMMAND ${PERL_EXECUTABLE} -MExtUtils::Typemaps -MExtUtils::Typemaps::Basic -e "$typemap = ExtUtils::Typemaps->new(file => \"${CMAKE_CURRENT_LIST_DIR}/xsp/my.map\"); $typemap->merge(typemap => ExtUtils::Typemaps::Basic->new); $typemap->write(file => \"${MyTypemap}\")"
        VERBATIM
)

set(MyTemplate ${CMAKE_CURRENT_BINARY_DIR}/template.xs)
file(GLOB files xsp/*.xsp)
foreach (file ${files})
    set(INCLUDE_COMMANDS "${INCLUDE_COMMANDS}INCLUDE_COMMAND: $^X -MExtUtils::XSpp::Cmd -e xspp -- -t \"${CMAKE_CURRENT_LIST_DIR}/xsp/typemap.xspt\" \"${file}\"\n")
endforeach ()
configure_file(template.xs.in ${MyTemplate} @ONLY)

set(MyXsC "${CMAKE_CURRENT_BINARY_DIR}/XS.cpp")
add_custom_command(
        OUTPUT ${MyXsC}
        DEPENDS ${MyTemplate} ${MyTypemap}
        COMMAND COMMAND xsubpp -typemap typemap -output ${MyXsC} -hiertype ${MyTemplate}
)

file(GLOB MySrc src/*.cpp)
file(GLOB MyAdmesh src/admesh/*.c)
SET_SOURCE_FILES_PROPERTIES(${MyAdmesh} PROPERTIES LANGUAGE CXX)

file(GLOB MyGuiSrc src/slic3r/GUI/*.cpp)
file(GLOB_RECURSE MyLibSlic3rSrc src/libslic3r/*.cpp)
file(GLOB_RECURSE MyPoly2TriSrc src/poly2tri/*.cc)
file(GLOB MyShinySrc src/Shiny/*.c)

add_library(XS SHARED ${MyXsC} ${MySrc} ${MyAdmesh} ${MyGuiSrc} ${MyLibSlic3rSrc} ${MyPoly2TriSrc} ${MyShinySrc})

find_package(PerlLibs)
target_include_directories(XS PRIVATE ${PERL_INCLUDE_PATH} src src/libslic3r )

target_compile_definitions(XS PRIVATE -DSLIC3RXS -DBOOST_ASIO_DISABLE_KQUEUE -DSLIC3R_GUI -DSLIC3R_PRUS -DBOOST_LOG_DYN_LINK -DBOOST_LIBS -DNDEBUG -D_USE_MATH_DEFINES)
set_target_properties(XS PROPERTIES PREFIX "")

find_package(wxWidgets REQUIRED)
if (wxWidgets_FOUND)
    include(${wxWidgets_USE_FILE})
    target_link_libraries(XS ${wxWidgets_LIBRARIES})
endif ()

find_package(Eigen3)
if (Eigen3_FOUND)
    include_directories(${EIGEN3_INCLUDE_DIR})
else ()
    include_directories(src/eigen)
endif ()

find_package(TBB REQUIRED)
if (TBB_FOUND)
    include_directories(${TBB_INCLUDE_DIRS})
    add_definitions(${TBB_DEFINITIONS})
    target_link_libraries(XS ${TBB_LIBRARIES})
endif ()

find_package(EXPAT)
if (EXPAT_FOUND)
    include_directories(${EXPAT_INCLUDE_DIRS})
    target_link_libraries(XS ${EXPAT_LIBRARIES})
else ()
    file(GLOB MyExpat src/expat/*.c)
    target_sources(XS PRIVATE ${MyExpat})
endif ()

find_package(Boost REQUIRED)
if (Boost_FOUND)
    include_directories(${Boost_INCLUDE_DIRS})
    target_link_libraries(XS ${Boost_LIBRARIES})
endif ()

find_package(GLEW)
if (GLEW_FOUND)
    include_directories(${GLEW_INCLUDE_DIRS})
    target_link_libraries(XS ${GLEW_LIBRARIES})
else ()
    file(GLOB MyGlew src/glew/src/*.c)
	include_directories(src/glew/include)
    target_sources(XS PRIVATE ${MyGlew})
endif ()

install(TARGETS XS DESTINATION lib/slic3r-prusa3d/auto/Slic3r)
install(FILES lib/Slic3r/XS.pm DESTINATION slic3r-prusa3d/Slic3r/XS.pm)