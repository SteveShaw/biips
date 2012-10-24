:: Change these variables to fit your needs
::-----------------------------------------
set BIIPS_SRC=C:\Users\Adrien-ALEA\workspace\biips-src\trunk
set BIIPS_BUILD=C:\Users\Adrien-ALEA\workspace\biips-release
set BIIPS_ROOT=C:\Users\Adrien-ALEA\biips
set BOOST_ROOT=C:\Program Files\boost\boost_1_46_1
set BOOST_LIBRARYDIR64=%BOOST_ROOT%\stage\lib64
set PAGEANT=C:\Program Files (x86)\PuTTY\pageant.exe
set GFORGE_PRIVATE_KEY=C:\Users\Adrien-ALEA\Documents\GForge_Inria_key.ppk
set TORTOISE=C:\Program Files\TortoiseSVN\bin\TortoiseProc.exe
set ECLIPSE=C:\Program Files\eclipse\eclipse.exe
set MAKE=C:\MinGW\bin\mingw32-make
set RTOOLS_BINDIR=C:\Rtools\bin
set R_BINDIR=C:\Program Files\R\R-2.15.1\bin
set CMAKE_BUILD_TYPE=Release
set CMAKE_GENERATOR="Eclipse CDT4 - MinGW Makefiles"
set CPACK_GENERATOR=NSIS
set NJOBS=8
::-----------------------------------------

pause
"%PAGEANT%" "%GFORGE_PRIVATE_KEY%"
"%TORTOISE%" /command:update /path:"%BIIPS_SRC%" /closeonend:2

choice /m "Run CMake"
if "%errorlevel%"=="1" (
	call:ask_clear
	cd "%BIIPS_BUILD%"
	cmake -G%CMAKE_GENERATOR% -DCMAKE_BUILD_TYPE=%CMAKE_BUILD_TYPE% -DCMAKE_INSTALL_PREFIX="%BIIPS_ROOT%" -DCMAKE_ECLIPSE_EXECUTABLE="%ECLIPSE%" "%BIIPS_SRC%"
)

cd "%BIIPS_BUILD%"

choice /m "Build/install Biips"
if "%errorlevel%"=="1" (
	rmdir /S /Q "%BIIPS_ROOT%"
	mkdir "%BIIPS_ROOT%"
	cd "%BIIPS_BUILD%"
	"%MAKE%" -j%NJOBS% install
	call:ask_test
	call:ask_testcompiler
	call:ask_package
)

set "PATH=%RTOOLS_BINDIR%;%R_BINDIR%;%PATH%"
choice /m "Build/install RBiips"
if "%errorlevel%"=="1" (
	cd "%BIIPS_BUILD%"
	"%MAKE%" RBiips_INSTALL_build
)

choice /m "Build MatBiips"
if "%errorlevel%"=="1" (
	cd "%BIIPS_BUILD%"
	"%MAKE%" matbiips
	call:ask_test_matbiips
)

pause

goto:eof

::-----------------
::Functions section
::-----------------

:ask_clear
choice /m "Clear build directory"
if "%errorlevel%"=="1" (
	rmdir /S /Q "%BIIPS_BUILD%"
	mkdir "%BIIPS_BUILD%"
)
goto:eof

:ask_test
choice /m "Run BiipsTest tests"
if "%errorlevel%"=="1" (
	cd "%BIIPS_BUILD%\test"
	"%MAKE%" test
)
goto:eof

:ask_testcompiler
choice /m "Run BiipsTestCompiler tests"
if "%errorlevel%"=="1" (
	cd "%BIIPS_BUILD%\testcompiler"
	"%MAKE%" test
)
goto:eof

:ask_package
choice /m "Package Biips"
if "%errorlevel%"=="1" (
	cd "%BIIPS_BUILD%"
	cpack -G %CPACK_GENERATOR%
	cpack -G ZIP
)
goto:eof

:ask_test_matbiips
choice /m "Run MatBiips tests"
if "%errorlevel%"=="1" (
	cd "%BIIPS_BUILD%\matbiips"
	"%MAKE%" test
)
goto:eof