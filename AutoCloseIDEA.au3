; made in Ukraine
; OPTIONS
Const $iniPath = @ScriptDir & '/autoClose.ini'

If FileExists($iniPath) = False Then
 IniWrite($iniPath, 'OPTIONS', 'windowContains', 'IntelliJ IDEA')
 IniWrite($iniPath, 'OPTIONS', 'exitOld', True)
 IniWrite($iniPath, 'OPTIONS', 'activeNew', True)
 IniWrite($iniPath, 'OPTIONS', 'doNotClose',"project1||project3|| [MyProject3]")
 IniWrite($iniPath, 'OPTIONS', 'sleep', 1000)
EndIf


Global $countDNClose, $closeHWND,  $lastHWND = '' ; $closeHWND ������� � ��'���� � �� ������������ ��������� ����, � �� ����� ��������� ������� ������� WinWaitClose ����� ������ �� ���� ��������.


; Search in black List
Func isDoNotColose($nameWindow)
   For $i=0 To $countDNClose-1
      If StringInStr($nameWindow, $doNotClose[$i]) Then Return True
   Next
EndFunc


; PROGRAM
While 1
   Local $sleep = IniRead($iniPath, 'OPTIONS', 'sleep', 1000)
   Sleep($sleep)

   Local $windowContains = IniRead($iniPath, 'OPTIONS', 'windowContains', 'IntelliJ IDEA')
   Local $exitOld = IniRead($iniPath, 'OPTIONS', 'exitOld', True)  ;�� ������� ����� False == stop script
   Local $activeNew = IniRead($iniPath, 'OPTIONS', 'activeNew', True) ;������� ���� �������� ���� ��������
   Local $doNotClose = StringSplit(IniRead($iniPath, 'OPTIONS', 'doNotClose', "||"), "||")
		 $countDNClose  = UBound($doNotClose);
		 ;[CLASS:SunAwtFrame] - ������, ��� � ��������� �� ������, � �� ���� ������ ������� � ������ IntelliJ IDEA ����� �������
		 $aWindows = WinList("[CLASS:SunAwtFrame]") ;WinList("[REGEXPTITLE:(?i)-.+?\[.+\]\s+-\s+IntelliJ IDEA$]")

   For $i=1 To $aWindows[0][0]
	  ; skip windows without 'IntelliJ IDEA'
	  If StringInStr($aWindows[$i][0], $windowContains) = False Or isDoNotColose($aWindows[$i][0]) Then ContinueLoop

	  If  String($LastHWND) <>  String($aWindows[$i][1]) And String($closeHWND) <> String($aWindows[$i][1]) Then
		 ; There can be only one! (Connor MacLeod)
		 If $exitOld and String($LastHWND) <> '' Then
			ConsoleWrite("Close " & $LastHWND & @CRLF)
			WinClose($LastHWND)
			WinWaitClose($LastHWND)
			$closeHWND = $LastHWND
		 EndIf

		 $LastHWND  = $aWindows[$i][1]
		 ConsoleWrite($aWindows[$i][0]& @CRLF)
		 ConsoleWrite(String($LastHWND) & @CRLF)

		 ; active yes/no
		 If $exitOld And $activeNew Then WinActivate($LastHWND)
	  EndIf
   Next
WEnd


