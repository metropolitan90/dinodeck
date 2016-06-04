
#=============================================================================
# Copyright 2002-2009 Kitware, Inc.
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
# (To distribute this file outside of CMake, substitute the full
#  License text for the above reference.)

# This module is shared by multiple languages; use include blocker.
if(__WINDOWS_GNU)
  return()
endif()
set(__WINDOWS_GNU 1)

set(CMAKE_IMPORT_LIBRARY_PREFIX "lib")
set(CMAKE_SHARED_LIBRARY_PREFIX "lib")
set(CMAKE_SHARED_MODULE_PREFIX  "lib")
set(CMAKE_STATIC_LIBRARY_PREFIX "lib")

set(CMAKE_EXECUTABLE_SUFFIX     ".exe")
set(CMAKE_IMPORT_LIBRARY_SUFFIX ".dll.a")
set(CMAKE_SHARED_LIBRARY_SUFFIX ".dll")
set(CMAKE_SHARED_MODULE_SUFFIX  ".dll")
set(CMAKE_STATIC_LIBRARY_SUFFIX ".a")

if(MSYS OR MINGW)
  set(CMAKE_EXTRA_LINK_EXTENSIONS ".lib") # MinGW can also link to a MS .lib
endif()

if(MINGW)
  set(CMAKE_FIND_LIBRARY_PREFIXES "lib" "")
  set(CMAKE_FIND_LIBRARY_SUFFIXES ".dll" ".dll.a" ".a" ".lib")
  set(CMAKE_C_STANDARD_LIBRARIES_INIT "-lkernel32 -luser32 -lgdi32 -lwinspool -lshell32 -lole32 -loleaut32 -luuid -lcomdlg32 -ladvapi32")
  set(CMAKE_CXX_STANDARD_LIBRARIES_INIT "${CMAKE_C_STANDARD_LIBRARIES_INIT}")
endif()

set(CMAKE_DL_LIBS "")
set(CMAKE_LIBRARY_PATH_FLAG "-L")
set(CMAKE_LINK_LIBRARY_FLAG "-l")
set(CMAKE_LINK_LIBRARY_SUFFIX "")
set(CMAKE_CREATE_WIN32_EXE  "-mwindows")

set(CMAKE_GNULD_IMAGE_VERSION
  "-Wl,--major-image-version,<TARGET_VERSION_MAJOR>,--minor-image-version,<TARGET_VERSION_MINOR>")

# Check if GNU ld is too old to support @FILE syntax.
set(__WINDOWS_GNU_LD_RESPONSE 1)
execute_process(COMMAND ld -v OUTPUT_VARIABLE _help ERROR_VARIABLE _help)
if("${_help}" MATCHES "GNU ld .* 2\\.1[1-6]")
  set(__WINDOWS_GNU_LD_RESPONSE 0)
endif()

