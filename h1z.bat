@echo off
setlocal enabledelayedexpansion
set "excel_file=C:\c\cgi.xlsx"
cls
xlsx2csv %excel_file% temp.csv
goto :menu

:menu
cls
echo =========================================
echo            Dahua Batch CGI
echo =========================================
echo Warning IP Addr of NTP server has changed to 10.250.4.5. Please ensure if the NTP configuration is correct before you apply it.
echo.


echo 1. = Show Input IPadrs and names (cgi.xlsx)
echo 2. = Get Camera IP, CAMERANAME, Model, SN, MAC (Dahua)
echo 3. = Get Camera IP, CAMERANAME, Model, SN, MAC (Hikvision)
echo 4. = Get Dahua channel title (useful to DVR)
echo 5. = Get Dahua NTP settings
echo 6. # Set Dahua Channel_title
echo 7. # Set Dahua Device_name
echo 8. # Set Dahua NTP configuration (right)
echo 9. # Set Dahua "New password"
echo.
echo e. = Exit
echo.
choice /c 123456789ea /n /m "Choose an option: "

if errorlevel 11 goto :hidden_menu
if errorlevel 10 goto :exit
if errorlevel 9 goto :set_password
if errorlevel 8 goto :set_ntp
if errorlevel 7 goto :set_device_name
if errorlevel 6 goto :set_channel_title
if errorlevel 5 goto :get_ntp
if errorlevel 4 goto :get_channel_title
if errorlevel 3 goto :get_hikinfo
if errorlevel 2 goto :get_dahuainfo
if errorlevel 1 goto :get_ipads
goto :menu


:hidden_menu
cls
echo ================================
echo         Hidden menu
echo ================================
echo 1. Disable annoying BEEP-BEEP sound
echo 2. Get the screenshots
echo 3.
echo 4.
echo e. Back
echo.
choice /c 1234e /n /m "Choose an option: "
if errorlevel 5 goto :menu
if errorlevel 4 goto :4
if errorlevel 3 goto :3
if errorlevel 2 goto :2
if errorlevel 1 goto :beep




:beep
echo Disable annoying BEEP-BEEP sound
set /p password="password: "
set "excel_file=C:\c\cgi.xlsx"
cls
xlsx2csv %excel_file% temp.csv

for /f "tokens=1,2 delims=," %%a in (temp.csv) do (
    set "ip=%%a"

    for %%c in (
		"name=StorageNotExist.Enable=false"
            ) do (
        echo.
        curl -s --globoff --digest --user admin:"!password!" --max-time 2 "http://!ip!/cgi-bin/configManager.cgi?action=setConfig&%%~c"
        echo.
    )

    if !errorlevel! equ 0 (
    echo !ip! found
      
    ) else (
    echo !ip! not found
    )
)

del temp.csv
pause
goto :hidden_menu

:2
echo Take the screens shot
python h1z.py

pause
goto :hidden_menu

:3
echo nothing
pause
goto :hidden_menu

:4
echo nothing
pause
goto :hidden_menu

:get_hikinfo

echo Get Camera IP, CAMERANAME, Model, SN, MAC (Hikvision)
set /p password="password: "
choice /c YN /n /m "Confirm? Y/N"
if errorlevel 2 (
    echo canceled
    pause
    goto :menu
)

if errorlevel 1 (
    set "excel_file=C:\c\cgi.xlsx"
    cls
    xlsx2csv %excel_file% temp.csv
	echo IP CAMERANAME MODEL MACADDR SN
    for /f "tokens=1 delims=," %%a in (temp.csv) do (
        set "ip=%%a"
		echo.
        call :process_ip %%a
		echo.
    )

    del temp.csv
    pause
    goto :menu
)

:process_ip
set "ip=%1"

curl -s --globoff --digest --user admin:"%password%" --max-time 2 "http://%ip%/ISAPI/System/Video/inputs/channels/1/" 2>nul | findstr "<name>" > temp.txt
curl -s --globoff --digest --user admin:"%password%" --max-time 2 "http://%ip%/ISAPI/System/deviceInfo" 2>nul | findstr "<model>" >> temp.txt
curl -s --globoff --digest --user admin:"%password%" --max-time 2 "http://%ip%/ISAPI/System/deviceInfo" 2>nul | findstr "<macAddress>" >> temp.txt
curl -s --globoff --digest --user admin:"%password%" --max-time 2 "http://%ip%/ISAPI/System/deviceInfo" 2>nul | findstr "<serialNumber>" >> temp.txt
if exist temp.txt (
    set "line="
    for /f "tokens=2 delims=<>" %%A in (temp.txt) do (
        set "line=!line! %%A"
    )
    setlocal enabledelayedexpansion
    echo %ip%!line!
    endlocal
    del temp.txt
) else (
    echo Camera at %ip% not found or inaccessible.
)
goto :eof



