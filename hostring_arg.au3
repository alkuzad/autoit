; #INDEX# =======================================================================================================================
; Title .........: HotString
; AutoIt Version : 3.3.10.2
; Description ...: Similar to HotKeySet but for entire strings of characters to be set as the hotkey.
; Author(s) .....: Manadar, GaryFrost, WideBoyDixon, KaFu, Malkey
; Dll ...........: user32.dll
; Repository ....: https://github.com/jvanegmond/hotstrings
; Modified to support argument passing to callfunc with
; ===============================================================================================================================

;Supported keys:
;{ESC}{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}
;{GRAVE}1234567890-={BACKSPACE}
;{TAB}QWERTYUIOP[]\
;{CAPSLOCK}ASDFGHJKL;{ACUTE/CEDILLA}
;{SHIFT}ZXCVBNM,./
;{CTRL}{Left Windows}{SPACE}{Right Windows}{Application}{Right Ctrl}
;{LEFT}{UP}{RIGHT}{DOWN}
;{INSERT}{HOME}{PGUP}{DELETE}{END}{PGDOWN}{Prnt Scrn}{SCROLL LOCK}{Pause}
;{Num Lock}{NUM DIVIDE}{NUMMULT}{NUM SUB}{NUM 7}{NUM 8}{NUM 9}{NUM PLUS}{NUM 4}{NUM 5}{NUM 6}{NUM 1}{NUM 2}{NUM 3}{NUM ENTER}{NUM 0}{NUM DECIMAL}


#include-once
#include <WinAPI.au3>
#include <WindowsConstants.au3>
#include <GUIConstantsEx.au3>
#include <Array.au3>
#include <CallAry.au3>

Local Const $HOTSTRING_MAXLEN = 25

Local $initialized = False, $hotString_Debug = False, $hotString_hStub_KeyProc, $hotString_hmod, $hotString_hHook, $hotString_buffer = "", $hotString_User32, $hotString_hotkeys[1], $hotString_hotfuncs[1], $hotString_hWnd, $hotStringTimer = TimerInit()
Global $hotString_hotargs[1][2]

Global $HotStringPressed ; allows monitoring of the typed sequence
Global $hotStringMaxInterval = 1500 ; allows monitoring of delays between keypresses (can be changed by user)
Global $bActive = False
Local $hHotStringActiveSemaphore = _WinAPI_CreateSemaphore('HotStringActiveSemaphore', 1, 1)
Global $sHotStringToIgnore = ""

;========================================
;
; Description:   HotStringSet($hotstring, $function)
;                Sets a string which when typed in calls the specified function without arguments.
; Parameter(s):  $hotstring - The string to be set which triggers calling the function. Check the supported keys.
;                $function - A string containing the function name to be called when $hotstring is typed.
;			     $args - array of arguments to pass into function
;
;========================================

Func HotStringSet($hotstring, $func = "", $args = [])
	If Not $initialized Then _HotString_Initialize()

	If $hotstring > $HOTSTRING_MAXLEN Then Return SetError(1, 0, -1)

	If $func = "" Then
		; Clears
		Local $i = _ArraySearch($hotString_hotkeys, $hotstring)
		If $i = -1 Then Return

		_ArrayDelete($hotString_hotkeys, $i)
		_ArrayDelete($hotString_hotfuncs, $i)
		_ArrayDelete($hotString_hotargs, $i)
	 Else
		_ArrayAdd($hotString_hotkeys, $hotstring)
		_ArrayAdd($hotString_hotfuncs, $func)
		_ArrayAdd($hotString_hotargs, $args)
	 EndIf

   Return 0
EndFunc   ;==>HotStringSet

;========================================
;
; Description:   HotStringSetDebug($flag)
;                Enables the hotstring library to print out debug information to the console.
; Parameter(s):  $flag - True for enable debug information. False for disable debug information.
;
;========================================

Func HotStringSetDebug($flag)
	$hotString_Debug = $flag
EndFunc   ;==>HotStringSetDebug

Func _HotString_Initialize()
	$hotString_hStub_KeyProc = DllCallbackRegister("_HotString_KeyProc", "long", "int;wparam;lparam")
	$hotString_hmod = _WinAPI_GetModuleHandle(0)
	$hotString_hHook = _WinAPI_SetWindowsHookEx($WH_KEYBOARD_LL, DllCallbackGetPtr($hotString_hStub_KeyProc), $hotString_hmod)
	$hotString_User32 = DllOpen("user32.dll")
	$hotString_hWnd = GUICreate("")
	GUIRegisterMsg($WM_COMMAND, "_HotString_GUIKeyProc")
	OnAutoItExitRegister("_HotString_OnAutoItExit")

	$initialized = True
