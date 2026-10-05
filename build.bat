@echo off
rem Build SimpleHUD-1.2.5.jar (vanilla 1.2.5 MultiMC patch jar) via RetroMCP-Java.
rem Repo root doubles as the RetroMCP workspace directory.
rem Requires: Java 8 (for RetroMCP) and Python 3 (for the HUD patch applier).
setlocal
cd /d "%~dp0"

set "JAVA8="
if defined JAVA8_HOME if exist "%JAVA8_HOME%\bin\java.exe" set "JAVA8=%JAVA8_HOME%\bin\java.exe"
if not defined JAVA8 if exist "C:\Program Files\Java\openjdk-8u212-b03\bin\java.exe" set "JAVA8=C:\Program Files\Java\openjdk-8u212-b03\bin\java.exe"
if not defined JAVA8 (
  echo ERROR: Java 8 not found. Set JAVA8_HOME to a JDK 8 install. 1>&2
  exit /b 1
)

set "RMCP="
if defined RETROMCP_JAR if exist "%RETROMCP_JAR%" set "RMCP=%RETROMCP_JAR%"
if not defined RMCP if exist "..\RetroMCP-Java\build\libs\RetroMCP-CLI-all.jar" set "RMCP=..\RetroMCP-Java\build\libs\RetroMCP-CLI-all.jar"
if not defined RMCP if exist "tools\RetroMCP-CLI-all.jar" set "RMCP=tools\RetroMCP-CLI-all.jar"
if not defined RMCP (
  echo ERROR: RetroMCP-CLI-all.jar not found. 1>&2
  echo   Clone https://github.com/MCPHackers/RetroMCP-Java next to this repo and run its build task, 1>&2
  echo   or drop RetroMCP-CLI-all.jar into tools\ ^(or set RETROMCP_JAR^). 1>&2
  exit /b 1
)

if not exist "jars" "%JAVA8%" -jar "%RMCP%" setup 1.2.5
if errorlevel 1 exit /b 1
if not exist "minecraft\src\net\minecraft\src\GuiIngame.java" "%JAVA8%" -jar "%RMCP%" decompile
if errorlevel 1 exit /b 1

python tools\apply_hud.py
if errorlevel 1 exit /b 1

"%JAVA8%" -jar "%RMCP%" build client
if errorlevel 1 exit /b 1

if not exist "dist" mkdir dist
copy /y "build\minecraft.zip" "dist\SimpleHUD-1.2.5.jar" >nul
echo OK: dist\SimpleHUD-1.2.5.jar
