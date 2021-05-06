; Call Func passing array as obj
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
	  Execute ($str)
	  If @error Then Return (3,2,"Error in calling function")
   Else
	  Return SetError(2,5,"Not an array")
   EndIf
EndFunc
