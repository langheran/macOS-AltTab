#NoEnv
#HotkeyInterval 1000
#MaxHotkeysPerInterval 800
#KeyHistory 0
#InstallKeybdHook
#WinActivateForce

#Include, Gdip_All.ahk
pToken := Gdip_Startup()
wsBorder:={}
wsNoBorder:={}
wsIcon:={}
wsTitle:={}
lastWS:={}
hwnds:={}
bgrColor := "111111"
makeTranslucent:=1
WS_BORDER := 0x00800000
OnExit Exit
SetTimer, RefreshWS, 30000

#Include RunAsTask.ahk
RunAsTask()
OnMessage(0x404, "AHK_NOTIFYICON")

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

CleanObjects:
For Key, hBitmap in wsBorder{
	DeleteObject(hBitmap)
}
For Key, hBitmap in wsNoBorder{
	DeleteObject(hBitmap)
}
For Key, hBitmap in wsIcon{
	DeleteObject(hBitmap)
}
Gdip_Shutdown(pToken)
return

Exit:
GoSub, CleanObjects
ExitApp

!CapsLock::
^CapsLock::
switchDesktop:
mainDesktop:=!mainDesktop
switchToDesktop(mainDesktop+1)
return

CloseStartMenu:
WinClose ahk_class Windows.UI.Core.CoreWindow ahk_exe SearchUI.exe
WinClose ahk_class Windows.UI.Core.CoreWindow ahk_exe StartMenuExperienceHost.exe
Process Close, StartMenuExperienceHost.exe
return

#If StartMenuVisible()
Esc::
GoSub, CloseStartMenu
return
#If

StartMenuVisible(){
WinGet name, ProcessName, A
return InStr(name, "SearchUI.exe")
}