:model
echo Get Device Type
set /p password="Password: "
choice /c YN /n /m "Confirm? (Y/N)"
if errorlevel 2 (
    echo Canceled
    pause
    goto :menu
)

if errorlevel 1 (
    set "excel_file=C:\c\cgi.xlsx"
    cls
    xlsx2csv %excel_file% temp.csv

    for /f "tokens=1 delims=," %%a in (temp.csv) do (
        set "ip=%%a"
        echo.
        call :process_model %%a
        echo.
    )

    del temp.csv
    pause
    goto :menu
)

:process_model
set "ip=%1"

curl -s --globoff --digest --user admin:"%password%" --max-time 2 "http://%ip%/cgi-bin/magicBox.cgi?action=getDeviceType" 2>nul > temp.txt
echo IP MODEL
if exist temp.txt (
    set "line="
    for /f "tokens=2 delims==" %%A in (temp.txt) do (
        set "line=!line! %%A"
    )
    setlocal enabledelayedexpansion
    echo %ip%!line!
    endlocal
    del temp.txt
) else (
    echo Device at %ip% not found or inaccessible.
)
goto :eof


@echo off
setlocal EnableDelayedExpansion

:get_dahuainfo
echo Get Camera IP, CAMERANAME, Model, SN, MAC (Dahua)
set /p password="Password: "
choice /c YN /n /m "Confirm? (Y/N)"
if errorlevel 2 (
    echo Canceled
    pause
    goto :menu
)

if errorlevel 1 (
    set "excel_file=C:\c\cgi.xlsx"
    cls
    echo IP Name Model SN MAC
    xlsx2csv %excel_file% temp.csv

    for /f "tokens=1 delims=," %%a in (temp.csv) do (
        set "ip=%%a"
        echo.
        call :process_sn %%a
        echo.
    )
    del temp.csv
    pause
    goto :menu
)

:process_sn
set "ip=%1"


curl -s --globoff --digest --user admin:"%password%" --max-time 2 "http://%ip%/cgi-bin/configManager.cgi?action=getConfig&name=ChannelTitle[0].Name" 2>nul > temp_title.txt
curl -s --globoff --digest --user admin:"%password%" --max-time 2 "http://%ip%/cgi-bin/magicBox.cgi?action=getDeviceType" 2>nul > temp_model.txt
curl -s --globoff --digest --user admin:"%password%" --max-time 2 "http://%ip%/cgi-bin/magicBox.cgi?action=getSerialNo" 2>nul > temp_sn.txt
curl -s --globoff --digest --user admin:"%password%" --max-time 2 "http://%ip%/cgi-bin/configManager.cgi?action=getConfig&name=Network.eth0.PhysicalAddress" 2>nul > temp_mac.txt


set "title=Not Found"
if exist temp_title.txt (
    for /f "tokens=2 delims==" %%A in (temp_title.txt) do (
        set "title=%%A"
    )
)

set "model=Not Found"
if exist temp_model.txt (
    for /f "tokens=2 delims==" %%A in (temp_model.txt) do (
        set "model=%%A"
    )
)

set "serial=Not Found"
if exist temp_sn.txt (
    for /f "tokens=2 delims==" %%A in (temp_sn.txt) do (
        set "serial=%%A"
    )
)

set "mac=Not Found"
if exist temp_mac.txt (
    for /f "tokens=2 delims==" %%A in (temp_mac.txt) do (
        set "mac=%%A"
    )
)


setlocal enabledelayedexpansion
echo %ip% !title! !model! !serial! !mac!
endlocal


if exist temp_title.txt del temp_title.txt
if exist temp_model.txt del temp_model.txt
if exist temp_sn.txt del temp_sn.txt
if exist temp_mac.txt del temp_mac.txt
goto :eof


:set_ntp
echo Set Dahua NTP configuration (right)
echo Warning: IP Addr of NTP server has changed to 10.250.4.5. Please ensure if the NTP configuration is correct before you apply it.
set /p password="password: "
choice /c YN /n /m "Confifm? Y/N"
if errorlevel 2 (
echo canceled
pause
goto :menu
)
if errorlevel 1 (
set "excel_file=C:\c\cgi.xlsx"
cls
xlsx2csv %excel_file% temp.csv

for /f "tokens=1,2 delims=," %%a in (temp.csv) do (
    set "ip=%%a"
    echo # !ip! #############################
    
    for %%c in (
        "NTP.Address=10.250.4.5"
        "NTP.Port=123"
        "NTP.TimeZoneDesc=Moscow"
        "NTP.UpdatePeriod=60"
        "Locales.TimeFormat=dd-MM-yy%%20HH:mm:ss"
		"NTP.Enable=true"
    ) do (
        curl -s --globoff --digest -H "Content-Type: application/x-www-form-urlencoded" --user admin:"!password!" --max-time 2 "http://!ip!/cgi-bin/configManager.cgi?action=setConfig&%%~c"
    )

    if !errorlevel! equ 0 (
        echo.
    ) else (
        echo !ip! not found
    )
    echo.
)

del temp.csv
pause
goto :menu
)

