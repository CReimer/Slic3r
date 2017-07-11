CXX      ?= g++
CXXFLAGS ?= -O3 -fPIC -std=c++11 -pipe -fstack-protector-strong
CPPFLAGS ?= -D_FORTIFY_SOURCE=2
LDFLAGS  ?= -Wl,-O1,--sort-common,--as-needed,-z,relro

rwildcard=$(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))

CPP_FILES=$(wildcard src/*.cpp)
GUI_FILES=$(wildcard src/slic3r/GUI/*.cpp)
LIBSLIC3R_FILES=$(call rwildcard, src/libslic3r, *.cpp)
POLY2TRI_FILES=$(call rwildcard, src/poly2tri, *.cc)
SHINY_FILES=$(wildcard src/Shiny/*.c)
OBJS=buildtmp/XS.o \
  $(CPP_FILES:.cpp=.o) \
  $(GUI_FILES:.cpp=.o) \
  $(LIBSLIC3R_FILES:.cpp=.o) \
  $(POLY2TRI_FILES:.cc=.o) \
  $(SHINY_FILES:.c=.o)

INCLUDES= -Isrc/libslic3r -Isrc -I/usr/lib/perl5/core_perl/CORE

DEFINES= -DSLIC3RXS -DBOOST_ASIO_DISABLE_KQUEUE -DSLIC3R_GUI -DSLIC3R_PRUS -DBOOST_LOG_DYN_LINK -DBOOST_LIBS -DNDEBUG 
LIBS= -lstdc++ -Lsrc/libslic3r -lboost_system -lboost_thread -lboost_log -ltbb

CXXFLAGS +=$(shell pkg-config --cflags glew eigen3 expat libadmesh) $(shell wx-config --cflags)
LIBS+= $(shell pkg-config --libs glew eigen3 expat libadmesh) $(shell wx-config --libs)

SOFILE = XS.so

XSP    = $(wildcard xsp/*.xsp)
XSPT   = xsp/typemap.xspt
MYMAP  = xsp/my.map

### Main target
all: $(SOFILE)

### Implicit rules
%.o: %.cpp
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $(DEFINES) $(INCLUDES) -o $@ $<

%.o: %.cc
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $(DEFINES) $(INCLUDES) -o $@ $<

%.o: %.c
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $(DEFINES) $(INCLUDES) -o $@ $<

### Targets
$(SOFILE): $(OBJS)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -shared $(OBJS) $(LIBS) -o $@

buildtmp/typemap: $(MYMAP)
	@mkdir -p buildtmp
	perl -MExtUtils::Typemaps -MExtUtils::Typemaps::Basic -e '$$typemap = ExtUtils::Typemaps->new(file => "$<"); $$typemap->merge(typemap => ExtUtils::Typemaps::Basic->new); $$typemap->write(file => "$@")'

buildtmp/XS.c: $(XSP) $(XSPT) buildtmp/typemap
	@mkdir -p buildtmp
	@cat template.xs > buildtmp/main.xs;\
	for file in $(XSP); do\
	  echo "INCLUDE_COMMAND: $$^X -MExtUtils::XSpp::Cmd -e xspp -- -t \"$$PWD/$(XSPT)\"  \"$$PWD/$$file\"" >> buildtmp/main.xs;\
	done
	xsubpp -typemap typemap -output $@ -hiertype buildtmp/main.xs 

.PHONY: clean

clean:
	@-rm -rf buildtmp
	@-rm -f $(OBJS)
