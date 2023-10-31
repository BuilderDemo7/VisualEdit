@echo off
echo LuaRT Lua Framework v1.5.2
echo Building VisualEdit.wlua to VisualEdit.exe ...
rtc -w VisualEdit.wlua -o bin/VisualEdit.exe
echo Compilation done.
pause