!Tab::
WinGet, active_id, ID, A
if(!active_id)
{
	IdList:=WinsGetProcesses(0)
	WinActivate, "ahk_id " . IdList[1]
}
WinGet, refresh_id, ID, A
SetTimer, RefreshWin, -10
GoSub, CloseStartMenu
WinGet, exename, ProcessName,A
IdList:=WinsGetProcesses(0)
IdListCount:=IdList._MaxIndex()
Gui, 2: +AlwaysOnTop +ToolWindow -SysMenu -Caption +LastFound +hwndhGui
guid_id:=WinExist()
Gui, 2:  Margin, 20, 20
Loop % IdListCount{
	winget, winpid, PID, % "ahk_id " IdList[A_Index]
	WinGet FileName, ProcessPath, % "ahk_id " IdList[A_Index]
	ptr := A_PtrSize =8 ? "ptr" : "uint"   ;for AHK Basic
	hIcon := DllCall("Shell32\ExtractAssociatedIcon" (A_IsUnicode ? "W" : "A"), ptr, DllCall("GetModuleHandle", ptr, 0, ptr), str, FileName, "ushort*", lpiIcon, ptr)   ;only supports 32x32
	i:=A_Index
	hwnds[A_Index]:=IdList[A_Index]
	sep:=10
	if(i==1)
		sep:=0
	if(!makeTranslucent)
	{
		Gui, 2:  Add, Text, w32 h32 x+%sep% y20 gSelectWindow vIcon%i% hwndmyIcon%i% 0x3 ; 0x3 = SS_ICON
		myIcon:=myIcon%i%
		SendMessage, STM_SETICON := 0x0170, hIcon, 0,, Ahk_ID %myIcon%
	} 
	else
	{
		Gui, 2: Add, Picture, w42 h42 x+%sep% y20 gSelectWindow hwndmyIconBackground%i%  +0xE
		myIconBackground:=myIconBackground%i%
		SetTitleFrameText(42*(A_ScreenDPI/96),42*(A_ScreenDPI/96),0xff721CAA,"", myIconBackground)
		WinSet, Style, +%WS_BORDER%, ahk_id %myIconBackground%
		GuiControl, Hide,    % myIconBackground
		Gui, 2: Add, Picture, w32 h32 xp+5 yp+5 gSelectWindow BackgroundTrans vIcon%i% hwndmyIcon%i%  +0xE
		myIcon:=myIcon%i%
		pBitmapI :=Gdip_CreateBitmapFromHICON(hIcon)
		hBitmapI := Gdip_CreateHBITMAPFromBitmap(pBitmapI)
		SetImage(myIcon, hBitmapI)
		DeleteObject(hBitmapI)
		Gdip_DisposeImage(pBitmapI)
	}
	DeleteObject(hIcon)
}
if(!makeTranslucent)
{
	;Gui, 2: Color, 333333
}
else
{
	Gui, 2: Color, c%bgrColor%
	SetAcrylicGlassEffect(bgrColor, 9, hGui)
}
Gui, 2:  Show, NoActivate 
count:=0
prevWindowId:=""
selectWindow:=0
While((GetKeyState("Alt", "P") || GetKeyState("LWin", "P") || count=0) && !selectWindow)
{
	if (GetKeyState("Tab", "P") || count=0)
	{
		if(!makeTranslucent)
		{
			WinSet, Style, -%WS_BORDER%, ahk_id %myIcon%
		}
		else
		{
			GuiControl, Hide,    % myIconBackground
			GuiControl, +Redraw,    % myIcon
		}
		shiftPressed := GetKeyState("Shift")
		count:=count+1-2*shiftPressed
		if(count<0)
			count:=IdList._MaxIndex()
		i:=Abs(Mod(count,IdListCount))+1
		myIcon:=myIcon%i%
		if(!makeTranslucent)
		{
			WinSet, Style, +%WS_BORDER%, ahk_id %myIcon%
		}
		else
		{
			myIconBackground:=myIconBackground%i%
			GuiControl, Show,    % myIconBackground
			GuiControl, +Redraw,    % myIcon
		}
		prevWindowId:=IdList[i]
		KeyWait Tab
	}
	if (GetKeyState("Esc"))
	{
		prevWindowId:=""
		break
	}
	if GetKeyState("BS", "P")
	{
		WinGet, close_exename, ProcessName, % "ahk_id " . prevWindowId
		Gui, 2: -AlwaysOnTop
		MsgBox, 4,CERRAR, Cerrar %close_exename%? (Si o No)
		IfMsgBox, Yes
		{
			GoSub, CloseExeByName
		} else {
			prevWindowId:=""
			break
		}
	}
}
WinMove, % "ahk_id " . guid_id,, -100, -100, 0, 0
if(prevWindowId!="")
{
	Loop, % 5
	{
		WinActivate, % "ahk_id " . prevWindowId
		Sleep, 10
	}
}
Gui, 2:  Cancel
Gui, 2:  Destroy
return

RemoveToolTip:
ToolTip
return

#IfWinNotExist, ahk_exe Mac-AltTab.exe
#BS::
WinGet, close_exename, ProcessName, A
CloseExeByName:
IdList:=WinsGetWindows(close_exename,0)
Loop, % IdList._MaxIndex(){
	close_id := IdList[A_Index]
	WinActivate, % "ahk_id " . close_id
	WinGetTitle, close_title, % "ahk_id " . close_id
	MsgBox, 4,CERRAR, Cerrar %close_title%? (Si o No)
	IfMsgBox, Yes
	{
		WinClose, % "ahk_id " . close_id
	}
}
return
#If