EndFunc   ;==>_HotString_Initialize

Func _HotString_EvaluateKey($key)

   ; if there's a long delay between keypresses, assume it won't be the same sequence so clear the buffer
	If TimerDiff($hotStringTimer) > $hotStringMaxInterval Then
		_HotString_DebugWrite("Clear buffer because of timeout")
		$hotString_buffer = ""
	EndIf

	If StringLen($key) > 1 Then
		$key = "{" & $key & "}"
	EndIf

    Local $sIgnoreKey = ""

    If StringLen($key) == 1 Then
	  $sIgnoreKey = StringUpper(StringLeft($sHotStringToIgnore, 1))
	  $sHotStringToIgnore = StringTrimLeft($sHotStringToIgnore, 1)
   EndIf

   if $key == $sIgnoreKey Then
	  _HotString_DebugWrite("Ignoring " & $key & " from previous expand" & @CRLF)
   else
	  _HotString_DebugWrite("Received key: " & $key)
	  $hotString_buffer &= $key
   EndIf

   $hotString_buffer = StringRight($hotString_buffer, $HOTSTRING_MAXLEN)

   _HotString_CheckHotkeys($hotString_buffer)

   $hotStringTimer = TimerInit()
EndFunc   ;==>_HotString_EvaluateKey

Func _HotString_CheckHotkeys($current)
	For $i = 1 To UBound($hotString_hotkeys) - 1
	  If _HotString_Match($hotString_hotkeys[$i], $current) Then
		 $HotStringPressed = $hotString_hotkeys[$i]
		 _HotString_DebugWrite("Hotstring " & $hotString_hotkeys[$i] & " triggers method " & $hotString_hotfuncs[$i] & " with " & $hotString_hotargs[$i][1])
		 Global $sHotStringToIgnore = $hotString_hotargs[$i][1]
		 Call($hotString_hotfuncs[$i], $hotString_hotargs[$i][0], $hotString_hotargs[$i][1])
	  EndIf
   Next
EndFunc   ;==>_HotString_CheckHotkeys

Func _HotString_Match($hotkey, $current)
	Return StringRight($current, StringLen($hotkey)) = $hotkey
EndFunc   ;==>_HotString_Match

Func _HotString_GUIKeyProc($hWnd, $Msg, $wParam, $lParam)
	If $hWnd <> $hotString_hWnd Then Return $GUI_RUNDEFMSG ; If this message is not for us, run the AutoIt internal handler

	Local $aRet = DllCall($hotString_User32, 'int', 'GetKeyNameText', 'int', $lParam, 'str', "", 'int', 256)

	Local $sKeyName = $aRet[2]
	If $sKeyName Then
	  _HotString_EvaluateKey($sKeyName)
	EndIf

	Return 0 ; Don't run the AutoIt internal handler for this GUI
EndFunc   ;==>_HotString_GUIKeyProc

Func _HotString_KeyProc($nCode, $wParam, $lParam)
	If $nCode >= 0 And $wParam = $WM_KEYDOWN Then
		Local $tKEYHOOKS = DllStructCreate($tagKBDLLHOOKSTRUCT, $lParam)

		; http://msdn.microsoft.com/en-us/library/ms646300(v=vs.85).aspx
		Local $vkKey = DllStructGetData($tKEYHOOKS, "vkCode")
		Local $scanCode = DllStructGetData($tKEYHOOKS, "scanCode")
		Local $flags = DllStructGetData($tKEYHOOKS, "flags")

		Local $lWantParam = BitShift($scanCode, -16)
		$lWantParam = BitOR($lWantParam, BitShift($flags, -24))

		; post message to our local GUI
		; We use $WM_COMMAND instead of $WM_KEYDOWN/UP because $WM_KEYDOWN/UP automagically consumed some chars such as up, down, enter
		_WinAPI_PostMessage($hotString_hWnd, $WM_COMMAND, $vkKey, $lWantParam)
	EndIf

	Return _WinAPI_CallNextHookEx($hotString_hHook, $nCode, $wParam, $lParam)
EndFunc   ;==>_HotString_KeyProc

Func _HotString_OnAutoItExit()
	_WinAPI_UnhookWindowsHookEx($hotString_hHook)
	DllCallbackFree($hotString_hStub_KeyProc)
	DllClose($hotString_User32)
EndFunc   ;==>_HotString_OnAutoItExit

Func _HotString_DebugWrite($line)
	If Not $hotString_Debug Then Return
	ConsoleWrite("HotString: " & $line & @CRLF)
EndFunc   ;==>_HotString_DebugWrite
