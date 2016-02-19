#include-Once

#include <Console.au3>

;I'm sorry if this UDF isn't well documented but it wasn't really meant to be shared online. It was just a collection
;of additional console functions that I used for some of my scripts!

;==CONSTANTS==
;Console message prefixes, used by _Cmsg()
Const $CONMSG_UNKNOWN=0		;[?] - Debug only, do not use.
Const $CONMSG_SUCCESS=1		;[+] - Used for successful tasks
Const $CONMSG_ERROR=10		;[!] - Used for generic errors
Const $CONMSG_CRITICAL=20	;[!!] - Used for script-breaking errors
Const $CONMSG_WARNING=30	;[->] - Used for displaying important messages, usually minor errors
Const $CONMSG_INFO=40		;[i] - Used for various informations, usually the beginning of a task

;This is a function that I often use in my console-based scripts to quickly add a colored prefix to a message.
;Think of it as Windows' message box icons for console scripts.
;Coded by RattletraPM
Func _Cmsg($prefix,$msg)
	Cout("[")
	Switch $prefix
		Case $CONMSG_UNKNOWN
			Cout("?",15)
		Case $CONMSG_SUCCESS
			Cout("+",BitOr($FOREGROUND_GREEN,$FOREGROUND_INTENSITY))
		Case $CONMSG_ERROR
			Cout("!",BitOr($FOREGROUND_RED,$FOREGROUND_INTENSITY))
		Case $CONMSG_CRITICAL
			Cout(Chr(19),$FOREGROUND_RED)
		Case $CONMSG_WARNING
			Cout(Chr(26),14)
		Case $CONMSG_INFO
			Cout("i",11)
		Case Else
			Cout("X")	;Used for invalid constants.
	EndSwitch
	Cout("] ")
	Cout($msg)
EndFunc

;Fills a console window with a certain number of characters at coords $iX, $iY. Useful as a Cls() alternative.
;Coded by Matt Diesel (Mat)
Func _Console_FillOutputCharacter($hConsoleOutput, $sCharacter, $nLength, $iX = 0, $iY = 0)
    Local $aResult, $tCOORD

    If $hConsoleOutput = -1 Then $hConsoleOutput = _Console_GetStdHandle()
    If IsString($sCharacter) Then $sCharacter = AscW($sCharacter)

    $tCOORD = BitShift($iY, -16) + $iX

    $aResult = DllCall("kernel32.dll", "bool", "FillConsoleOutputCharacterW", _
            "handle", $hConsoleOutput, _
            "WORD", $sCharacter, _
            "dword", $nLength, _
            "int", $tCOORD, _
            "dword*", 0)
    If @error Then Return SetError(@error, @extended, False)

    Return SetExtended($aResult[5], $aResult[0] <> 0)
EndFunc ;==>_Console_FillOutputCharacter

;Gets the handle of a console window, used by _ConsoleFillOutputCharacter
;Coded by Matt Diesel (Mat)
Func _Console_GetStdHandle($nStdHandle = -11)
    Local $aResult

    $aResult = DllCall("kernel32.dll", "handle", "GetStdHandle", _
            "dword", $nStdHandle)
    If @error Then Return SetError(@error, @extended, 0)

    Return $aResult[0]
EndFunc ;==>_Console_GetStdHandle

;Sets the cursor of a console window to $iX, $iY. Useful after using _ConsoleFillOutputCharacter (as the cursor will
;get moved around) and used by _Cls()-check below.
;Coded by Matt Diesel (Mat)
Func _Console_SetCursorPosition($hConsoleOutput, $iX, $iY)
    Local $iCursorPosition, $aResult

    If $hConsoleOutput = -1 Then $hConsoleOutput = _Console_GetStdHandle()

    $iCursorPosition = BitShift($iY, -16) + $iX

    $aResult = DllCall("kernel32.dll", "bool", "SetConsoleCursorPosition", _
            "handle", $hConsoleOutput, _
            "int", $iCursorPosition)
    If @error Then Return SetError(@error, @extended, False)

    Return $aResult[0] <> 0
EndFunc ;==>_Console_SetCursorPosition

;You may be wondering why I made a specific function for clearing the screen when I could've used system("CLS").
;If you do, read this article (it's mainly for C++ but it also applies here): http://www.cplusplus.com/forum/articles/11153/
;Lazily coded by RattletraPM (ugh...)
Func _Cls($iY)
	Local $i=0
	Local $spaces=0
	Do
		_Console_SetCursorPosition(-1,0,$iY+$i)
		Do
			;I didn't use _Console_FillOutputCharacter() as it doesn't reset the background colour, while Cout does.
			Cout(" ")
			$spaces+=1
		Until $spaces==79
		$i+=1
	Until $i==25
	_Console_SetCursorPosition(-1,0,0)
EndFunc

;Again, if you're wondering why I'm not using system("PAUSE"), check the article I linked in _Cls()'s comments.
;Literally one variable plus one command written by RattletraPM (1337 skillz)
;Again, if you're wondering why I'm not using system("PAUSE"), check the article I linked in _Cls()'s comments.
;Literally command written by RattletraPM (1337 skillz)
Func Cpause()
	Getch()
EndFunc