#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.15.0 (Beta)
 Author:         RattletraPM

 Script Function:
	Extracts UNDERTALE's files from its SFXCAB and saves a copy of the exe file
	with its CAB part removed, so that it can be modded and added again later.

	Part of UDTranslation Kit.

	This script has been commented in english so that other translators will be
	able to understand how it works and modify it to their own needs.

#ce ----------------------------------------------------------------------------

;This was a work in progress Italian translation that I made for UDTranslationKit. As you may (or may not) know that I originally started coding my tools to translate
;Undertale in Italian it would make sense to write the tools in Italian aswell. Still, since then not only a group started making their own patch but also
;Toby released a patch that made UDTPrep and the other old tools obsolete, so I never really completed this translation. I'm including this here just for historic
;purposes, as I don't think I'll ever complete it.

#include <GDIPlus.au3>
#include <GDIPlusconstants.au3>
#include <WinAPIShellEx.au3>
#include <WinAPIGdi.au3>
#include <FileConstants.au3>
#include <MsgBoxConstants.au3>
#include <AutoItConstants.au3>
#include <Console.au3>			;Shaggi's Console.au3 UDF. You can find it in the "include" folder.
#include <ConsoleEX.au3>		;UDF for additional misc console functions, some written by my and some randomly found online. Again, you can find it in the "include" folder.

Opt("TrayIconHide",1)	;This script doesn't need the tray icon at all

$currentdir=""

Cout("UDTPrep v0.3 by RattletraPM"&@CRLF)
Cout("Parte di UDTranslation Kit"&@CRLF&@CRLF)
Cout("Questa build di UDTPrep è privata e potrebbe contenere bug. Non ridistribuire!"&@CRLF&@CRLF)

;First, we need to ask the user to select UNDERTALE.EXE.
$file = FileOpenDialog("Seleziona il file eseguibile di UNDERTALE", @ScriptDir, "File Eseguibili (*.exe)", $FD_FILEMUSTEXIST)

;If the user doesn't choose a file or it can't be opened, exit.
If @error == 1 or @error == 2 Then
	_Cmsg($CONMSG_CRITICAL,"CRITICO: Il file non può essere aperto o nessun file è stato scelto."&@CRLF)
	PauseExit()
EndIf

;AutoIt includes a trailing backslash to @ScriptDir only when the script is run on the root of a drive,
;so we need to check if this is the case before doing anything as it could cause errors later on.
If StringTrimLeft(@ScriptDir, StringLen(@ScriptDir)-1)<>"\" Then
	$currentdir=@ScriptDir&"\"	;If the string doesn't have a current backslash, add it
Else
	$currentdir=@ScriptDir		;If it does, keep it that way
EndIf

;Everything's in place, we'll notify the user that the path is valid and the file can be opened
_Cmsg($CONMSG_INFO, "E' stato scelto il file "&$file&@CRLF)

;We're going to open the file in binary mode and check if it's acutally a SFXCAB file. This is because 7z can extract
;metadata from  many EXE files, but we want to make sure that this is acutally Undertale's SFXCAB
_Cmsg($CONMSG_INFO, "Verifica del file in corso..."&@CRLF)
$udtexe=FileOpen($file,$FO_BINARY)
$sfxcab=String(FileRead($file))
FileClose($udtexe)
If StringInStr($sfxcab,"4D534346")==0 Then
	_Cmsg($CONMSG_CRITICAL,"CRITICO: Il file scelto non è un SFXCAB."&@CRLF)
	PauseExit()
EndIf
_Cmsg($CONMSG_SUCCESS,"Il file è stato verificato con successo."&@CRLF)

;Now for the "fun" part: we're going to extract the files somewhere. We'll be using 7z.exe as EXPAND won't work for some reason.
;First of all, tho, we're going to check if 7z.exe and 7z.dll exist in the BIN directory
If FileExists($currentdir&"bin\7z.exe") == 0 Then
	_Cmsg($CONMSG_CRITICAL,"CRITICO: 7z.exe mancante nella directory BIN."&@CRLF)
	PauseExit()
EndIf
If FileExists($currentdir&"bin\7z.dll") == 0 Then
	_Cmsg($CONMSG_CRITICAL,"CRITICO: 7z.dll mancante nella directory BIN."&@CRLF)
	PauseExit()
EndIf

;Create the extr folder if it doesn't exists (notice how AutoIt uses FileExists to check if folders exist too)
If FileExists($currentdir&"extr")==0 Then
	DirCreate($currentdir&"extr")
EndIf

