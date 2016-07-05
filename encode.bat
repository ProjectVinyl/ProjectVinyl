@echo off
set INPUT=%1
set TEMP=%2
set OUTPUT=%3

if exist %TEMP% (
    echo false
) else (
    ffmpeg -n -hide_banner -nostats -loglevel panic -i %INPUT% -c:v libvpx -crf 10 -b:v 1M -c:a libvorbis %TEMP%
    if exist %TEMP% (
      copy /Y %TEMP% %OUTPUT%
      del %TEMP%
    )
    echo true
)