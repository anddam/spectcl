@echo off
rem SpecTcl executable for Windows
rem Contributed by Ryan P. Casey April 2001
rem

rem Change DIR to the directory that contains the SpecTcl 
source files
set DIR=c:\programs\SpecTcl\SpecTcl

rem Change WISH to the pathname of your wish  binary
set WISH=c:\programs\tcl\bin\wish83.exe

set SPECTCL_DIR=%DIR%

echo Starting SpecTcl 1.2

call "%WISH%" "%DIR%\main.tk" "%1"
