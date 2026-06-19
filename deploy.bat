@echo off
REM ============================================
REM  Tide - Vercel Deployment Script
REM ============================================
REM  Prerequisites:
REM    1. Flutter SDK installed and on PATH
REM    2. Vercel CLI: npm i -g vercel
REM    3. Logged in to Vercel: vercel login
REM ============================================

echo [1/2] Building Flutter web app...
call flutter build web --release --base-href /

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Flutter build failed!
    exit /b 1
)

echo.
echo [2/2] Deploying to Vercel...
echo.

REM Use --prod flag for production deployment
REM Remove --prod for preview deployment
vercel --prod

echo.
echo Deployment complete!
