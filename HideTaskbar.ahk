#SingleInstance, Force
#Persistent

taskbarVisible:=0
GoSub, HideTaskbar
return

HideTaskbar:
WinHide, ahk_class Shell_TrayWnd
WinHide, Start ahk_class Button
SetTimer, HideTaskbar, -1000
return

ShowTaskbar:
WinShow, ahk_class Shell_TrayWnd
WinShow, Start ahk_class Button
SetTimer, HideTaskbar, Off
return

^#!F12::
taskbarVisible:=!taskbarVisible
if(taskbarVisible)
    GoSub, ShowTaskbar
else
    GoSub, HideTaskbar
return
