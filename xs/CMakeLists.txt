set(CMAKE_CXX_STANDARD 11) # Enable c++11 language standard
list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake/modules/) # Add our own cmake module path

# Bring back SLIC3R_DYNAMIC logic from Build.PL
if (DEFINED SLIC3R_DYNAMIC AND NOT SLIC3R_DYNAMIC)
    set(SLIC3R_STATIC 1)
endif ()

# Bring back SLIC3R_NOGUI logic from Build.PL
if (DEFINED SLIC3R_NOGUI AND NOT SLIC3R_NOGUI)
    set(SLIC3R_GUI 0)
else ()
    set(SLIC3R_GUI 1)
endif ()


# Generate XS typemap file
find_package(Perl REQUIRED)
set(MyTypemap ${CMAKE_CURRENT_BINARY_DIR}/typemap)
add_custom_command(
        OUTPUT ${MyTypemap}
        COMMAND ${PERL_EXECUTABLE} -MExtUtils::Typemaps -MExtUtils::Typemaps::Basic -e "$typemap = ExtUtils::Typemaps->new(file => \"${CMAKE_CURRENT_LIST_DIR}/xsp/my.map\"); $typemap->merge(typemap => ExtUtils::Typemaps::Basic->new); $typemap->write(file => \"${MyTypemap}\")"
        VERBATIM
)

# Generate main.xs file
set(MyMainXs ${CMAKE_CURRENT_BINARY_DIR}/main.xs)
file(GLOB files xsp/*.xsp)
foreach (file ${files})
    set(INCLUDE_COMMANDS "${INCLUDE_COMMANDS}INCLUDE_COMMAND: $^X -MExtUtils::XSpp::Cmd -e xspp -- -t \"${CMAKE_CURRENT_LIST_DIR}/xsp/typemap.xspt\" \"${file}\"\n")
endforeach ()
configure_file(main.xs.in ${MyMainXs} @ONLY) # Insert INCLUDE_COMMANDS into main.xs

# Generate XS.cpp file
set(MyXsC "${CMAKE_CURRENT_BINARY_DIR}/XS.cpp")
add_custom_command(
        OUTPUT ${MyXsC}
        DEPENDS ${MyTemplate} ${MyTypemap}
        COMMAND COMMAND xsubpp -typemap typemap -output ${MyXsC} -hiertype ${MyMainXs}
)

# Find and define all source files
file(GLOB MySrc src/*.cpp)
file(GLOB MyAdmesh src/admesh/*.c)
SET_SOURCE_FILES_PROPERTIES(${MyAdmesh} PROPERTIES LANGUAGE CXX) # admesh has C++ syntax in it's source but the files are *.c

file(GLOB MyGuiSrc src/slic3r/GUI/*.cpp)
file(GLOB_RECURSE MyLibSlic3rSrc src/libslic3r/*.cpp)
file(GLOB_RECURSE MyPoly2TriSrc src/poly2tri/*.cc)
file(GLOB MyShinySrc src/Shiny/*.c)

# Define target file
if (SLIC3R_STATIC)
    add_library(XS STATIC ${MyXsC} ${MySrc} ${MyAdmesh} ${MyGuiSrc} ${MyLibSlic3rSrc} ${MyPoly2TriSrc} ${MyShinySrc})
else ()
    add_library(XS SHARED ${MyXsC} ${MySrc} ${MyAdmesh} ${MyGuiSrc} ${MyLibSlic3rSrc} ${MyPoly2TriSrc} ${MyShinySrc})
endif ()

target_include_directories(XS PRIVATE src src/libslic3r) # Local include directories
target_compile_definitions(XS PRIVATE -DSLIC3RXS)
set_target_properties(XS PROPERTIES PREFIX "") # Prevent cmake from generating libXS.so instead of XS.so

# Windows specific stuff
if (WIN32)
    target_compile_definitions(XS PRIVATE -D_USE_MATH_DEFINES -DNOGDI -DNOMINMAX -D_WIN32 -DHAS_BOOL)
endif ()

## Configuration flags
if (SLIC3R_GUI)
    message("Slic3r will be built with GUI support")
    target_compile_definitions(XS PRIVATE -DSLIC3R_GUI)
endif ()

if (SLIC3R_PROFILE)
    message("Slic3r will be built with a Shiny invasive profiler")
    target_compile_definitions(XS PRIVATE -DSLIC3R_PROFILE)
endif ()

if (SLIC3R_HAS_BROKEN_CROAK)
    target_compile_definitions(XS PRIVATE -DSLIC3R_HAS_BROKEN_CROAK)
endif ()

if (CMAKE_BUILD_TYPE MATCHES DEBUG)
    target_compile_definitions(XS PRIVATE -DSLIC3R_DEBUG)
else ()
    target_compile_definitions(XS PRIVATE -DNDEBUG)
endif ()

# Perl specific stuff
find_package(PerlLibs REQUIRED)
target_include_directories(XS PRIVATE ${PERL_INCLUDE_PATH})

## REQUIRED packages

# Find and configure boost
find_package(Boost REQUIRED COMPONENTS system filesystem thread log)
if (Boost_FOUND)
    include_directories(${Boost_INCLUDE_DIRS})
    target_link_libraries(XS ${Boost_LIBRARIES})
    target_compile_definitions(XS PRIVATE -DBOOST_ASIO_DISABLE_KQUEUE -DBOOST_LIBS)
    if (NOT SLIC3R_STATIC)
        target_compile_definitions(XS PRIVATE -DBOOST_LOG_DYN_LINK)
    endif ()
endif ()

# Find and configure intel-tbb
find_package(TBB REQUIRED)
if (TBB_FOUND)
    include_directories(${TBB_INCLUDE_DIRS})
    add_definitions(${TBB_DEFINITIONS})
    target_link_libraries(XS ${TBB_LIBRARIES})
endif ()

# Find and configure wxWidgets
find_package(wxWidgets REQUIRED)
if (wxWidgets_FOUND)
    include(${wxWidgets_USE_FILE})
    target_link_libraries(XS ${wxWidgets_LIBRARIES})
endif ()

## OPTIONAL packages

# Find eigen3 or use bundled version
find_package(Eigen3)
if (Eigen3_FOUND AND NOT SLIC3R_STATIC)
    include_directories(${EIGEN3_INCLUDE_DIR})
else ()
    include_directories(src/eigen)
endif ()

# Find expat or use bundled version
find_package(EXPAT)
if (EXPAT_FOUND AND NOT SLIC3R_STATIC)
    include_directories(${EXPAT_INCLUDE_DIRS})
    target_link_libraries(XS ${EXPAT_LIBRARIES})
else ()
    file(GLOB MyExpat src/expat/*.c)
    target_sources(XS PRIVATE ${MyExpat})
endif ()

# Find glew or use bundled version
find_package(GLEW)
if (GLEW_FOUND AND NOT SLIC3R_STATIC)
    include_directories(${GLEW_INCLUDE_DIRS})
    target_link_libraries(XS ${GLEW_LIBRARIES})
else ()
    file(GLOB MyGlew src/glew/src/*.c)
    include_directories(src/glew/include)
    target_sources(XS PRIVATE ${MyGlew})
    target_compile_definitions(XS PRIVATE -DGLEW_STATIC)
endif ()

# Installation
install(TARGETS XS DESTINATION lib/slic3r/auto/Slic3r)
install(FILES lib/Slic3r/XS.pm DESTINATION slic3r/Slic3r/XS.pm)
