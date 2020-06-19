
#NoEnv
#HotkeyInterval 1000
#MaxHotkeysPerInterval 800
#KeyHistory 0
#InstallKeybdHook

#Include RunAsTask.ahk
RunAsTask()

ListLines Off
Process, Priority, , A
SetBatchLines, -1
SetKeyDelay, -1, -1
SetMouseDelay, -1
SetDefaultMouseSpeed, 0
SetWinDelay, -1
SetControlDelay, -1
SendMode Input

;#NoTrayIcon
#SingleInstance,Force 
#NoEnv

#Include switchDesktop.ahk

return

!CapsLock::
^CapsLock::
switchDesktop:
mainDesktop:=!mainDesktop
switchToDesktop(mainDesktop+1)
return

!Tab::
WinGet, exename, ProcessName,A
WinGet, active_id, ID, A
IdList:=WinsGetProcesses(0)
IdListCount:=IdList._MaxIndex()
WS_BORDER := 0x00800000
Gui, 2: +AlwaysOnTop +ToolWindow -SysMenu -Caption
Gui, 2:  Margin, 20, 20
Loop % IdListCount{
	winget, winpid, PID, % "ahk_id " IdList[A_Index]
	WinGet FileName, ProcessPath, % "ahk_id " IdList[A_Index]
	ptr := A_PtrSize =8 ? "ptr" : "uint"   ;for AHK Basic
	hIcon := DllCall("Shell32\ExtractAssociatedIcon" (A_IsUnicode ? "W" : "A"), ptr, DllCall("GetModuleHandle", ptr, 0, ptr), str, FileName, "ushort*", lpiIcon, ptr)   ;only supports 32x32

	i:=A_Index
	sep:=10
	if(i==1)
		sep:=0
	Gui, 2:  Add, Text, w32 h32 x+%sep% y20 vText%i% hwndmyIcon%i% 0x3 ; 0x3 = SS_ICON
	myIcon:=myIcon%i%
	SendMessage, STM_SETICON := 0x0170, hIcon, 0,, Ahk_ID %myIcon%
}
Gui, 2:  Show
count:=0
While(GetKeyState("Alt", "P") || GetKeyState("LWin", "P") || count=0)
{
	if (GetKeyState("Tab", "P") || count=0)
	{
		WinSet, Style, -%WS_BORDER%, ahk_id %myIcon%
		shiftPressed := GetKeyState("Shift")
		count:=count+1-2*shiftPressed
		if(count<0)
			count:=IdList._MaxIndex()
		i:=Abs(Mod(count,IdListCount))+1
		myIcon:=myIcon%i%
		WinSet, Style, +%WS_BORDER%, ahk_id %myIcon%
		prevWindowId:=IdList[i]
		KeyWait Tab
	}
	if GetKeyState("Esc", "P")
	{
		WinGet, close_exename, ProcessName, % "ahk_id " . prevWindowId
		Gui, 2: -AlwaysOnTop
		MsgBox, 4,CERRAR, Cerrar %close_exename%? (Si o No)
		IfMsgBox, Yes
		{
			IdList:=WinsGetWindows(close_exename,0)
			Loop, % IdList._MaxIndex(){
				WinClose, % "ahk_id " . IdList[A_Index]
			}
		}
	}
}
Gui, 2:  Destroy
Loop 5
{
	WinActivate, % "ahk_id " . prevWindowId
	Sleep, 10
}
return

#Tab::
WinGet, exename, ProcessName,A
WinGet, active_id, ID, A
IdList:=WinsGetWindows(exename,0)
count:=0
count := 0
	IdListCount:=IdList._MaxIndex()
	WinGet, active_id, ID, A
	AlwaysOnTopArray:=[]
	
	Loop % IdListCount {
		WinGet, ExStyle, ExStyle, % "ahk_id " IdList[A_Index]
		If (ExStyle & 0x8)
			AlwaysOnTop:= 1
		Else
			AlwaysOnTop:= 0
		AlwaysOnTopArray.Insert(AlwaysOnTop)
	}

	Loop % IdListCount {
		WinSet, AlwaysOnTop, Off, % "ahk_id " . IdList[A_Index]
	}
	prevWindowId:=0
	While(GetKeyState("Alt", "P") || GetKeyState("LWin", "P") || count=0)
	{
		if (GetKeyState("Tab", "P") || count=0)
		{
			count:=count+1
			if(prevWindowId)
				WinSet, AlwaysOnTop, Off, % "ahk_id " . prevWindowId
			prevWindowId:=IdList[Mod(count,IdListCount)+1]
			WinSet, AlwaysOnTop, On, % "ahk_id " . prevWindowId
			WinGet MX, MinMax, % "ahk_id " . prevWindowId
			If (MX==-1)
				WinRestore, % "ahk_id " . prevWindowId
			KeyWait Tab
			; WinSet, AlwaysOnTop, Off, % "ahk_id " . IdList[Mod(count,IdListCount)+1]
		}
	}
	Loop % IdListCount {
		WinSet, AlwaysOnTop, Off, % "ahk_id " . IdList[A_Index]
	}
	WinSet, AlwaysOnTop, Off, % "ahk_id " . active_id
	WinSet, AlwaysOnTop, On, % "ahk_id " . prevWindowId
	Loop 3{
		WinActivate, % "ahk_id " . active_id
		WinActivate, % "ahk_id " . prevWindowId
		Sleep, 50
	}
	Loop % IdListCount {
		if(AlwaysOnTopArray[A_Index]==1)
			WinSet, AlwaysOnTop, On, % "ahk_id " . IdList[A_Index]
		else
			WinSet, AlwaysOnTop, Off, % "ahk_id " . IdList[A_Index]
	}
