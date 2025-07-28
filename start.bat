@echo off
setlocal enabledelayedexpansion

:: WhatsApp Defender Ultra - Windows Startup Script
:: Usage: start.bat [mode]

title WhatsApp Defender Ultra

:: Colors (limited in Windows CMD)
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "PURPLE=[95m"
set "CYAN=[96m"
set "NC=[0m"

:: ASCII Banner
echo %PURPLE%
echo ██╗    ██╗██╗  ██╗ █████╗ ████████╗███████╗ █████╗ ██████╗ ██████╗ 
echo ██║    ██║██║  ██║██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██╔══██╗██╔══██╗
echo ██║ █╗ ██║███████║███████║   ██║   ███████╗███████║██████╔╝██████╔╝
echo ██║███╗██║██╔══██║██╔══██║   ██║   ╚════██║██╔══██║██╔═══╝ ██╔═══╝ 
echo ╚███╔███╔╝██║  ██║██║  ██║   ██║   ███████║██║  ██║██║     ██║     
echo  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝     
echo.                                                                     
echo ██████╗ ███████╗███████╗███████╗███╗   ██╗██████╗ ███████╗██████╗  
echo ██╔══██╗██╔════╝██╔════╝██╔════╝████╗  ██║██╔══██╗██╔════╝██╔══██╗ 
echo ██║  ██║█████╗  █████╗  █████╗  ██╔██╗ ██║██║  ██║█████╗  ██████╔╝ 
echo ██║  ██║██╔══╝  ██╔══╝  ██╔══╝  ██║╚██╗██║██║  ██║██╔══╝  ██╔══██╗ 
echo ██████╔╝███████╗██║     ███████╗██║ ╚████║██████╔╝███████╗██║  ██║ 
echo ╚═════╝ ╚══════╝╚═╝     ╚══════╝╚═╝  ╚═══╝╚═════╝ ╚══════╝╚═╝  ╚═╝ 
echo.                                                                     
echo                     🛡️  ULTRA ANTI BUG SYSTEM 🛡️
echo %NC%

:: Check if Node.js is installed
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo %RED%❌ Node.js is not installed. Please install Node.js v20+ first.%NC%
    pause
    exit /b 1
)

:: Get Node.js version
for /f "tokens=1 delims=v" %%i in ('node -v') do set NODE_VERSION=%%i
for /f "tokens=1 delims=." %%i in ("%NODE_VERSION:~1%") do set MAJOR_VERSION=%%i

if %MAJOR_VERSION% lss 20 (
    echo %RED%❌ Node.js version %MAJOR_VERSION% detected. Please upgrade to v20+%NC%
    pause
    exit /b 1
)

echo %GREEN%✅ Node.js %NODE_VERSION% detected%NC%

:: Check if Python is installed
where python >nul 2>nul
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
    echo %GREEN%✅ !PYTHON_VERSION! detected%NC%
    set PYTHON_AVAILABLE=1
) else (
    echo %YELLOW%⚠️  Python not found. Python monitoring will be disabled.%NC%
    set PYTHON_AVAILABLE=0
)

:: Function to install dependencies
:install_deps
echo %YELLOW%📦 Checking dependencies...%NC%

if not exist "node_modules" (
    echo %YELLOW%📦 Installing Node.js dependencies...%NC%
    call npm install
    if %errorlevel% neq 0 (
        echo %RED%❌ Failed to install Node.js dependencies%NC%
        pause
        exit /b 1
    )
    echo %GREEN%✅ Node.js dependencies installed%NC%
) else (
    echo %GREEN%✅ Node.js dependencies already installed%NC%
)

if %PYTHON_AVAILABLE% equ 1 (
    if exist "requirements.txt" (
        echo %YELLOW%📦 Installing Python dependencies...%NC%
        python -m pip install -r requirements.txt --quiet
        echo %GREEN%✅ Python dependencies installed%NC%
    )
)
goto :eof

:: Function to create directories
:create_dirs
echo %YELLOW%📁 Creating directories...%NC%
if not exist "logs" mkdir logs
if not exist "session" mkdir session
if not exist "temp" mkdir temp
if not exist "backup" mkdir backup
echo %GREEN%✅ Directories created%NC%
goto :eof

:: Function to show system info
:show_system_info
echo %BLUE%📋 System Information:%NC%
echo %BLUE%   • OS: %OS% %PROCESSOR_ARCHITECTURE%%NC%
echo %BLUE%   • CPU Cores: %NUMBER_OF_PROCESSORS%%NC%
echo %BLUE%   • Node.js: %NODE_VERSION%%NC%
if %PYTHON_AVAILABLE% equ 1 (
    echo %BLUE%   • Python: %PYTHON_VERSION%%NC%
)
echo %BLUE%────────────────────────────────────%NC%
goto :eof

:: Function to show usage
:show_usage
echo %CYAN%Usage: %0 [mode]%NC%
echo %CYAN%Modes:%NC%
echo %CYAN%  main        - Run main bot (default)%NC%
echo %CYAN%  defender    - Run basic defender only%NC%
echo %CYAN%  ultra       - Run ultra defender with clustering%NC%
echo %CYAN%  performance - Run performance monitor only%NC%
echo %CYAN%  python      - Run Python performance monitor%NC%
echo %CYAN%  install     - Install dependencies only%NC%
echo %CYAN%  help        - Show this help%NC%
echo.
echo %CYAN%Examples:%NC%
echo %CYAN%  %0           # Run main bot%NC%
echo %CYAN%  %0 ultra     # Run ultra defender%NC%
echo %CYAN%  %0 install   # Install dependencies%NC%
goto :eof

:: Main execution
set MODE=%1
if "%MODE%"=="" set MODE=main

if "%MODE%"=="help" goto show_usage
if "%MODE%"=="-h" goto show_usage
if "%MODE%"=="--help" goto show_usage

if "%MODE%"=="install" (
    call :install_deps
    call :create_dirs
    echo %GREEN%✅ Installation completed%NC%
    pause
    exit /b 0
)

call :install_deps
call :create_dirs
call :show_system_info

if "%MODE%"=="main" (
    echo %GREEN%🚀 Starting WhatsApp Defender Ultra (Main Bot)...%NC%
    node index.js
) else if "%MODE%"=="defender" (
    echo %GREEN%🛡️  Starting Basic Defender...%NC%
    node Defender.js
) else if "%MODE%"=="ultra" (
    echo %GREEN%🔥 Starting Ultra Defender with Clustering...%NC%
    node DefendUltra.js
) else if "%MODE%"=="performance" (
    echo %GREEN%📊 Starting Performance Monitor...%NC%
    node Performa.js
) else if "%MODE%"=="python" (
    if %PYTHON_AVAILABLE% equ 0 (
        echo %RED%❌ Python is required but not installed%NC%
        pause
        exit /b 1
    )
    echo %GREEN%🐍 Starting Python Performance Monitor...%NC%
    python Performa.py
) else (
    echo %RED%❌ Unknown mode: %MODE%%NC%
    call :show_usage
    pause
    exit /b 1
)

:: Keep window open if there's an error
if %errorlevel% neq 0 (
    echo.
    echo %RED%❌ Process exited with error code %errorlevel%%NC%
    pause
)

endlocal