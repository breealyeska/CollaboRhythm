::cls
@echo off

:: ***************************************************************************************
:: Note: before using this install script you should change the variables below

set AndroidADBFolder=/Applications/Android Studio.app/sdk/platform-tools
:: Android default path used to include the word "windows", so you might need this depending on the version you have
::set AndroidADBFolder=/Applications/Android Studio.app/sdk/platform-tools
::set SettingsFile=my_settings_debug.xml
set SettingsFile=/Users/breezy/AppData/Roaming/CollaboRhythm.Tablet.debug/Local Store/settings.xml

:: ***************************************************************************************

color f9
echo -----------------------------------------------------------------------
echo Copying CollaboRhythm Tablet settings from your Android device...
echo.
echo Please do not close this window.
echo.
echo Settings: %SettingsFile%
echo.

"%AndroidADBFolder%"\adb pull "/data/local/air.CollaboRhythm.Tablet.debug/CollaboRhythm.Tablet.debug/Local Store/settings.xml" "%SettingsFile%"
				  
echo.
echo Copy complete for %SettingsFile%
echo.

pause