return

CapsLock::
KeyWait CapsLock
KeyWait CapsLock, D T0.2
if (ErrorLevel = 0)
{
	KeyWait CapsLock
	KeyWait CapsLock, D T0.2
	if (ErrorLevel = 0)
	{
		GoSub, switchDesktop
	}
	else
	{
		WinGet, exename, ProcessName,A
		next_program:=WinsGetProcesses(0,exename)[1]
		WinActivate, % "ahk_id " . next_program
	}
}
else
{
	WinGet, exename, ProcessName,A
	WinGet, ahkid, ID,A
	next_program:=WinsGetWindows(exename,0,ahkid)[1]
	WinActivate, % "ahk_id " . next_program
}
return

#IfWinActive ahk_exe Mac-AltTab.exe
$Esc::
	ControlClick, Button2, A
return
#IfWinActive

WinsGetWindows(ahk_exe, dir=0, exclude="") {
	DetectHiddenWindows, Off
	ListArray:=[]
	ListArrayDict:={}
    WinGet, myList, list
    Loop % myList {
		if(!dir)
			index:=A_Index
		else
			index:=myList - A_Index
        WinGetPos, winX, winY, winW, winH, % "ahk_id " myList%index% 
		WinGetTitle, title, % "ahk_id " myList%index%
		WinGetClass, class, % "ahk_id " myList%index%
		WinGet, exename, ProcessName, % "ahk_id " myList%index%
		WinGet MX, MinMax, % "ahk_id " myList%index%
		WinGet, ExStyle, ExStyle, % "ahk_id " myList%index%
		If (ExStyle & 0x8)
			isontop = 1
		Else
			isontop = 0
        If (title!="")
		&& (title!="Program Manager")
		&& (class!="")
		&& (class!="WorkerW")
		&& (class!="Cortana")
		&& (exename!="video.exe")
		&& (!isontop)
		&& (exename!="spritz.exe")
		&& (exename!="clock.exe")
		&& (myList%index%!=exclude)
		&& (exename=ahk_exe)
		&& (WinIsVisible(myList%index%))
		{
			ListArray.Insert(myList%index%)
		}
    }
    return ListArray
}

WinsGetProcesses(dir=0, exclude="") {
	DetectHiddenWindows, Off
	ListArray:=[]
	ListArrayDict:={}
    WinGet, myList, list
    Loop % myList {
		if(!dir)
			index:=A_Index
		else
			index:=myList - A_Index
        WinGetPos, winX, winY, winW, winH, % "ahk_id " myList%index% 
		WinGetTitle, title, % "ahk_id " myList%index%
		WinGetClass, class, % "ahk_id " myList%index%
		WinGet, exename, ProcessName, % "ahk_id " myList%index%
		WinGet MX, MinMax, % "ahk_id " myList%index%
		WinGet, ExStyle, ExStyle, % "ahk_id " myList%index%
		If (ExStyle & 0x8)
			isontop = 1
		Else
			isontop = 0
        If (title!="")
		&& (title!="Program Manager")
		&& (class!="")
		&& (class!="WorkerW")
		&& (class!="Cortana")
		&& (exename!="video.exe")
		&& (!isontop)
		&& (exename!="spritz.exe")
		&& (exename!="clock.exe")
		&& (exename!="")
		&& (WinIsVisible(myList%index%))
		{
			if(!ListArrayDict.HasKey(exename) && exclude!=exename)
			{
				ListArrayDict[exename]:=1
				ListArray.Insert(myList%index%)
			}
		}
    }
    return ListArray
}

IsInvisibleWin10BackgroundAppWindow(hWindow) {
  result := 0
  VarSetCapacity(cloakedVal, A_PtrSize) ; DWMWA_CLOAKED := 14
  hr := DllCall("DwmApi\DwmGetWindowAttribute", "Ptr", hWindow, "UInt", 14, "Ptr", &cloakedVal, "UInt", A_PtrSize)
  if !hr ; returns S_OK (which is zero) on success. Otherwise, it returns an HRESULT error code
    result := NumGet(cloakedVal) ; omitting the "&" performs better
  return result ? true : false
}

WinIsVisible(ahk_id="A"){
	hWindow:=ahk_id
	if(ahk_id!="A")
	{
		ahk_id := "ahk_id " . ahk_id
	}
	else
	{
		WinGet, hWindow, ID, A
	}
	WinGet, Active_Process, ProcessName, ahk_id %hWindow%
	 WinGet, es, ExStyle, ahk_id %hWindow%
      return (Active_Process<>"spritz.exe") && (!((es & WS_EX_TOOLWINDOW) && !(es & WS_EX_APPWINDOW)) && !IsInvisibleWin10BackgroundAppWindow(hWindow))
}