#Tab::
if(0)
{
	GoSub, CloseStartMenu
	CoordMode, Tooltip, Screen
	WinGet, exename, ProcessName,A
	WinGet, active_id, ID, A
	IdList:=WinsGetWindows(exename,0)
	count:=0
	IdListCount:=IdList._MaxIndex()
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
	close_exename:=""
	While(GetKeyState("Alt", "P") || GetKeyState("LWin", "P") || count=0)
	{
		if (GetKeyState("Tab", "P") || count=0)
		{
			if(prevWindowId)
				WinSet, AlwaysOnTop, Off, % "ahk_id " . prevWindowId
			shiftPressed := GetKeyState("Shift")
			count:=count+1-2*shiftPressed
			if(count<0)
				count:=IdList._MaxIndex()
			i:=Abs(Mod(count,IdListCount))+1
			prevWindowId:=IdList[i]
			WinSet, AlwaysOnTop, On, % "ahk_id " . prevWindowId
			WinGetTitle, Title, % "ahk_id " . prevWindowId
			WinGetPos, X, Y, Width, Height, % "ahk_id " . prevWindowId
			position:= "" . i . "/" .  IdList._MaxIndex()
			CalculateToolTipDisplayRight(position)
			ToolTip, % position, % X+Width-tW-10 , %Y%
			SetTimer, RemoveToolTip, -5000
			WinGet MX, MinMax, % "ahk_id " . prevWindowId
			If (MX==-1)
				WinRestore, % "ahk_id " . prevWindowId
			KeyWait Tab
			; WinSet, AlwaysOnTop, Off, % "ahk_id " . IdList[Mod(count,IdListCount)+1]
		}
		if GetKeyState("Backspace", "P")
		{
			WinGet, close_exename, ProcessName, % "ahk_id " . prevWindowId
			break
		}
		if (GetKeyState("Esc"))
		{
			prevWindowId:=""
			break
		}
	}
	GoSub, RemoveToolTip
	if(prevWindowId)
	{
		Loop % IdListCount {
			WinSet, AlwaysOnTop, Off, % "ahk_id " . IdList[A_Index]
		}
		WinSet, AlwaysOnTop, Off, % "ahk_id " . active_id
		WinSet, AlwaysOnTop, On, % "ahk_id " . prevWindowId
		SetWinDelay, -1
		Loop % 2 {
			WinActivate, % "ahk_id " . active_id
			WinActivate, % "ahk_id " . prevWindowId
		}
	}
	Loop % IdListCount {
		if(AlwaysOnTopArray[A_Index]==1)
			WinSet, AlwaysOnTop, On, % "ahk_id " . IdList[A_Index]
		else
			WinSet, AlwaysOnTop, Off, % "ahk_id " . IdList[A_Index]
	}
	if(!prevWindowId)
	{
		WinGetPos, X, Y, Width, Height, % "ahk_id " . active_id
		position:="Activate"
		CalculateToolTipDisplayRight(position)
		ToolTip, % position, % X+Width-tW-10 , %Y%
		Loop % 4 {
			WinActivate, % "ahk_id " . active_id
			WinActivate, ahk_class tooltips_class32 ahk_exe %A_ScriptName%
		}
		GoSub, RemoveToolTip
	}
	if(close_exename)
	{
		MsgBox, 4,CERRAR, Cerrar %close_exename%? (Si o No)
		IfMsgBox, Yes
		{
			GoSub, CloseExeByName
		}
	}
}
else
{
	WinGet, active_id, ID, A
	if(!active_id)
	{
		IdList:=WinsGetProcesses(0)
		WinActivate, "ahk_id " . IdList[1]
	}
	WinGet, refresh_id, ID, A
	SetTimer, RefreshWin, -10
	GoSub, CloseStartMenu
	CoordMode, Tooltip, Screen
	WinGet, new_exename, ProcessName,A
	if(new_exename)
		exename:=new_exename
	IdList:=WinsGetWindows(exename,0)
	count:=0
	IdListCount:=IdList._MaxIndex()
	if(!IdListCount)
		return
	; If(IdListCount<3)
	; {
	; 	KeyWait LWin, U T0.2
	; 	if (ErrorLevel = 0)
	; 	{
	; 		prevWindowId:=IdList[2]
	; 		Loop, % 5
	; 		{
	; 			WinActivate, % "ahk_id " . prevWindowId
	; 			Sleep, 10
	; 		}
	; 		return
	; 	}
	; }
	Gui, 2: +AlwaysOnTop +ToolWindow -SysMenu -Caption +LastFound +hwndhGui
	guid_id:=WinExist()
	Gui, 2:  Margin, 20, 20
	Loop % IdListCount{
		i:=A_Index
		sep:="+10"
		if(Mod(i-1,5)=0)
			sep:="20"
		line:=(Floor((i-1)/5))
		y:=20+240*line
		y2:=153+240*line-5
		Gui 2:Add, Picture, % "x" . sep . " y" . y . " w230 h230 gSelectWindow vIcon" . i . " hwndmyIcon" . i . " +0xE"
		Gui 2:Add, Picture, % "xp+5 y" . y2 . " w230 h30 BackgroundTrans hwndThumbIcon" . i . " +0xE" ; 203
		image := myIcon%i%
		icon := ThumbIcon%i%
		sourceWin:=IdList[A_Index]
		hwnds[A_Index]:=sourceWin
		SetImage(image, getWsNoBorder(sourceWin))
		SetImage(icon, getWsIcon(sourceWin))
	}
	y:=20+240*(line+1)+10
	gwidth := Min(IdListCount,5)*230+(Min(IdListCount,5)-1)*10
	if(gwidth="")
		gwidth:=0
	min_win_width:=3
	gwidth:=Max(gwidth, min_win_width*230+(min_win_width-1)*10)
	gheight:=30
	if(!makeTranslucent)
	{
		Gui, 2: Font, SF Pro Display Bold
		Gui, 2: Add, Text, xp yp w%gwidth% h%gheight% +0x200 vTitleFrame cWhite +Left BackgroundTrans ReadOnly 0x1000, ;0x1000->ss_sunken +0x201->center +Center
		Gui, 2: Color, 333333
	}
	else
	{
		Gui, 2: Add, Picture, x20 y%y% w%gwidth% h%gheight% hwndTextBackground  +0xE
		gwidth1:=gwidth*(A_ScreenDPI/96)
		gheight1:=gheight*(A_ScreenDPI/96)
		Gui, 2: Color, c%bgrColor%
		SetAcrylicGlassEffect(bgrColor, 9, hGui)
	}
	Gui, 2:  Show, NoActivate 
	count:=0
	prevWindowId:=active_id
	selectWindow:=0
	While((GetKeyState("Alt", "P") || GetKeyState("LWin", "P") || count=0) && !selectWindow)
	{
		if (GetKeyState("Tab", "P") || count=0)
		{
			; refresh_id:=prevWindowId
			; SetTimer, RefreshWin, -1
			GuiControl, -Redraw,    % myIcon
			SetImage(myIcon, getWsNoBorder(prevWindowId))
			GuiControl, +Redraw,    % myIcon
			GuiControl, +Redraw,    % ThumbIcon
			WinSet, Style, -%WS_BORDER%, ahk_id %myIcon%

			shiftPressed := GetKeyState("Shift")
			count:=count+1-2*shiftPressed
			if(count<0)
				count:=IdList._MaxIndex()
			i:=Abs(Mod(count,IdListCount))+1
			myIcon:=myIcon%i%
			myIconBorder:=myIconBorder%i%
			ThumbIcon:=ThumbIcon%i%

			GuiControl, -Redraw,    % myIcon
			SetImage(myIcon, getWsBorder(IdList[i]))
			if(!makeTranslucent)
			{
				GuiControl, 2:, TitleFrame,% "  " . getWsTitle(IdList[i])
			}
			else
			{
				SetTitleFrameText(gwidth1,gheight1,0xff000000,getWsTitle(IdList[i]), TextBackground)
			}
			GuiControl, +Redraw,    % TextBackground
			GuiControl, +Redraw,    % myIcon
			GuiControl, +Redraw,    % ThumbIcon
			WinSet, Style, +%WS_BORDER%, ahk_id %myIcon%

			prevWindowId:=IdList[i]
			KeyWait Tab
		}
		if (GetKeyState("Esc"))
		{
			prevWindowId:=""
			break
		}
		if GetKeyState("BS", "P")
		{
			WinGet, close_exename, ProcessName, % "ahk_id " . prevWindowId
			Gui, 2: -AlwaysOnTop
			MsgBox, 4,CERRAR, Cerrar %close_exename%? (Si o No)
			IfMsgBox, Yes
			{
				Loop, % IdList._MaxIndex(){
					i:=Abs(Mod(count,IdListCount))+1
					close_id := IdList[i]
					WinActivate, % "ahk_id " . close_id
					WinGetTitle, close_title, % "ahk_id " . close_id
					MsgBox, 4,CERRAR, Cerrar %close_title%? (Si o No)
					IfMsgBox, Yes
					{
						WinClose, % "ahk_id " . close_id
					}
					count:=count+1
				}
			} else {
				prevWindowId:=""
				break
			}
		}
	}
	WinMove, % "ahk_id " . guid_id,, -100, -100, 0, 0
	if(prevWindowId!="")
	{
		Loop, % 5
		{
			WinActivate, % "ahk_id " . prevWindowId
			Sleep, 10
		}
	}
	Gui, 2:  Cancel
	Gui, 2:  Destroy
}
return

