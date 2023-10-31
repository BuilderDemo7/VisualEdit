@echo off
color 9
echo LuaRT Lua Framework v1.5.2
echo      Building VisualEdit.wlua to bin/VisualEdit.exe ...
echo #===============================
echo Creating dynamic:
rtc -lcanvas.dll -w VisualEdit.wlua -o bin/VisualEdit.exe
echo ===============================
echo Compilation done.
echo ...
echo ...
pause
