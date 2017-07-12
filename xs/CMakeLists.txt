list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake/modules/)

set(MyXsC "${CMAKE_CURRENT_BINARY_DIR}/XS.cpp")
add_custom_command(
        OUTPUT ${MyXsC}
        DEPENDS xsp/*.xsp
        BYPRODUCTS ${CMAKE_CURRENT_BINARY_DIR}/main.xs ${CMAKE_CURRENT_BINARY_DIR}/typemap
        COMMAND ${CMAKE_COMMAND} -P ${PROJECT_SOURCE_DIR}/cmake/modules/GenerateXsCpp.cmake
)

file(GLOB MySrc src/*.cpp)
file(GLOB MyAdmesh src/admesh/*.c)
SET_SOURCE_FILES_PROPERTIES(${MyAdmesh} PROPERTIES LANGUAGE CXX)

file(GLOB MyGuiSrc src/slic3r/GUI/*.cpp)
file(GLOB_RECURSE MyLibSlic3rSrc src/libslic3r/*.cpp)
file(GLOB_RECURSE MyPoly2TriSrc src/poly2tri/*.cc)
file(GLOB MyShinySrc src/Shiny/*.c)

add_library(XS SHARED ${MyXsC} ${MySrc} ${MyAdmesh} ${MyGuiSrc} ${MyLibSlic3rSrc} ${MyPoly2TriSrc} ${MyShinySrc})
target_include_directories(XS PRIVATE src src/libslic3r /usr/lib/perl5/core_perl/CORE)
target_compile_definitions(XS PRIVATE -DSLIC3RXS -DBOOST_ASIO_DISABLE_KQUEUE -DSLIC3R_GUI -DSLIC3R_PRUS -DBOOST_LOG_DYN_LINK -DBOOST_LIBS -DNDEBUG)
set_target_properties(XS PROPERTIES PREFIX "")

find_package(wxWidgets REQUIRED)
if (wxWidgets_FOUND)
    include(${wxWidgets_USE_FILE})
    target_link_libraries(XS ${wxWidgets_LIBRARIES})
endif ()

find_package(Eigen3 REQUIRED)
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

find_package(EXPAT REQUIRED)
if (EXPAT_FOUND)
    include_directories(${EXPAT_INCLUDE_DIRS})
    target_link_libraries(XS ${EXPAT_LIBRARIES})
else ()
    file(GLOB MyExpat src/expat/*.c)
    target_sources(XS PRIVATE ${MyExpat})
endif ()

find_package(Boost REQUIRED COMPONENTS system filesystem thread log)
if (Boost_FOUND)
    include_directories(${Boost_INCLUDE_DIRS})
    target_link_libraries(XS ${Boost_LIBRARIES})
endif ()

find_package(GLEW REQUIRED)
if (GLEW_FOUND)
    include_directories(${GLEW_INCLUDE_DIRS})
    target_link_libraries(XS ${GLEW_LIBRARIES})
else ()
    file(GLOB MyGlew src/glew/src/*.c)
    target_sources(XS PRIVATE ${MyGlew})
endif ()

install(TARGETS XS DESTINATION lib/slic3r-prusa3d/auto/Slic3r)
install(FILES lib/Slic3r/XS.pm DESTINATION slic3r-prusa3d/Slic3r/XS.pm)