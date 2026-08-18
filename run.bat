@echo off
setlocal

:: 1. Terminate background processes
taskkill /F /IM vsim.exe /T 2>nul
taskkill /F /IM vopt.exe /T 2>nul
taskkill /F /IM vlog.exe /T 2>nul
taskkill /F /IM vish.exe /T 2>nul

:: 2. Wipe previous work folder if it exists
if exist "work" (
    rmdir /s /q "work" 2>nul
)

:: 3. Run simulation
"C:\questasim64_2021.1\win64\vsim.exe" -c -do "do run.do"

:: 4. Post-run cleanup
taskkill /F /IM vsim.exe /T 2>nul
taskkill /F /IM vopt.exe /T 2>nul
taskkill /F /IM vlog.exe /T 2>nul
taskkill /F /IM vish.exe /T 2>nul

pause