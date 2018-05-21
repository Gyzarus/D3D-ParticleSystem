@echo off
::以下设置要统计的文件夹路径
set "Dir=F:\Program Files\project0\new"
 
echo 正在统计文件总行数，请耐心等待。。。。
for /r "%Dir%" %%a in (*) do (
    for /f "delims=" %%b in ('type "%%~a"') do set /a Line+=1
)
cls&echo 所有文件总行数：%Line%
pause