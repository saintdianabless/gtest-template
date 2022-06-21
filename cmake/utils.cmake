# COPY FROM OFFICAL GOOGLETEST REPO
# CHECK https://github.com/google/googletest/blob/main/googletest/cmake/internal_utils.cmake

# Defines the gtest & gtest_main libraries.  User tests should link
# with one of them.
function(cxx_library_with_type name type cxx_flags)
  # type can be either STATIC or SHARED to denote a static or shared library.
  # ARGN refers to additional arguments after 'cxx_flags'.
  add_library(${name} ${type} ${ARGN})
  add_library(${cmake_package_name}::${name} ALIAS ${name})
  set_target_properties(${name}
    PROPERTIES
    COMPILE_FLAGS "${cxx_flags}")
  # Set the output directory for build artifacts
  set_target_properties(${name}
    PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
    PDB_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
  # make PDBs match library name
  get_target_property(pdb_debug_postfix ${name} DEBUG_POSTFIX)
  set_target_properties(${name}
    PROPERTIES
    PDB_NAME "${name}"
    PDB_NAME_DEBUG "${name}${pdb_debug_postfix}"
    COMPILE_PDB_NAME "${name}"
    COMPILE_PDB_NAME_DEBUG "${name}${pdb_debug_postfix}")

  if (BUILD_SHARED_LIBS OR type STREQUAL "SHARED")
    set_target_properties(${name}
      PROPERTIES
      COMPILE_DEFINITIONS "GTEST_CREATE_SHARED_LIBRARY=1")
    if (NOT "${CMAKE_VERSION}" VERSION_LESS "2.8.11")
      target_compile_definitions(${name} INTERFACE
        $<INSTALL_INTERFACE:GTEST_LINKED_AS_SHARED_LIBRARY=1>)
    endif()
  endif()
  if (DEFINED GTEST_HAS_PTHREAD)
    if ("${CMAKE_VERSION}" VERSION_LESS "3.1.0")
      set(threads_spec ${CMAKE_THREAD_LIBS_INIT})
    else()
      set(threads_spec Threads::Threads)
    endif()
    target_link_libraries(${name} PUBLIC ${threads_spec})
  endif()

  if (NOT "${CMAKE_VERSION}" VERSION_LESS "3.8")
    target_compile_features(${name} PUBLIC cxx_std_11)
  endif()
endfunction()

########################################################################
#
# Helper functions for creating build targets.

function(cxx_shared_library name cxx_flags)
  cxx_library_with_type(${name} SHARED "${cxx_flags}" ${ARGN})
endfunction()

function(cxx_library name cxx_flags)
  cxx_library_with_type(${name} "" "${cxx_flags}" ${ARGN})
endfunction()

# cxx_executable_with_flags(name cxx_flags libs srcs...)
#
# creates a named C++ executable that depends on the given libraries and
# is built from the given source files with the given compiler flags.
function(cxx_executable_with_flags name cxx_flags libs)
  add_executable(${name} ${ARGN})
  if (MSVC)
    # BigObj required for tests.
    set(cxx_flags "${cxx_flags} -bigobj")
  endif()
  if (cxx_flags)
    set_target_properties(${name}
      PROPERTIES
      COMPILE_FLAGS "${cxx_flags}")
  endif()
  if (BUILD_SHARED_LIBS)
    set_target_properties(${name}
      PROPERTIES
      COMPILE_DEFINITIONS "GTEST_LINKED_AS_SHARED_LIBRARY=1")
  endif()
  # To support mixing linking in static and dynamic libraries, link each
  # library in with an extra call to target_link_libraries.
  foreach (lib "${libs}")
    target_link_libraries(${name} ${lib})
  endforeach()
endfunction()

# cxx_executable(name dir lib srcs...)
#
# creates a named target that depends on the given libs and is built
# from the given source files.  dir/name.cc is implicitly included in
# the source file list.
function(cxx_executable name dir libs)
  cxx_executable_with_flags(
    ${name} "${cxx_default}" "${libs}" "${dir}/${name}.cc" ${ARGN})
endfunction()

# cxx_test_with_flags(name cxx_flags libs srcs...)
#
# creates a named C++ test that depends on the given libs and is built
# from the given source files with the given compiler flags.
function(cxx_test_with_flags name cxx_flags libs)
  cxx_executable_with_flags(${name} "${cxx_flags}" "${libs}" ${ARGN})
    add_test(NAME ${name} COMMAND "$<TARGET_FILE:${name}>")
endfunction()

# cxx_test(name libs srcs...)
#
# creates a named test target that depends on the given libs and is
# built from the given source files.  Unlike cxx_test_with_flags,
# test/name.cc is already implicitly included in the source file list.
function(cxx_test name libs)
  cxx_test_with_flags("${name}" "${cxx_default}" "${libs}"
    "test/${name}.cc" ${ARGN})
endfunction()