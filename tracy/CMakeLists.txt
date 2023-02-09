cmake_minimum_required(VERSION 3.0)

if(POLICY CMP0077)
    cmake_policy(SET CMP0077 NEW) # Enables override of options from parent CMakeLists.txt
endif()

if(POLICY CMP0091)
    cmake_policy(SET CMP0091 NEW) # Enables use of MSVC_RUNTIME_LIBRARY
endif()

if(POLICY CMP0092)
    cmake_policy(SET CMP0092 NEW) # Enables clean /W4 override for MSVC
endif()

project(tracy VERSION 0.16 LANGUAGES CXX)

option(TRACY_BUILD_SHARED_LIBS "Build shared libraries" OFF)

set(SOURCES
	Tracy.hpp
	TracyOpenGL.hpp
	TracyClient.cpp
)

if(MSVC)
    add_compile_options(/W4 /WX)
	
	# Make tracy minimally promiscuous - local profiling only
	add_compile_definitions(TRACY_ENABLE TRACY_NO_BROADCAST TRACY_ONLY_LOCALHOST TRACY_ONLY_IPV4)
else()
	add_compile_definitions(TRACY_ENABLE TRACY_NO_BROADCAST TRACY_ONLY_LOCALHOST TRACY_ONLY_IPV4)
	add_compile_options(-std=c++11 -Wall -Wextra -Wno-missing-field-initializers -Wno-unused-parameter -Werror)
endif()

if(TRACY_BUILD_SHARED_LIBS)
    add_library(tracy SHARED ${SOURCES})
else()
    add_library(tracy STATIC ${SOURCES})
endif()

target_include_directories(tracy INTERFACE "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/common:${CMAKE_CURRENT_SOURCE_DIR}/client>")

if(TRACY_BUILD_SHARED_LIBS)
    set_target_properties(tracy PROPERTIES CXX_VISIBILITY_PRESET hidden)
    set_target_properties(tracy PROPERTIES VISIBILITY_INLINES_HIDDEN ON)

    if(WIN32)
        target_compile_definitions(tracy INTERFACE "TRACY_API=__declspec(dllimport)")
        target_compile_definitions(tracy PRIVATE "TRACY_API=__declspec(dllexport)")
    else()
        target_compile_definitions(tracy PUBLIC "TRACY_API=__attribute__((visibility(\"default\")))")
    endif()
endif()

set(TARGETS tracy)

include(GNUInstallDirs)

install(TARGETS ${TARGETS} EXPORT tracyTargets
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

install(FILES Tracy.hpp DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
install(EXPORT tracyTargets DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/tracy NAMESPACE tracy::)

include(CMakePackageConfigHelpers)

write_basic_package_version_file(${CMAKE_CURRENT_BINARY_DIR}/tracyConfigVersion.cmake COMPATIBILITY ExactVersion)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/tracyConfig.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/tracyConfigVersion.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/tracy)