;We don't want the user to accidentally overwrite their directory. If extr isn't empty, let him choose what to do
$dirempty=DirGetSize($currentdir&"extr",1)
If @error<>0 Then	;In case there has been an error, it probably means there's a file called "extr" in the directory
	FileDelete($currentdir&"extr")	;We need to delete it, or else 7z will crash
	DirCreate($currentdir&"extr")
	$dirempty=DirGetSize($currentdir&"extr",1)	;We beed to get the dir size again or our script will crash
EndIf
If $dirempty[1]<>0 Then
	_Cmsg($CONMSG_WARNING,"ATTENZIONE: La cartella extr non è vuota. I file verranno sovrascritti!"&@CRLF)
	Cout("Premere [s] per procedere o qualsiasi altro tasto per uscire."&@CRLF)
	If Getch()<>"s" Then
		_Cmsg($CONMSG_ERROR,"Operazione annullata dall'utente."&@CRLF)
		PauseExit()
	EndIf
EndIf

;This acutally starts the extraction
_Cmsg($CONMSG_INFO,"Estrazione dei file in corso..."&@CRLF)
$exitcode = RunWait(@ComSpec & ' /C 7z x "'&$file&'" -y -o"'&$currentdir&"extr",$currentdir&"bin",@SW_HIDE,$STDOUT_CHILD)

;Now we check that everything went correctly using 7z.exe's exit codes
Switch $exitcode
	Case 0	; = Everything went fine
		_Cmsg($CONMSG_SUCCESS,"Estrazione completata con successo!"&@CRLF)
	Case 1	; = Warning, Shouldn't be using for extracting, but we include it in just in case
		_Cmsg($CONMSG_WARNING,"ATTENZIONE: 7z ha riportato un errore minore, alcuni file potrebbero non"&@CRLF&"essere stati estratti."&@CRLF)
	Case 2	; = Fatal error
		_Cmsg($CONMSG_CRITICAL,"CRITICO: 7z ha riportato un errore fatale."&@CRLF)
		PauseExit()
	Case 7	; = Command line error
		WriteErr()
		_Cmsg($CONMSG_CRITICAL,"CRITICO: 7z ha riportato un errore di riga di comando."&@CRLF&"Questo può essere dato da un bug di UDTPrep. E' stato creato un file di"&@CRLF&"testo con il comando eseguito chiamato errcmd.txt scoprire la causa dell'errore."&@CRLF)
		PauseExit()
	Case 8	; = Out of memory error
		_Cmsg($CONMSG_CRITICAL,"CRITICO: Non è stato possibile allocare abbastanza memoria per 7z."&@CRLF)
		PauseExit()
	Case 255; = User aborted the operation
		_Cmsg($CONMSG_CRITICAL,"CRITICO: Estrazione annullata dall'utente."&@CRLF)
		PauseExit()
	Case Else;= Unknown exit code
		_Cmsg($CONMSG_CRITICAL,"CRITICO: 7z ha riportato un codice d'uscita sconosciuto."&@CRLF)
		PauseExit()
EndSwitch

;Finally, we'll extract the ICO file from Undertale's SFX archive, so we can rebuild it later
_Cmsg($CONMSG_INFO,"Estrazione dell'icona in corso..."&@CRLF)
$icon=$currentdir&"res\UNDERTALE.ico"
_ExtractIconFromExe($file,$icon,0)
If FileExists($icon)==0 Then
	_Cmsg($CONMSG_WARNING,"ATTENZIONE: Non è stato possibile estrarre l'icona dal file."&@CRLF)
	PauseExit()
Else
	_Cmsg($CONMSG_SUCCESS,"Estrazione dell' icona completata con successo!"&@CRLF)
	_Cmsg($CONMSG_SUCCESS,"Tutte le operazioni sono state completate con successo."&@CRLF)
	PauseExit()
EndIf

Func WriteErr()	;This function writes a file called "errcmd.txt" if 7z reports a command line error and writes the exact command line string used by it
	Local $errfile = FileOpen($currentdir&"errcmd.txt", $FO_OVERWRITE)
	FileWriteLine($errfile, @ComSpec & ' /C 7z x "'&$file&'" -y -o"'&$currentdir&"extr")
	FileClose($errfile)
EndFunc

Func _ExtractIconFromExe($source,$outsource,$iconnumber = 0)	;Function to extract icons from an EXE
	Local $ico = _WinAPI_ShellExtractIcon($source, 0, 64, 64)
	_WinAPI_SaveHICONToFile($outsource,$ico,False)
Endfunc

Func PauseExit()	;Displays "Press any key to exit", waits for user input, then exits
	Cout("Premere un qualsiasi tasto per uscire.")
	Cpause()
	Exit
EndFunc