SelectWindow:
	iconNumber:=StrReplace(A_GuiControl, "Icon")
	prevWindowId:=hwnds[iconNumber]
	selectWindow:=1
return

CalculateToolTipDisplayRight(CData) {
	global tW
	global tH
	CoordMode, ToolTip, Screen
	ToolTip, %CData%,,A_ScreenHeight+100
	thisId:=WinExist()
	WinGetPos,,, tW, tH, ahk_class tooltips_class32 ahk_exe %A_ScriptName%
	ToolTip
	Return
}

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

;###########################################################
SetTitleFrameText(DstWidth,DstHeight, color, text, ctrl)
{
	pBitmapB := Gdip_CreateBitmap(DstWidth,DstHeight)
	GB := Gdip_GraphicsFromImage(pBitmapB)
	pBrush := Gdip_BrushCreateSolid(color)
	Gdip_FillRectangle(GB, pBrush, 0, 0, DstWidth, DstHeight)
	if(text)
	{
		Options := "x0 y5 h" . (DstHeight) . " w" . (DstWidth) . " s24 Left Bold cffffffff"
		Font := "SF Pro Display"
		Gdip_TextToGraphics(GB, " " . text, Options, Font, DstWidth, DstHeight)
	}
	hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmapB)
	SetImage(ctrl, hBitmap)
	DeleteObject(hBitmap)
	Gdip_DeleteBrush(pBrush)
	Gdip_DeleteGraphics(GB)
	Gdip_DisposeImage(pBitmapB)
}
CopyWinImgToCache(SourceWin,DstWidth, DstHeight)
{
global Bord
global wsBorder
global wsNoBorder
global wsIcon
global lastWS

WinGetTitle, Title, % "ahk_id " . SourceWin
Title:=limittext(Title)

lastWS[SourceWin]:=A_TickCount

Bord:=10
DstWidth:=DstWidth-Bord
DstHeight:=DstHeight-Bord
pBitmapI :=Gdip_CreateBitmapFromHICON(Get_Window_Icon(SourceWin))
w1 := Gdip_GetImageWidth(pBitmapI), h1 := Gdip_GetImageHeight(pBitmapI)
pBitmapI := Gdip_ResizepBitmap(pBitmapI, w1, h1, 128, 128, 0)
hBitmapI := Gdip_CreateHBITMAPFromBitmap(pBitmapI)

wsIcon[SourceWin]:=hBitmapI

pBitmap := 	Gdip_BitmapFromHWNDStretchToDst(SourceWin,DstWidth,DstHeight)
pBitmapB := Gdip_CreateBitmap(DstWidth+Bord, DstHeight+Bord)
GB := Gdip_GraphicsFromImage(pBitmapB)
pBrush := Gdip_BrushCreateSolid(0xff721CAA)
Gdip_FillRectangle(GB, pBrush, 0, 0, DstWidth+Bord, DstHeight+Bord)
Gdip_DeleteBrush(pBrush)
Gdip_DrawImage(GB, pBitmap, Bord/2, Bord/2, DstWidth, DstHeight, 0, 0, DstWidth, DstHeight)
pBrush := Gdip_BrushCreateSolid(0xff721CAA)
Gdip_FillRectangle(GB, pBrush, 0, 0, DstWidth+Bord, 32)
Gdip_DeleteBrush(pBrush)
Options := "x0 y5 h30 w" . (DstWidth-Bord) . " s20 Center Bold cffffffff"
Font := "SF Pro Display"
Gdip_TextToGraphics(GB, Title, Options, Font, DstWidth-Bord, 30)
hBitmapB := Gdip_CreateHBITMAPFromBitmap(pBitmapB)

wsBorder[SourceWin]:=hBitmapB

pBitmapW := Gdip_CreateBitmap(DstWidth+Bord, DstHeight+Bord)
G := Gdip_GraphicsFromImage(pBitmapW)
pBrush := Gdip_BrushCreateSolid(0xff333333)
Gdip_FillRectangle(G, pBrush, 0, 0, DstWidth+Bord, DstHeight+Bord)
Gdip_DeleteBrush(pBrush)
Gdip_DrawImage(G, pBitmap, Bord/2, Bord/2, DstWidth, DstHeight, 0, 0, DstWidth, DstHeight)
pBrush := Gdip_BrushCreateSolid(0xff333333)
Gdip_FillRectangle(G, pBrush, 0, 0, DstWidth+Bord, 32)
Gdip_DeleteBrush(pBrush)
Options := "x0 y5 h30 w" . (DstWidth-Bord) . " s20 Center Bold c99ffffff"
Font := "SF Pro Display"
Gdip_TextToGraphics(G, Title, Options, Font, DstWidth-Bord, 30)

hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmapW)