:set_device_name
echo Set Dahua Device_name
set /p password="password: "
choice /c YN /n /m "Confifm? Y/N"
if errorlevel 2 (
echo canceled
pause
goto :menu
)
if errorlevel 1 (
set "excel_file=C:\c\cgi.xlsx"
cls
xlsx2csv %excel_file% temp.csv

for /f "tokens=1,2 delims=," %%a in (temp.csv) do (
    set "ip=%%a"
    set "changedname=%%b"
    for %%c in (
        "General.MachineName=!changedname!"
    ) do (
        curl -s --globoff --digest --user admin:"!password!" --max-time 2 "http://!ip!/cgi-bin/configManager.cgi?action=setConfig&%%~c" > NUL
    )

    if !errorlevel! equ 0 (
        echo Requests for !ip! with changed name !changedname! succeeded.
    ) else (
        echo Requests for !ip! with changed name !changedname! failed.
    )
)

del temp.csv
pause
goto :menu
)


:get_device_name
@echo off
setlocal EnableDelayedExpansion

echo Get IP device name
set /p password="Password: "
choice /c YN /n /m "Confirm? (Y/N)"
if errorlevel 2 (
    echo Canceled
    pause
    goto :menu
)

if errorlevel 1 (
    set "excel_file=C:\c\cgi.xlsx"
    cls
    xlsx2csv %excel_file% temp.csv

    for /f "tokens=1 delims=," %%a in (temp.csv) do (
        set "ip=%%a"
        echo.
        call :process_dname %%a
        echo.
    )

    del temp.csv
    pause
    goto :menu
)

:process_dname
set "ip=%1"

curl -s --globoff --digest --user admin:"%password%" --max-time 2 "http://%ip%/cgi-bin/configManager.cgi?action=getConfig&name=General.MachineName" 2>nul > temp.txt

if exist temp.txt (
    set "line="
    for /f "tokens=2 delims==" %%A in (temp.txt) do (
        set "line=!line! %%A"
    )
    setlocal enabledelayedexpansion
    echo %ip%!line!
    endlocal
    del temp.txt
) else (
    echo Device at %ip% not found or inaccessible.
)
goto :eof

:exit
echo exitting
exit /b

:get_ipads
echo.
echo Show Input IPadrs and names (cgi.xlsx)
echo.
powershell -command "xlsx2csv C:\c\cgi.xlsx -s 1 | ForEach-Object { $_.Split(',')[0,1] -join ','}"
pause
goto :menu

:get_ntp


echo Get Dahua NTP settings
set /p password="Password: "
choice /c YN /n /m "Confirm? (Y/N)"
if errorlevel 2 (
    echo Canceled
    pause
    goto :menu
)

if errorlevel 1 (
    set "excel_file=C:\c\cgi.xlsx"
    cls
	echo IP NTP.Addr Enable Port TimeZone UpdatePeriod Time_Format HMS
    xlsx2csv %excel_file% temp.csv

    for /f "tokens=1 delims=," %%a in (temp.csv) do (
        set "ip=%%a"
        echo.
        call :process_ntp %%a
        echo.
    )

    del temp.csv
    pause
    goto :menu
)

:process_ntp
set "ip=%1"

for %%c in (
    "name=NTP.Address"
    "name=NTP.Enable"
    "name=NTP.Port"
    "name=NTP.TimeZoneDesc"
    "name=NTP.UpdatePeriod"
    "name=Locales.TimeFormat"
) do (
    curl -s --globoff --digest --user admin:"%password%" --max-time 2 "http://%ip%/cgi-bin/configManager.cgi?action=getConfig&%%~c" 2>nul | findstr "table" >> temp.txt
)

if exist temp.txt (
    set "line="
    for /f "tokens=2 delims==" %%A in (temp.txt) do (
        set "line=!line! %%A"
    )
    setlocal enabledelayedexpansion
    echo %ip%!line!
    endlocal
    del temp.txt
) else (
    echo Camera at %ip% not found or inaccessible.
)
goto :eof

