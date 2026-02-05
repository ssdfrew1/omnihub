@echo off
chcp 65001 >nul
title Запуск omniroblox.mooo.com на порту 80
color 0A

echo ========================================
echo   Запуск веб-сервера на порту 80
echo   Домен: omniroblox.mooo.com
echo ========================================
echo.

REM Проверяем Python
python --version >nul 2>&1
if errorlevel 1 (
    echo [ОШИБКА] Python не найден!
    echo Установите Python или добавьте в PATH
    pause
    exit /b 1
)

REM Переходим в папку с сайтом
cd /d "C:\Users\Kita1ko\Desktop\Project\Loader\Omni\omniroblox.mooo.com"

echo Текущая папка: %cd%
echo.
echo Важная информация:
echo 1. Сервер запускается на ВСЕХ интерфейсах (0.0.0.0)
echo 2. Порт: 80
echo 3. Для работы на порту 80 нужны права администратора
echo 4. Проверьте настройки брандмауэра
echo.

REM Проверяем права администратора для порта 80
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ВНИМАНИЕ] Нет прав администратора!
    echo Порт 80 требует прав админа в Windows
    echo.
    set /p choice="Попробовать все равно? (y/N): "
    if /i not "%choice%"=="y" (
        echo Запуск отменен
        pause
        exit /b 1
    )
)

echo Запуск сервера...
echo Команда: python -m http.server 80
echo.

REM Основная команда запуска
python -m http.server 80