wsNoBorder[SourceWin]:=hBitmap

Gdip_DeleteGraphics(G)
Gdip_DeleteGraphics(GB)

Gdip_DisposeImage(pBitmap)
Gdip_DisposeImage(pBitmapB)
Gdip_DisposeImage(pBitmapW)
Gdip_DisposeImage(pBitmapI)
if pBitmap=0
	return false
return true
}

limittext(s,words=5,len=20)
{
  r := ""
  loop,parse,s,`t` -,
  {
    if (StrLen(r . " " . A_LoopField) > len)
      break
    r .= " " A_LoopField
    if (A_Index = words)
      break
  }
  if(r=="")
  loop,parse,s,`t` -,
  {
    r .= " " A_LoopField
    break
  }
  r:=LTrim(RTrim(r))
  if(SubStr(r, -1)=" -")
	r:=RTrim(LTrim(SubStr(r, 1, StrLen(r)-1)))
  return r
}

getWsTitle(sourceWin){
	global wsTitle
	global lastWS

	if(wsTitle.HasKey(sourceWin) && (A_TickCount - lastWS[sourceWin])<10000)
		return wsTitle[sourceWin]
	WinGetTitle, title, % "ahk_id " . sourceWin
	wsTitle[sourceWin]:=title
	lastWS[sourceWin]:=A_TickCount
	return wsTitle[sourceWin]
}

