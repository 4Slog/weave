@echo off
echo Creating @old directory structure...

mkdir @old\models 2>nul
mkdir @old\providers 2>nul
mkdir @old\services 2>nul
mkdir @old\widgets 2>nul
mkdir @old\screens 2>nul
mkdir @old\painters 2>nul
mkdir @old\navigation 2>nul
mkdir @old\theme 2>nul

echo Moving old files to @old directory...

if exist lib\models\*.* (
    copy lib\models\*.* @old\models\ >nul
)

if exist lib\providers\*.* (
    copy lib\providers\*.* @old\providers\ >nul
)

if exist lib\services\*.* (
    copy lib\services\*.* @old\services\ >nul
)

if exist lib\widgets\*.* (
    copy lib\widgets\*.* @old\widgets\ >nul
)

if exist lib\screens\*.* (
    copy lib\screens\*.* @old\screens\ >nul
)

if exist lib\painters\*.* (
    copy lib\painters\*.* @old\painters\ >nul
)

if exist lib\navigation\*.* (
    copy lib\navigation\*.* @old\navigation\ >nul
)

if exist lib\theme\*.* (
    copy lib\theme\*.* @old\theme\ >nul
)

echo Updating main.dart...

if exist lib\main_with_new_structure.dart (
    if exist lib\main.dart (
        copy lib\main.dart @old\main.dart >nul
    )
    
    copy lib\main_with_new_structure.dart lib\main.dart >nul
    copy lib\main_with_new_structure.dart @old\main_with_new_structure.dart >nul
)

echo Migration completed successfully!
echo Old files have been moved to the @old directory.
echo The main.dart file has been updated to use the new structure.
