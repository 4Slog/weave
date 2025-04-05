@echo off
echo Fixing migration issues...

echo Moving remaining old directories from lib to @old...

if exist lib\models\*.* (
    xcopy lib\models\*.* @old\models\ /s /i /y
    rd /s /q lib\models
)

if exist lib\navigation\*.* (
    xcopy lib\navigation\*.* @old\navigation\ /s /i /y
    rd /s /q lib\navigation
)

if exist lib\painters\*.* (
    xcopy lib\painters\*.* @old\painters\ /s /i /y
    rd /s /q lib\painters
)

if exist lib\providers\*.* (
    xcopy lib\providers\*.* @old\providers\ /s /i /y
    rd /s /q lib\providers
)

if exist lib\screens\*.* (
    xcopy lib\screens\*.* @old\screens\ /s /i /y
    rd /s /q lib\screens
)

if exist lib\services\*.* (
    xcopy lib\services\*.* @old\services\ /s /i /y
    rd /s /q lib\services
)

if exist lib\theme\*.* (
    xcopy lib\theme\*.* @old\theme\ /s /i /y
    rd /s /q lib\theme
)

if exist lib\widgets\*.* (
    xcopy lib\widgets\*.* @old\widgets\ /s /i /y
    rd /s /q lib\widgets
)

if exist lib\main_with_new_structure.dart (
    copy lib\main_with_new_structure.dart @old\main_with_new_structure.dart /y
    del lib\main_with_new_structure.dart
)

echo Migration fix completed successfully!
echo Old directories have been moved to the @old directory.
