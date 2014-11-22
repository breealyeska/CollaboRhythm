::cls
@echo off

:: ***************************************************************************************
:: Note: before using this install script you should change the variables below

set AndroidADBFolder="/Users/breezy/Development/AndroidSDK/platform-tools"
:: Android default path used to include the word "windows", so you might need this depending on the version you have
set SettingsFile="/Users/breezy/Library/Preferences/CollaboRhythm.Tablet.Emulator/Local Store/settings.xml"

:: ***************************************************************************************

color f9
echo -----------------------------------------------------------------------
echo Removing CollaboRhythm Tablet settings from your Android device...
echo.
echo Please do not close this window.
echo.
echo Settings: %SettingsFile%
echo.

"%AndroidADBFolder%"\adb shell rm "/storage/sdcard0/air.CollaboRhythm.Tablet.debug/CollaboRhythm.Tablet.debug/Local Store/settings.xml"
				  
echo.
echo Remove complete for %SettingsFile%
echo.

pause
