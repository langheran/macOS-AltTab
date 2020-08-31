#SingleInstance, Force
#Persistent
#WinActivateForce

taskbarVisible:=0
GoSub, HideTaskbar
return

HideTaskbar:
WinHide, ahk_class Shell_TrayWnd
WinHide, Start ahk_class Button
SetTimer, HideTaskbar, -1000
WinHide, ahk_class NotifyIconOverflowWindow
return

ShowTaskbar:
SetTimer, HideTaskbar, Off
WinShow, ahk_class Shell_TrayWnd
WinActivate, ahk_class Shell_TrayWnd
WinSet, AlwaysOnTop, On, ahk_class Shell_TrayWnd
WinShow, Start ahk_class Button
WinShow, ahk_class NotifyIconOverflowWindow
WinActivate, ahk_class NotifyIconOverflowWindow
WinSet, AlwaysOnTop, On, ahk_class NotifyIconOverflowWindow
ControlClick,Button2,ahk_class Shell_TrayWnd
return

^#!F12::
taskbarVisible:=!taskbarVisible
if(taskbarVisible)
    GoSub, ShowTaskbar
else
    GoSub, HideTaskbar
return
