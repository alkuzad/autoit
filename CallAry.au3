; Call Func passing array as obj

; Example:
; local $ary[2] = ["1stparam","2ndparam"]

; CallAry("wordf",$ary)

; func wordf($param1,$param2)
;   msgbox("","Showing parameters",$param1 &"-" &$param2)
; endfunc

Local $_CallAry_debug = False

Func SetCallAryDebug($debug)
   Local $_CallAry_debug = $debug
EndFunc

Func CallAry($func, $ary)
   If IsArray($ary) Then
	  $param = ""
	  For $i = 0 To UBound($ary)-1
		 $ary[$i] = '"' &$ary[$i] &'"'
	  Next
	  For $i = 0 To UBound($ary)-1
		 $param &=  $ary[$i] &","
	  Next
	  $param = StringTrimRight($param,1)
	  $str = 'Call ("' &$func &'",' &$param &')'
	  if $_CallAry_debug Then
		 ConsoleWrite("Executing this call: " & $str)
	  EndIf
	  Execute ($str)
	  If @error Then Return (3,2,"Error in calling function")
   Else
	  Return SetError(2,5,"Not an array")
   EndIf
EndFunc