getWsBorder(sourceWin){
	global wsBorder
	global lastWS

	if(wsBorder.HasKey(sourceWin) && (A_TickCount - lastWS[sourceWin])<10000)
		return wsBorder[sourceWin]
	CopyWinImgToCache(sourceWin,300, 300)
	return wsBorder[sourceWin]
}

getWsNoBorder(sourceWin){
	global wsNoBorder
	global lastWS

	if(wsNoBorder.HasKey(sourceWin) && (A_TickCount - lastWS[sourceWin])<10000)
		return wsNoBorder[sourceWin]
	CopyWinImgToCache(sourceWin,300, 300)
	return wsNoBorder[sourceWin]
}

getWsIcon(sourceWin){
	global wsIcon
	global lastWS

	if(wsIcon.HasKey(sourceWin) && (A_TickCount - lastWS[sourceWin])<10000)
		return wsIcon[sourceWin]
	CopyWinImgToCache(sourceWin,300, 300)
	return wsIcon[sourceWin]
}

RefreshWin:
CopyWinImgToCache(refresh_id,300, 300)
return

RefreshWS:
if(WinExist("ahk_id " . guid_id))
	return
For Key, hBitmap in wsIcon{
	if(!WinExist("ahk_id " . Key)){
		DeleteObject(wsIcon[Key])
		DeleteObject(wsNoBorder[Key])
		DeleteObject(wsBorder[Key])
		wsIcon.Delete(Key)
		wsNoBorder.Delete(Key)
		wsBorder.Delete(Key)
		wsTitle.Delete(Key)
	}
	else
	{
		if(!WinActive("ahk_id " . Key)){
			WinGetTitle, title, % "ahk_id " . sourceWin
			wsTitle[sourceWin]:=title
			CopyWinImgToCache(Key,300, 300)
			lastWS[sourceWin]:=A_TickCount
		}
	}
}
if(Mod(A_TickCount, 30000)==0)
{
	; Reload
	GoSub, CleanObjects
	pToken := Gdip_Startup()
}
return