macro(__windows_compiler_gnu lang)

  if(MSYS OR MINGW)
    # Create archiving rules to support large object file lists for static libraries.
    set(CMAKE_${lang}_ARCHIVE_CREATE "<CMAKE_AR> cr <TARGET> <LINK_FLAGS> <OBJECTS>")
    set(CMAKE_${lang}_ARCHIVE_APPEND "<CMAKE_AR> r  <TARGET> <LINK_FLAGS> <OBJECTS>")
    set(CMAKE_${lang}_ARCHIVE_FINISH "<CMAKE_RANLIB> <TARGET>")

    # Initialize C link type selection flags.  These flags are used when
    # building a shared library, shared module, or executable that links
    # to other libraries to select whether to use the static or shared
    # versions of the libraries.
    foreach(type SHARED_LIBRARY SHARED_MODULE EXE)
      set(CMAKE_${type}_LINK_STATIC_${lang}_FLAGS "-Wl,-Bstatic")
      set(CMAKE_${type}_LINK_DYNAMIC_${lang}_FLAGS "-Wl,-Bdynamic")
    endforeach(type)
  endif()

  set(CMAKE_SHARED_LIBRARY_${lang}_FLAGS "") # No -fPIC on Windows
  set(CMAKE_${lang}_USE_RESPONSE_FILE_FOR_OBJECTS ${__WINDOWS_GNU_LD_RESPONSE})

  # We prefer "@" for response files but it is not supported by gcc 3.
  execute_process(COMMAND ${CMAKE_${lang}_COMPILER} --version OUTPUT_VARIABLE _ver ERROR_VARIABLE _ver)
  if("${_ver}" MATCHES "\\(GCC\\) 3\\.")
    if("${lang}" STREQUAL "Fortran")
      # The GNU Fortran compiler reports an error:
      #   no input files; unwilling to write output files
      # when the response file is passed with "-Wl,@".
      set(CMAKE_Fortran_USE_RESPONSE_FILE_FOR_OBJECTS 0)
    else()
      # Use "-Wl,@" to pass the response file to the linker.
      set(CMAKE_${lang}_RESPONSE_FILE_LINK_FLAG "-Wl,@")
    endif()
  elseif(CMAKE_${lang}_USE_RESPONSE_FILE_FOR_OBJECTS)
    # Use "@" to pass the response file to the front-end.
    set(CMAKE_${lang}_RESPONSE_FILE_LINK_FLAG "@")
  endif()

  # Binary link rules.
  set(CMAKE_${lang}_CREATE_SHARED_MODULE
    "<CMAKE_${lang}_COMPILER> <CMAKE_SHARED_MODULE_${lang}_FLAGS> <LINK_FLAGS> <CMAKE_SHARED_MODULE_CREATE_${lang}_FLAGS> -o <TARGET> ${CMAKE_GNULD_IMAGE_VERSION} <OBJECTS> <LINK_LIBRARIES>")
  set(CMAKE_${lang}_CREATE_SHARED_LIBRARY
    "<CMAKE_${lang}_COMPILER> <CMAKE_SHARED_LIBRARY_${lang}_FLAGS> <LINK_FLAGS> <CMAKE_SHARED_LIBRARY_CREATE_${lang}_FLAGS> -o <TARGET> -Wl,--out-implib,<TARGET_IMPLIB> ${CMAKE_GNULD_IMAGE_VERSION} <OBJECTS> <LINK_LIBRARIES>")
  set(CMAKE_${lang}_LINK_EXECUTABLE
    "<CMAKE_${lang}_COMPILER> <FLAGS> <CMAKE_${lang}_LINK_FLAGS> <LINK_FLAGS> <OBJECTS>  -o <TARGET> -Wl,--out-implib,<TARGET_IMPLIB> ${CMAKE_GNULD_IMAGE_VERSION} <LINK_LIBRARIES>")

  # Support very long lists of object files.
  if("${CMAKE_${lang}_RESPONSE_FILE_LINK_FLAG}" STREQUAL "@")
    foreach(rule CREATE_SHARED_MODULE CREATE_SHARED_LIBRARY LINK_EXECUTABLE)
      # The gcc/collect2/ld toolchain does not use response files
      # internally so we cannot pass long object lists.  Instead pass
      # the object file list in a response file to the archiver to put
      # them in a temporary archive.  Hand the archive to the linker.
      string(REPLACE "<OBJECTS>" "-Wl,--whole-archive <OBJECT_DIR>/objects.a -Wl,--no-whole-archive"
        CMAKE_${lang}_${rule} "${CMAKE_${lang}_${rule}}")
      set(CMAKE_${lang}_${rule}
        "<CMAKE_COMMAND> -E remove -f <OBJECT_DIR>/objects.a"
        "<CMAKE_AR> cr <OBJECT_DIR>/objects.a <OBJECTS>"
        "${CMAKE_${lang}_${rule}}"
        )
    endforeach()
  endif()
endmacro()
