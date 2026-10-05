@echo off
rem Build dist\SimpleHUD-1.2.5.jar for Minecraft 1.2.5.
rem
rem The jar contains a single ModLoader mod class (mod_SimpleHUD): no vanilla
rem classes are edited, so it is safe to add on top of Forge/MultiMC instances.
rem Repo root doubles as the RetroMCP workspace directory (compile classpath).
rem Requires: Java 8, curl, python.
setlocal
cd /d "%~dp0"

set "JAVA8="
if defined JAVA8_HOME (
  if exist "%JAVA8_HOME%\bin\java.exe" set "JAVA8=%JAVA8_HOME%\bin\java.exe"
  if exist "%JAVA8_HOME%" if not exist "%JAVA8_HOME%\bin\java.exe" set "JAVA8=%JAVA8_HOME%"
)
if not defined JAVA8 if exist "C:\Program Files\Java\openjdk-8u212-b03\bin\java.exe" set "JAVA8=C:\Program Files\Java\openjdk-8u212-b03\bin\java.exe"
if not defined JAVA8 (
  echo ERROR: Java 8 not found. Set JAVA8_HOME to a JDK 8 install. 1>&2
  exit /b 1
)
for %%i in ("%JAVA8%") do set "JAVABIN=%%~dpi"
set "JAVAC=%JAVABIN%javac.exe"
set "JARTOOL=%JAVABIN%jar.exe"

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

set "CACHE=tools\.cache"

set "PY="
call :trypy python3
if not defined PY call :trypy python
if not defined PY (
  echo ERROR: working python3/python not found. 1>&2
  exit /b 1
)

rem 1. Vanilla workspace (compile classpath only - nothing is patched)
if not exist "jars" "%JAVA8%" -jar "%RMCP%" setup 1.2.5
if errorlevel 1 exit /b 1
if not exist "minecraft\src\net\minecraft\src\GuiIngame.java" "%JAVA8%" -jar "%RMCP%" decompile
if errorlevel 1 exit /b 1
if not exist "minecraft\bin\net\minecraft\client\Minecraft.class" "%JAVA8%" -jar "%RMCP%" recompile client
if errorlevel 1 exit /b 1

rem 2. ModLoader API classes (compile-time only, never shipped)
if not exist "%CACHE%" mkdir "%CACHE%"
if not exist "%CACHE%\modloader" mkdir "%CACHE%\modloader"
if not exist "%CACHE%\modloader\BaseMod.class" (
  if not exist "%CACHE%\ModLoader-1.2.5.zip" curl -sSL -o "%CACHE%\ModLoader-1.2.5.zip" "https://b2.mcarchive.net/file/mcarchive/219370a86a15bfef8ff91f51fdd151e99391b771759183b19f72197452a28b79/ModLoader%%201.2.5.zip"
  if errorlevel 1 exit /b 1
  %PY% -c "import zipfile; z=zipfile.ZipFile(r'%CACHE%\ModLoader-1.2.5.zip'); z.extract('BaseMod.class',r'%CACHE%\modloader'); z.extract('ModLoader.class',r'%CACHE%\modloader')"
  if errorlevel 1 exit /b 1
)

