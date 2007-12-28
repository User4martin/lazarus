SET OLDCURDIR=%CD%
SET OLDCURDRIVE=%CD:~,2%

SET FPCSRC_DIR=%FPCSVNDIR%\fpcsrc
SET HASFCL=0

SET SOURCE_DIR=%BUILDDIR%\fpc-source
%SVN% export %FPCSRC_DIR% %SOURCE_DIR%

:: to switch drive
%SOURCE_DIR:~,2%
cd %SOURCE_DIR%

:: apply patch
if [%PATCHFILE%]==[] GOTO NO_PATCH
%PATCHEXE% -p0 -i %PATCHDIR%\%PATCHFILE%

:NO_PATCH 

:: copy fpc source
gmkdir -p %BUILDDIR%\fpc\source
cp -pr %SOURCE_DIR%\rtl %BUILDDIR%\fpc\source\rtl >> %LOGFILE%
IF %HASFCL%==1 cp -pr %SOURCE_DIR%\fcl %BUILDDIR%\fpc\source\fcl >> %LOGFILE%
cp -pr %SOURCE_DIR%\packages %BUILDDIR%\fpc\source\packages >> %LOGFILE%

:: build compiler
%MAKEEXE% clean PP=%RELEASE_PPC% >> %LOGFILE% 2>&1
%MAKEEXE% compiler_cycle PP=%RELEASE_PPC% >> %LOGFILE% 2>&1

FOR /F %%L IN ('%SOURCE_DIR%\compiler\utils\fpc.exe -PB') DO SET COMPILER=%SOURCE_DIR%\compiler\%%L
FOR /F %%L IN ('%COMPILER% -iV') DO SET FPCVERSION=%%L
FOR /F %%L IN ('%COMPILER% -iW') DO SET FPCLONGVERSION=%%L
IF "%FPCVERSION:~,3%"=="2.0" SET HASFCL=1

%MAKEEXE% -C rtl clean PP=%COMPILER% >> %LOGFILE% 
%MAKEEXE% -C packages clean PP=%COMPILER% >> %LOGFILE%
IF %HASFCL%==1 %MAKEEXE% -C fcl clean PP=%COMPILER% >> %LOGFILE%

IF %HASFCL%==0 %MAKEEXE% rtl packages PP=%COMPILER% OPT="-g -Ur -CX" >> %LOGFILE%
IF %HASFCL%==1 %MAKEEXE% rtl packages_base_all fcl packages_extra_all PP=%COMPILER% OPT="-g -Ur -CX" >> %LOGFILE%

%MAKEEXE% utils PP=%COMPILER% OPT="-CX -XX -Xs" DATA2INC=%SOURCE_DIR%\utils\data2inc >> %LOGFILE%

SET INSTALL_BASE=%BUILDDIR%\fpc\%FPCVERSION%
SET INSTALL_BINDIR=%INSTALL_BASE%\bin\%FPCFULLTARGET%
%MAKEEXE% compiler_install rtl_install packages_install utils_install INSTALL_PREFIX=%INSTALL_BASE% PP=%COMPILER% FPCMAKE=%SOURCE_DIR%\utils\fpcm\fpcmake.exe >> %LOGFILE%
IF %HASFCL%==1 %MAKEEXE% fcl_install INSTALL_PREFIX=%INSTALL_BASE% PP=%COMPILER% FPCMAKE=%SOURCE_DIR%\utils\fpcm\fpcmake.exe >> %LOGFILE%

FOR /F %%L IN ('%INSTALL_BINDIR%\fpc.exe -PB') DO SET COMPILER=%%L

:: move fpc source to final location
mv %BUILDDIR%\fpc\source %INSTALL_BASE% >> %LOGFILE%

%OLDCURDRIVE%
cd %OLDCURDIR%

rm -rf %SOURCE_DIR%

