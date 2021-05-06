#include <hotstring.au3>

Dim $config_file = @ScriptDir & "\config.ini"
Dim $debug = False

Func SetupAutoStart()
   If (Not (StringRight(@ScriptName, 4) == ".au3")) Then
	  If Not FileExists(@StartupDir & "\text-expander.lnk") Then
		 FileCreateShortcut(@ScriptFullPath, @StartupDir & "\text-expander.lnk", @ScriptDir, "", "AutoIT Script Description")
		 MsgBox(262144 + 48, "Text Expander", "Text Expander was installed as Startup script, do not move it from this location or it will stop working" & @CRLF & "To remove run this script with /uninstall argument")
	  EndIf
   EndIf

   if $cmdline[0] > 0 And $cmdline[1] == "/uninstall" Then
	  FileDelete(@StartupDir & "\text-expander.lnk")
	  MsgBox(262144 + 64, "Text Expander", "Uninstalled from Current User startup folder")
   EndIf
EndFunc

Func ReadConfig()
   if Not FileExists($config_file) then
	  MsgBox(262144 + 16, "No config.ini", "Create config.ini file" )
	  Exit(1)
   EndIf

   IniReadSection($config_file, "global")
   Dim $keyDelay = "5"
   if not @error Then
	  $keyDelay = IniRead($config_file, "global", "key-delay", "5")
	  $debug = IniRead($config_file, "global", "debug", "false") == "true"
   endif
   Opt("SendKeyDelay", $keyDelay)
   Opt("SendKeyDownDelay" , $keyDelay)
EndFunc

Func expandfunc($iDelCount, $sExpand)
   for $i = 1 to $iDelCount
	  send("{backspace}")
   Next
   send($sExpand)
EndFunc

Func ExpandCorrect($sText, $sExpand)
   if StringInStr($sExpand, $sText) Then
	  ConsoleWriteError("Expand text '" & $sExpand & "' includes whole trigger text '" & $sText & "' which will cause loop, change it" & @CRLF)
	  Return False
   EndIf
   Return True
EndFunc

Func Setup()
   HotStringSetDebug($debug)

   Local $aSections = IniReadSectionNames($config_file)

   For $i = 1 To $aSections[0]
	  If StringInStr($aSections[$i], "hotstring.",0,1,1,10) Then
		 Local $aSection = IniReadSection($config_file, $aSections[$i])
		 Local $sText = IniRead($config_file, $aSections[$i], "text", "Not-Existing-asdvsadbvasdas")
		 Local $sExpand = IniRead($config_file, $aSections[$i], "expand", "Not-Existing-asdvsadbvasdas")

		 If not ExpandCorrect($sText, $sExpand) Then
			Exit(1)
		 EndIf

		 If $sText ==  "Not-Existing-asdvsadbvasdas" Or $sExpand ==  "Not-Existing-asdvsadbvasdas" Then
			MsgBox(262144 + 16, "Invalid hotstring configuration", "Missing text or expand key in " & $aSection & " section" & @CRLF)
			Exit(1)
		 EndIf

		 Local $iDeleteCount = StringLen(StringRegExpReplace($sText, "(?i)\{\w+\}", "", 0))

		 ConsoleWrite($aSections[$i] & " replace '" & $sText & "' with '" & $sExpand & "'. AutoDelete " & $iDeleteCount & " first characters" & @CRLF)

		 Local $aArgumentsAry[1][2] = [[$iDeleteCount, $sExpand]]
		 HotStringSet($sText, "expandfunc", $aArgumentsAry)
	  EndIf
   Next
EndFunc

Func Main()
   SetupAutoStart()
   ReadConfig()
   Setup()
   While 1
	  Sleep(100)
   WEnd
EndFunc

Main()
