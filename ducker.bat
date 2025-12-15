rem Set local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" setlocal

set CM="docker"
set CATEGORY=%1
set COMMAND=%2
set TARGET=%3

if "%CATEGORY%" == "shell" goto shell
if "%CATEGORY%" == "compose" goto compose
if "%CATEGORY%" == "list" goto list
if "%CATEGORY%" == "image" goto image
if "%CATEGORY%" == "container" goto container

    echo Usage: ducker [container|image|list] <command> <arguments>
    echo.
    echo General Commands:
    echo  - list                     Prints out a list of installed docker images and containers
    echo.
    echo Image Commands:
    echo  - build <image name>     Builds and installs a docker image from a dockerfile in the current directory
    echo  - install <image name>     Downloads and installs a docker image
    echo  - remove <image name>      Removes an image previously downloaded using ducker image install
    echo  - list
    echo.
    echo Container Commands:
    echo  - create <image name>         Creates a new container and connects to it
    echo  - start <container name>      Restarts a container
    echo  - stop <container name>       Stops a container
    echo  - drop <container name>       Shuts down and removes an existing container
    echo  - reconnect <container name>  Connects to an existing container
    echo  - list
    goto end

:list
    echo Images:; %CM% images
    echo Containers:; %CM% ps -a
    goto end

:image
    if "%COMMAND%" == "install" goto image_install
    if "%COMMAND%" == "remove" goto image_remove
    if "%COMMAND%" == "build" goto image_build
    echo 'Images:'; %CM% images
    goto end

:image_install
    %CM% image pull %TARGET%
    goto end

:image_remove
    %CM% image rm %TARGET% -f
    goto end

:image_build
    %CM% build -t %TARGET% .
    goto end

:container
    if "%COMMAND%" == "drop" goto container_drop
    if "%COMMAND%" == "start" goto container_start
    if "%COMMAND%" == "stop" goto container_stop
    if "%COMMAND%" == "create" goto container_create
    if "%COMMAND%" == "reconnect" goto container_reconnect
    echo Containers:
    %CM% ps -a
    goto end

:container_drop
    %CM% rm %TARGET%
    goto end

:container_start
     %CM% start --attach %TARGET%
     goto end

:container_stop
    then %CM% container stop %TARGET%
    goto end

:container_create
    rem https://stackoverflow.com/a/108511/4840774
    rem NB:in a batch file, need to use %%i not %i
    setlocal EnableDelayedExpansion
    set lf=-
    FOR /F "delims=" %%i IN ('%CM% run -dit %TARGET%') DO if ("!out!"=="") (set out=%%i) else (set out=!out!%lf%%%i)
    %CM% attach %out%
    goto end

:container_reconnect
    %CM% attach %3
    goto end

:compose
    if "%COMMAND%" == "shell" goto compose_shell
    %CM% compose up --build
    goto end

:compose_shell
    %CM% compose run --rm app
    goto end

:shell
    %CM% exec -it %COMMAND% bash
    goto end

:end
    if "%OS%"=="Windows_NT" endlocal
