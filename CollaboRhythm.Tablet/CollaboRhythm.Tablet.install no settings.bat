::cls
@echo off

:: ***************************************************************************************
:: Note: before using this install script you should change the variables below

set AndroidADBFolder="/Users/breezy/Development/AndroidSDK/platform-tools"
:: Android default path used to include the word "windows", so you might need this depending on the version you have
set SettingsFile="/Users/breezy/Library/Preferences/CollaboRhythm.Tablet.Emulator/Local Store/settings.xml"
set CollaboRhythmTabletApk="bin-debug/CollaboRhythm.Tablet.apk"

:: ***************************************************************************************

color f9
echo -----------------------------------------------------------------------
echo Installing CollaboRhythm Tablet on your Android device...
echo.
echo Please do not close this window.
::echo   After the application is installed and launched this screen will close automatically.
echo.
echo Settings: %SettingsFile%
echo.

adb push %SettingsFile% "/storage/sdcard0/air.CollaboRhythm.Tablet.debug/CollaboRhythm.Tablet.debug/Local Store/settings.xml"
adb push "/Users/breezy/Library/Preferences/CollaboRhythm.Tablet.Emulator/Local Store/plugins" "/storage/sdcard0/air.CollaboRhythm.Tablet.debug/CollaboRhythm.Tablet.debug/Local Store"

adb -d uninstall %CollaboRhythmTabletApk%
adb -d install -r %CollaboRhythmTabletApk%
adb shell am start -a android.intent.action.MAIN -n CollaboRhythm.Tablet/.AppEntry

::"%AndroidADBFolder%"\adb -d uninstall collaboRhythm.android.deviceGateway
::"%AndroidADBFolder%"\adb -d install -r CollaboRhythm.Android.DeviceGateway.apk
::"%AndroidADBFolder%"\adb shell am start -a android.intent.action.MAIN -n collaboRhythm.android.deviceGateway/.DeviceGatewayActivity
				  
echo.
echo Install complete for %CollaboRhythmTabletApk% and %SettingsFile%
echo.

pause
