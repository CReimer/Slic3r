cmake_minimum_required(VERSION 2.6)
project(Slic3r)
add_subdirectory(xs)

install(PROGRAMS slic3r.pl DESTINATION bin RENAME slic3r-prusa3d)

file(GLOB MyVar var/*.png)
install(FILES ${MyVar} DESTINATION share/slic3r-prusa3d)
install(FILES lib/Slic3r.pm DESTINATION lib/slic3r-prusa3d)
install(DIRECTORY lib/Slic3r DESTINATION lib/slic3r-prusa3d)