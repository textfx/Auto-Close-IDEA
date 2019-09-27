#include <TrayConstants.au3> ; Required for the $TRAY_ICONSTATE_SHOW constant.
#include <MsgBoxConstants.au3>
#include <StringConstants.au3>
; made in Ukraine
; OPTIONS
Opt("TrayMenuMode", 1+2) ; The default tray menu items will not be shown and items are not checked when selected. These are options 1 and 2 for TrayMenuMode.
TraySetIcon("shell32.dll",-35) ;-3 -35
TraySetPauseIcon("shell32.dll",-3 )

; Create tray menu  https://autoit-script.ru/docs/functions/tray%20management.htm
Global $idPause = TrayCreateItem("Pause", -1,-1, 0);
Global $idSetWhite = TrayCreateItem("SetWhite")
Global $idResetWhite = TrayCreateItem("ResetWhite")
Global $idViewWhite = TrayCreateItem("ViewWhite")
    TrayCreateItem("") ; Create a separator line.
Global $idExit = TrayCreateItem("Exit")

; Loading ini file
Const $iniPath = @ScriptDir & '/autoClose.ini'
If FileExists($iniPath) = False Then
 IniWrite($iniPath, 'OPTIONS', 'windowContains', 'IntelliJ IDEA')
 ;IniWrite($iniPath, 'OPTIONS', 'exitOld', 1) ;If you want active new windows but doesn't want close old windows
 IniWrite($iniPath, 'OPTIONS', 'activeNew', 1) ;active new windows
 IniWrite($iniPath, 'OPTIONS', 'doNotClose',"project1||project3|| [MyProject3]")
 IniWrite($iniPath, 'OPTIONS', 'sleep', 1000)
EndIf


Global $countDNClose, $closeHWND,  $lastHWND = Null ; $closeHWND потрібен в зв'язку з не моментальним закриттям вікон, і не зовсім коректною роботою функції WinWaitClose треба робити ще одну перевірку.

; Search in white List
Func isDoNotColose($nameWindow)
   For $i=1 To $countDNClose-1
	  ;ConsoleWrite($nameWindow & @CRLF)
	  ;ConsoleWrite($doNotClose[$i]& @CRLF)
      If StringInStr($nameWindow, $doNotClose[$i]) Then Return True
   Next
EndFunc



; PROGRAM
$mark =  -1;
$pause = false;
While 1
   ;TRAY MENU
    Switch TrayGetMsg()
	  Case $idPause ; Display a message box about the AutoIt version and installation path of the AutoIt executable.
		   if ($pause) Then
			  $pause = False
			  TrayItemSetState($idPause, $TRAY_UNCHECKED)
		   Else
			  $pause = True
			  TrayItemSetState($idPause, $TRAY_CHECKED)
		   EndIf
		   ConsoleWrite($pause&@CRLF)
	  Case $idSetWhite ; Exit the loop.
		   $aWindows = WinList("[CLASS:SunAwtFrame]")
		   ConsoleWrite(@CRLF)
		   $white = ""
		   For $i = $aWindows[0][0] To 1 Step -1
			  If StringInStr($aWindows[$i][0], $windowContains) = False Then ContinueLoop
				 $arr = StringSplit($aWindows[$i][0], "\[")
			  ;ConsoleWrite($arr[1]&@CRLF)
			  $white &=  StringStripWS($arr[1], $STR_STRIPLEADING + $STR_STRIPTRAILING + $STR_STRIPSPACES) & "||"
			  ConsoleWrite($aWindows[$i][0]&@CRLF)
		   Next
		   $LastHWND = Null;
		   IniWrite($iniPath, 'OPTIONS', 'doNotClose', $white)
		   MsgBox(4096, "Info", "All active windows added in white list" & @CRLF & @CRLF &$white)
		   ;ConsoleWrite("SetWhite")
	  Case $idResetWhite ; Exit the loop.
			$LastHWND = Null;
			IniWrite($iniPath, 'OPTIONS', 'doNotClose',"||")
			MsgBox(4096, "Info", "White list is RESET" & @CRLF)
	  Case $idViewWhite ; Exit the loop.
			MsgBox(4096, "Info", "White list is RESET" & @CRLF & IniRead($iniPath, 'OPTIONS', 'doNotClose', "||"))
	  Case $idExit ; Exit the loop.
		   ExitLoop
	  EndSwitch


   ;Close Windows
   Local $sleep = IniRead($iniPath, 'OPTIONS', 'sleep', 1000)
   if ($pause = False) And ($mark = -1 Or TimerDiff($mark)>$sleep) Then
	  Local $windowContains = IniRead($iniPath, 'OPTIONS', 'windowContains', 'IntelliJ IDEA')
	  ;Local $exitOld = IniRead($iniPath, 'OPTIONS', 'exitOld', 1)  ;не потрібна опція False == stop script
	  Local $activeNew = IniRead($iniPath, 'OPTIONS', 'activeNew', 1) ;зробити вікно активним після відкриття
	  Local $doNotClose = StringSplit(IniRead(	$iniPath, 'OPTIONS', 'doNotClose', "||"), "||")
			$countDNClose  = UBound($doNotClose);
			;[CLASS:SunAwtFrame] - захист, щоб в браузерах не шукало, а то якщо знайде вкладку з назвою IntelliJ IDEA закриє браузер
			$aWindows = WinList("[CLASS:SunAwtFrame]") ;WinList("[REGEXPTITLE:(?i)-.+?\[.+\]\s+-\s+IntelliJ IDEA$]")
	  Local $active = false;


	  ;ConsoleWrite(@CRLF&@CRLF)
	  For $i=$aWindows[0][0] To 1 Step -1
		 ; skip windows without 'IntelliJ IDEA'
		 If StringInStr($aWindows[$i][0], $windowContains) = False Or isDoNotColose($aWindows[$i][0]) Then ContinueLoop

		 ;ConsoleWrite("Window " & $aWindows[$i][0] & @CRLF)
		 If String($LastHWND) <>  String($aWindows[$i][1]) And String($closeHWND) <> String($aWindows[$i][1]) Then ;
			; There can be only one! (Connor MacLeod)
			Do
			   If (String($LastHWND) <> Null) Then
				  ConsoleWrite("Close " & $LastHWND & @CRLF)
				  WinClose($LastHWND)
				  ;WinWaitClose($LastHWND) ;WinWaitClose is not work
				  $closeHWND = $LastHWND
			   EndIf
			   Sleep(100)
			   ConsoleWrite(WinExists($LastHWND)& @CRLF)
			Until (WinExists($LastHWND)=0)

			$LastHWND  = $aWindows[$i][1]
			ConsoleWrite($aWindows[$i][0]& @CRLF)
			ConsoleWrite(String($LastHWND) & @CRLF)

			; active yes/no
			;щоб тільки 1 раз вікно активувало
			If $activeNew  = 1 Then  $active = true
		 EndIf
	  Next

	  If $active Then
		 $active = False
		 WinActivate($LastHWND)
	  EndIf
	  $mark = TimerInit()
   EndIf
WEnd