:only_names 
echo  Change camera name
set /p password="password: "
choice /c YN /n /m "Confifm? Y/N"
if errorlevel 2 (
echo canceled
pause
goto :menu
)
if errorlevel 1 (
set "excel_file=C:\c\cgi.xlsx"
cls
xlsx2csv %excel_file% temp.csv

for /f "tokens=1,2 delims=," %%a in (temp.csv) do (
    set "ip=%%a"
    set "changedname=%%b"
    for %%c in (
        "ChannelTitle[0].Name=!changedname!"
    ) do (
        curl -s --globoff --digest --user admin:"!password!" --max-time 2 "http://!ip!/cgi-bin/configManager.cgi?action=setConfig&%%~c" > NUL
    )

    if !errorlevel! equ 0 (
        echo Requests for !ip! with changed name !changedname! succeeded.
    ) else (
        echo Requests for !ip! with changed name !changedname! failed.
    )
)

del temp.csv
pause
goto :menu
)

:set_channel_title

echo Set Dahua Channel_title
set /p password="password: "
choice /c YN /n /m "Confifm? Y/N"
if errorlevel 2 (
echo canceled
pause
goto :menu
)
if errorlevel 1 (
set "excel_file=C:\c\cgi.xlsx"
cls
xlsx2csv %excel_file% temp.csv

for /f "tokens=1,2,3,4,5 delims=," %%a in (temp.csv) do (
    set "ip=%%a"
    set "changedname0=%%b"
    set "changedname1=%%c"
    set "changedname2=%%d"
    set "changedname3=%%e"
    if not "%%b"=="" (
        curl -s --globoff --digest --user admin:"!password!" --max-time 2 "http://!ip!/cgi-bin/configManager.cgi?action=setConfig&ChannelTitle[0].Name=%%b" > NUL
    )
    if not "%%c"=="" (
        curl -s --globoff --digest --user admin:"!password!" --max-time 2 "http://!ip!/cgi-bin/configManager.cgi?action=setConfig&ChannelTitle[1].Name=%%c" > NUL
    )
    if not "%%d"=="" (
        curl -s --globoff --digest --user admin:"!password!" --max-time 2 "http://!ip!/cgi-bin/configManager.cgi?action=setConfig&ChannelTitle[2].Name=%%d" > NUL
    )
    if not "%%e"=="" (
        curl -s --globoff --digest --user admin:"!password!" --max-time 2 "http://!ip!/cgi-bin/configManager.cgi?action=setConfig&ChannelTitle[3].Name=%%e" > NUL
    )   
    if !errorlevel! equ 0 (
        echo Requests for !ip! succeeded.
    ) else (
        echo Requests for !ip! failed.
    )

)

del temp.csv
pause
goto :menu
)


:get_channel_title
echo Get Dahua channel title (useful to DVR)
set /p password="Password: "
set /p num_channels="Enter number of channels to process (0-30): "
choice /c YN /n /m "Confirm? (Y/N)"
if errorlevel 2 (
    echo Canceled
    pause
    goto :menu
)

if errorlevel 1 (
    set "excel_file=C:\c\cgi.xlsx"
    cls
    echo IP ChannelTitles
    xlsx2csv %excel_file% temp.csv

    for /f "tokens=1 delims=," %%a in (temp.csv) do (
        set "ip=%%a"
        echo.
        call :process_gettitle %%a %num_channels%
        echo.
    )

    del temp.csv
    pause
    goto :menu
)

:process_gettitle
set "ip=%1"
set "num_channels=%2"
setlocal enabledelayedexpansion

set "titles="
for /l %%i in (0,1,%num_channels%) do (
    curl -s --globoff --digest --user admin:"%password%" --max-time 2 "http://%ip%/cgi-bin/configManager.cgi?action=getConfig&name=ChannelTitle[%%i].Name" 2>nul > temp_title.txt

    if exist temp_title.txt (
        for /f "tokens=2 delims==" %%A in (temp_title.txt) do (
            set "title=%%A"
            if not "!title!"=="ChannelTitle[%%i].Name" (
                set "titles=!titles! !title!"
            )
        )
        del temp_title.txt
    ) else (
        goto :end_process_ip
    )
)

:end_process_ip
setlocal enabledelayedexpansion
echo %ip%!titles!
endlocal
goto :eof

:set_password
echo Set Dahua "New password"
set /p password="Old password: "
set /p password1="New password: "
choice /c YN /n /m "Confifm? Y/N"
if errorlevel 2 (
echo canceled
pause
goto :menu
)
if errorlevel 1 (
set "excel_file=C:\c\cgi.xlsx"
cls
xlsx2csv %excel_file% temp.csv

for /f "tokens=1,2 delims=," %%a in (temp.csv) do (
    set "ip=%%a"

    for %%c in (
        "name=General.MachineName"
            ) do (
        echo.
        curl -s --globoff --digest --user admin:"!password!" --max-time 2 "http://!ip!/cgi-bin/userManager.cgi?action=modifyPassword&name=admin&pwd=!password1!&pwdOld=!password!"
        echo.
    )

    if !errorlevel! equ 0 (
    echo !ip! found
      
    ) else (
    echo !ip! not found
    )
)

del temp.csv
pause
goto :menu
)