Get_Window_Icon(wid, Use_Large_Icons_Current=1) ; (window id, whether to get large icons)
{


  ; check status of window - if window is responding or "Not Responding"

  h_icon:=0
  Responding := DllCall("SendMessageTimeout", "UInt", wid, "UInt", 0x0, "Int", 0, "Int", 0, "UInt", 0x2, "UInt", 150, "UInt *", NR_temp) ; 150 = timeout in millisecs
  If (Responding)
    {
    ; WM_GETICON values -    ICON_SMALL =0,   ICON_BIG =1,   ICON_SMALL2 =2
    If Use_Large_Icons_Current =1
      {
      SendMessage, 0x7F, 1, 0,, ahk_id %wid%
      h_icon := ErrorLevel
      }
    If ( ! h_icon )
      {
      SendMessage, 0x7F, 2, 0,, ahk_id %wid%
      h_icon := ErrorLevel
        If ( ! h_icon )
          {
          SendMessage, 0x7F, 0, 0,, ahk_id %wid%
          h_icon := ErrorLevel
          If ( ! h_icon )
            {
            If Use_Large_Icons_Current =1
              h_icon := DllCall( "GetClassLong", "uint", wid, "int", -14 ) ; GCL_HICON is -14
            If ( ! h_icon )
              {
              h_icon := DllCall( "GetClassLong", "uint", wid, "int", -34 ) ; GCL_HICONSM is -34
              ;If ( ! h_icon )
              ;  h_icon := DllCall( "LoadIcon", "uint", 0, "uint", 32512 ) ; IDI_APPLICATION is 32512
              }
            }
          }
        }
      }
return h_icon
}

