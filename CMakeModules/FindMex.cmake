if (NOT $ENV{MATLAB_ROOT} STREQUAL "")
    set(MATLAB_ROOT $ENV{MATLAB_ROOT})
endif()
if (MATLAB_ROOT)
    set(MATLAB_BINDIR ${MATLAB_ROOT}/bin)
endif()
# search for matlab in PATH
find_program(MATLAB matlab ${MATLAB_BINDIR})
# Yes! found it
if (MATLAB)
   if (NOT MATLAB_BINDIR)
       get_filename_component(MATLAB_BINDIR ${MATLAB} PATH)
   endif()
   if (WIN32)
       set(MEX_COMMAND ${MATLAB_BINDIR}/mex.bat)
       set(MEXEXT_COMMAND ${MATLAB_BINDIR}/mexext.bat)
   else (WIN32)
       set(MEX_COMMAND ${MATLAB_BINDIR}/mex)
       set(MEXEXT_COMMAND ${MATLAB_BINDIR}/mexext)
   endif (WIN32)
   if (EXISTS ${MEX_COMMAND})
      message (STATUS "mex (Matlab) found : " ${MEX_COMMAND})
      set(MEX_FOUND MATLAB)
   endif(EXISTS ${MEX_COMMAND})
   execute_process(COMMAND ${MEXEXT_COMMAND} OUTPUT_VARIABLE MEX_EXT  OUTPUT_STRIP_TRAILING_WHITESPACE)
   message(STATUS "mex extension on this machine :" ${MEX_EXT})
   set(MATLAB_COMMAND "matlab")
   set(MATLAB_FLAGS -nojvm)
   if ("${MEX_EXT}" MATCHES ".*64.*")
	   set(MATLAB_ARCH x64)
	   message(STATUS "Matlab 64-bit architecture!")
	   set(MEX_OPT -largeArrayDims)
   else("${MEX_EXT}" MATCHES ".*64.*")
	   set(MATLAB_ARCH i386)
   endif("${MEX_EXT}" MATCHES ".*64.*")
# We did not find matlab
else(MATLAB)
  # try with octave	
  find_program(MKOCT mkoctfile)
  if(MKOCT)
    message (STATUS "mex (Octave) found : " ${MKOCT})
    set(MEX_FOUND OCTAVE)
    set(MEX_COMMAND ${MKOCT} --mex)
    set(MEX_EXT mex)
    find_program(OCTAVE "octave")
    if (OCTAVE)
      set(MATLAB_COMMAND "${OCTAVE}")
      set(MATLAB_FLAGS --traditional)
    endif(OCTAVE)	    
  else(MKOCT)
    message(FATAL_ERROR "No Matlab or Octave mex compiler found") 
    set(MEX_FOUND 0)
  endif(MKOCT)
endif(MATLAB)
