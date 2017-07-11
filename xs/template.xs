#include <cstring>
#include <cstdlib>
#include <ostream>
#include <sstream>
#include <libslic3r/GCodeSender.hpp>

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#undef do_open
#undef do_close
#ifdef __cplusplus
}
#endif

MODULE = Slic3r::XS	PACKAGE = Slic3r::XS