Gdip_BitmapFromHWNDStretchToDst(SrcHwnd,DstWidth,DstHeight,Bord:=0)
{

WinGetPos,,, Width, Height, ahk_id %SrcHwnd%
if (Width=0) or (Height=0)
	{
	return 0
	}
if (A_OSVersion in WIN_XP)  ; Note: No spaces around commas.
	{
	pBitmap := Gdip_BitmapFromHWND(SrcHwnd)
	}
else
	{
	if (SrcHwnd="")
		{
		SrcHwnd:=0
		}
	hdc2 := DllCall("GetDC", UInt, SrcHwnd)
	hdc := DllCall("CreateCompatibleDC", "uint", hdc2)
	hbm := DllCall("gdi32.dll\CreateCompatibleBitmap", UInt,hdc2 , Int,Width, Int,Height)
	obm := DllCall( "gdi32.dll\SelectObject", UInt,hdc, UInt,hbm)
	PrintWindow(SrcHwnd, hdc)
	pBitmap := Gdip_CreateBitmapFromHBITMAP(hbm)
	sel_obj := SelectObject(hdc, obm)
	DeleteObject(obm), 
	DeleteObject(hbm), 
	DeleteDC(hdc),
	DeleteDC(hdc2),
	DeleteObject(sel_obj)
	}
pBitmap := Gdip_ResizepBitmap(pBitmap, Width, Height, DstWidth, DstHeight,Bord)
return pBitmap
}

Gdip_ResizepBitmap(pBitmap,SrcW,SrcH,DstW,DstH,Bord:=0)
{
	nwpBitmap := Gdip_CreateBitmap(DstW,DstH)
	nwpGraphics := Gdip_GraphicsFromImage(nwpBitmap)
	Gdip_DrawImage(nwpGraphics, pBitmap, 0, 0, DstW, DstH, Bord, Bord, SrcW, SrcH)
	Gdip_DeleteGraphics(nwpGraphics)
	Gdip_DisposeImage(pBitmap)

	return nwpBitmap
}

AHK_NOTIFYICON(wParam, lParam)
{
	if (lParam = 0x203) { ; user double left-clicked tray icon
		Reload
	}
}

ConvertToBGRfromRGB(RGB) { ; Get numeric BGR value from numeric RGB value or HTML color name
  ; HEX values
  BGR := SubStr(RGB, -1, 2) SubStr(RGB, 1, 4) 
  Return BGR 
}

SetAcrylicGlassEffect(thisColor, thisAlpha, hWindow) {
  ; based on https://github.com/jNizM/AHK_TaskBar_SetAttr/blob/master/scr/TaskBar_SetAttr.ahk
  ; by jNizM
    initialAlpha := thisAlpha
    If (thisAlpha<16)
       thisAlpha := 16
    Else If (thisAlpha>245)
       thisAlpha := 245


    thisColor := ConvertToBGRfromRGB(thisColor)
    thisAlpha := Format("{1:#x}", thisAlpha)
    gradient_color := thisAlpha . thisColor

    Static init, accent_state := 4, ver := DllCall("GetVersion") & 0xff < 10
    Static pad := A_PtrSize = 8 ? 4 : 0, WCA_ACCENT_POLICY := 19
    accent_size := VarSetCapacity(ACCENT_POLICY, 16, 0)
    NumPut(accent_state, ACCENT_POLICY, 0, "int")

    If (RegExMatch(gradient_color, "0x[[:xdigit:]]{8}"))
       NumPut(gradient_color, ACCENT_POLICY, 8, "int")

    VarSetCapacity(WINCOMPATTRDATA, 4 + pad + A_PtrSize + 4 + pad, 0)
    && NumPut(WCA_ACCENT_POLICY, WINCOMPATTRDATA, 0, "int")
    && NumPut(&ACCENT_POLICY, WINCOMPATTRDATA, 4 + pad, "ptr")
    && NumPut(accent_size, WINCOMPATTRDATA, 4 + pad + A_PtrSize, "uint")
    If !(DllCall("user32\SetWindowCompositionAttribute", "ptr", hWindow, "ptr", &WINCOMPATTRDATA))
       Return 0 
    thisOpacity := (initialAlpha<16) ? 60 + initialAlpha*9 : 250
    WinSet, Transparent, %thisOpacity%, ahk_id %hWindow%
    Return 1
}