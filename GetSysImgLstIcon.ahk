; ======================================================================================================================
; GetSysImgLstIcon() - Retrieves an icon from the system image list.
; Author:      just me
; AHK version: 1.1.13.01
; Tested on:   Win XP x86 / Win 7 x64
; Parameters:
;     Path     -  File path (max. 260 characters) or extension (including the leading dot).     (String)
;     Size     -  One of the keys defined in SHIL.                                              (String)
;                 Default: "SYSSMALL"
;     Overlay  -  Include the specified overlay icon (one of the keys defined in SHGIOI).       (String)
;                 Default: "" (none)
; Return values:
;     On success: Object containing three key/value pairs:
;                 -  HICON -  icon handle
;                 -  W     -  width in pixels
;                 -  H     -  height in pixels
;     On failure: False
; Change History:
;     1.0.02.00/2013-01-15/just me     -  replaced interface calls by image list function calls,
;                                      -  added parameter Overlay,
;                                      -  changed GetIcon flags.
;     1.0.01.00/2013-01-14/just me     -  fixed file handling.
;     1.0.00.00/2013-01-14/just me     -  initial release.
; MSDN:
;     SHGetFileInfo           -> http://msdn.microsoft.com/en-us/library/bb762179(v=vs.85).aspx
;     SHGetImageList          -> http://msdn.microsoft.com/en-us/library/bb762185(v=vs.85).aspx
;     SHGetIconOverlayIndex   -> http://msdn.microsoft.com/en-us/library/bb762183(v=vs.85).aspx
;     IIDFromString           -> http://msdn.microsoft.com/en-us/library/ms687262(v=vs.85).aspx
; ======================================================================================================================
GetSysImgLstIcon(Path, Size := "SYSSMALL", Overlay := "") {
   Static AW := A_IsUnicode ? "W" : "A"
   Static cbSFI := A_PtrSize + 8 + (340 << !!A_IsUnicode)
   Static FILE_ATTRIBUTE_NORMAL := 0x80
   Static IID_IIL_Str := "{46EB5926-582E-4017-9FDF-E8998DAA0950}"
   Static SHGFI := {SYSICONINDEX: 0x04000, USEFILEATTRIBUTES: 0x0010}
   Static SHGIOI := {SHARE: 0x0FFFFFFF, LINK: 0x0FFFFFFE, SLOWFILE: 0x0FFFFFFD, DEFAULT: 0x0FFFFFFC}
   Static SHIL := {LARGE: 0x00, SMALL: 0x01, EXTRALARGE: 0x02, SYSSMALL: 0x03, JUMBO: 0x04}
   If !SHIL.HasKey(Size)
      Return False
   VarSetCapacity(IID_IIL, 16, 0) ; IID
   If DllCall("Ole32.dll\IIDFromString", "WStr", IID_IIL_Str, "Ptr", &IID_IIL, "UInt")
      Return False
   HMOD := DllCall("Kernel32.dll\GetModuleHandle", "Str", "shell32.dll", "UPtr")
   FileIconInit := DllCall("Kernel32.dll\GetProcAddress", "Ptr", HMOD, "Ptr", 660, "UPtr")
   DllCall(FileIconInit, "UInt", True, "UInt")
   VarSetCapacity(SFI, cbSFI, 0) ; SHFILEINFO
   ; pure extensions need special handling
   Flags := SHGFI.SYSICONINDEX | (SubStr(Path, 1, 1) = "." ? SHGFI.USEFILEATTRIBUTES : 0x0)
   If !DllCall("Shell32.dll\SHGetFileInfo" . AW, "Str", Path, "UInt", 0x80, "Ptr", &SFI, "UInt", cbSFI, "UInt", Flags, "UPtr")
      Return False
   IconIndex := NumGet(SFI, A_PtrSize, "Int")
   If DllCall("Shell32.dll\SHGetImageList", "Int", SHIL[Size], "Ptr", &IID_IIL, "PtrP", IIL, "UInt")
      Return False
   Flags := 0x0020 ; ILD_IMAGE
   ; overlays need a special handling
   If SHGIOI.HasKey(Overlay)
   && (IOV := DllCall("Shell32.dll\SHGetIconOverlayIndex", "Ptr", 0, "UInt", SHGIOI[Overlay], "Int")) >= 0
      Flags |= IOV << 8
   DllCall("Comctl32.dll\ImageList_GetIconSize", "Ptr", IIL, "IntP", CX, "IntP", CY, "UInt")
   HICON := DllCall("Comctl32.dll\ImageList_GetIcon", "Ptr", IIL, "Int", IconIndex, "UInt", Flags, "UPtr")
   Return {HICON: HICON, W: CX, H: CY}
}