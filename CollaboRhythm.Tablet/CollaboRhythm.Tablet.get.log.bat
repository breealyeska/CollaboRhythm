::cls
@echo off

:: ***************************************************************************************
:: Note: before using this install script you should change the variables below

set AndroidADBFolder=/Applications/Android Studio.app/sdk/platform-tools
:: Android default path used to include the word "windows", so you might need this depending on the version you have
::set AndroidADBFolder=/Applications/Android Studio.app/sdk/platform-tools
set LogDirectory=currentSubjectLogs

:: ***************************************************************************************

color f9
echo -----------------------------------------------------------------------
echo Copying CollaboRhythm Tablet Log from your Android device...
echo.
echo Please do not close this window.
echo.
echo Destination log directory: %LogDirectory%
echo.

"%AndroidADBFolder%"\adb pull "/storage/sdcard0/CollaboRhythm.Tablet.debug/collaboRhythm.log" "%LogDirectory%/collaboRhythm.log"
"%AndroidADBFolder%"\adb pull "/storage/sdcard0/CollaboRhythm.Tablet.debug/old_logs" "%LogDirectory%/old_logs"
				  
echo.
echo Copy complete for %LogDirectory%
echo.

pause