rem 3. tiny-remapper + deps (compile-time only, never shipped)
if not exist "%CACHE%\remaplib" mkdir "%CACHE%\remaplib"
call :dll "tiny-remapper-0.14.1.jar" "https://maven.fabricmc.net/net/fabricmc/tiny-remapper/0.14.1/tiny-remapper-0.14.1.jar"
call :dll "mapping-io-0.8.0.jar" "https://maven.fabricmc.net/net/fabricmc/mapping-io/0.8.0/mapping-io-0.8.0.jar"
call :dll "tiny-mappings-parser-0.3.0+build.17.jar" "https://maven.fabricmc.net/net/fabricmc/tiny-mappings-parser/0.3.0+build.17/tiny-mappings-parser-0.3.0+build.17.jar"
call :dll "asm-9.10.1.jar" "https://repo1.maven.org/maven2/org/ow2/asm/asm/9.10.1/asm-9.10.1.jar"
call :dll "asm-analysis-9.10.1.jar" "https://repo1.maven.org/maven2/org/ow2/asm/asm-analysis/9.10.1/asm-analysis-9.10.1.jar"
call :dll "asm-commons-9.10.1.jar" "https://repo1.maven.org/maven2/org/ow2/asm/asm-commons/9.10.1/asm-commons-9.10.1.jar"
call :dll "asm-tree-9.10.1.jar" "https://repo1.maven.org/maven2/org/ow2/asm/asm-tree/9.10.1/asm-tree-9.10.1.jar"
call :dll "asm-util-9.10.1.jar" "https://repo1.maven.org/maven2/org/ow2/asm/asm-util/9.10.1/asm-util-9.10.1.jar"
call :dll "gson-2.11.0.jar" "https://repo1.maven.org/maven2/com/google/code/gson/gson/2.11.0/gson-2.11.0.jar"
call :dll "jsr305-3.0.2.jar" "https://repo1.maven.org/maven2/com/google/code/findbugs/jsr305/3.0.2/jsr305-3.0.2.jar"

rem 4. Compile the mod (MCP names)
if exist "%CACHE%\modbuild" rmdir /s /q "%CACHE%\modbuild"
if exist "%CACHE%\modinput.jar" del "%CACHE%\modinput.jar"
mkdir "%CACHE%\modbuild"
"%JAVAC%" -encoding UTF-8 -cp "minecraft/bin;%CACHE%/modloader" -d "%CACHE%/modbuild" mod/mod_SimpleHUD.java
if errorlevel 1 exit /b 1

rem 5. Package + remap to notch names (tiny-remapper merges into existing
rem output, so the output jar must not exist beforehand)
if exist "%CACHE%\modinput" rmdir /s /q "%CACHE%\modinput"
mkdir "%CACHE%\modinput"
copy "%CACHE%\modbuild\mod_SimpleHUD.class" "%CACHE%\modinput\" >nul
pushd "%CACHE%\modinput"
"%JARTOOL%" cfM ..\modinput.jar mod_SimpleHUD.class
if errorlevel 1 exit /b 1
popd
if not exist "dist" mkdir dist
if exist "dist\SimpleHUD-1.2.5.jar" del "dist\SimpleHUD-1.2.5.jar"
set "REMAPP_CP="
for %%j in ("%CACHE%\remaplib\*.jar") do call set "REMAPP_CP=%%REMAPP_CP%%;%%~fj"
set "REMAPP_CP=%REMAPP_CP:~1%"
"%JAVA8%" -cp "%REMAPP_CP%" net.fabricmc.tinyremapper.Main "%CACHE%\modinput.jar" dist\SimpleHUD-1.2.5.jar conf\mappings.tiny named client "minecraft\bin" "%CACHE%\modloader"
if errorlevel 1 exit /b 1

rem 6. Guard: the jar must contain ONLY the mod class (never vanilla classes)
%PY% -c "import zipfile,sys; n=zipfile.ZipFile(r'dist\SimpleHUD-1.2.5.jar').namelist(); sys.exit(0 if n==['mod_SimpleHUD.class'] else (print('UNEXPECTED JAR CONTENTS:',n),1))"
if errorlevel 1 exit /b 1
echo OK: dist\SimpleHUD-1.2.5.jar
exit /b 0

:dll
if not exist "%CACHE%\remaplib\%~1" curl -sSL -o "%CACHE%\remaplib\%~1" "%~2"
if errorlevel 1 exit /b 1
exit /b 0

:trypy
where %1 >nul 2>nul || exit /b 0
%1 -c "import sys" >nul 2>nul || exit /b 0
set "PY=%1"
exit /b 0
