@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION

:: 设定生成Token的长度
SET TOKEN_LENGTH=64
:: 用于生成Token的字符集
SET TOKEN_CHAR_SET=abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*-_=+

ECHO ==================== Deploy InfluxDB 2 ====================

ECHO 1. Generating Token for InfluxDB2...

:: 生成随机Token的方法（使用PowerShell）
for /f "delims=" %%i in ('powershell -command "$length=%TOKEN_LENGTH%; $chars='%TOKEN_CHAR_SET%'; -join ((1..$length) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })"') do set TOKEN=%%i

ECHO 2. Starting InfluxDB2 container...

:: 如果容器已经启动，则提示并退出
FOR /F "tokens=*" %%i IN ('docker ps -a --format "{{.Names}}"') DO (
  IF "%%i"=="perf-influxdb" (
    ECHO.
    ECHO InfluxDB2 container is already running.
    ECHO.
    ECHO Please stop the container first before starting a new one.
    ECHO.
    GOTO :EOF
  )
)

ECHO.
ECHO Container Id:
:: 拉起`InfluxDB 2`容器
docker run -d ^
  -p 8086:8086 ^
  -v influxdb-data:/var/lib/influxdb2 ^
  -v influxdb-config:/etc/influxdb2 ^
  -e DOCKER_INFLUXDB_INIT_MODE=setup ^
  -e DOCKER_INFLUXDB_INIT_USERNAME=admin ^
  -e DOCKER_INFLUXDB_INIT_PASSWORD=perf@JMeter#1024 ^
  -e DOCKER_INFLUXDB_INIT_ORG=Org ^
  -e DOCKER_INFLUXDB_INIT_BUCKET=JMeter ^
  -e DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=!TOKEN! ^
  --restart=unless-stopped ^
  --hostname=influxdb ^
  --name=perf-influxdb ^
  influxdb:2

:: 提示保存
ECHO.
ECHO Please save the following Token securely, it is your credential to access InfluxDB2.
ECHO.
ECHO token: !TOKEN!
ECHO.

ENDLOCAL
