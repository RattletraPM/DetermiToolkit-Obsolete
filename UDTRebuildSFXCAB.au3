#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.15.0 (Beta)
 Author:         RattletraPM

 Script Function:
	Creates a CAB file with UNDERTALE's extracted files, then compiles a script
	serving as an open source SFXCAB utility with a previously extracted icon
	and then appends the CAB file to it.

	Part of UDTranslation Kit.

	This script has been commented in english so that other translators will be
	able to understand how it works and modify it to their own needs.

#ce ----------------------------------------------------------------------------

#include <FileConstants.au3>
#include <Crypt.au3>
#include <File.au3>
#include <Console.au3>			;Shaggi's Console.au3 UDF. You can find it in the "include" folder.
#include <ConsoleEX.au3>		;UDF for additional misc console functions, some written by my and some randomly found online. Again, you can find it in the "include" folder.

$currentdir=""

Opt("TrayIconHide",1)	;This script doesn't need the tray icon at all

Cout("UDTRebuildSFXCAB v0.26 by RattletraPM"&@CRLF)
Cout("Part of UDTranslation Kit"&@CRLF&@CRLF)
;Cout("This build of UDTRebuildSFXCAB is private and may contain bugs."&@CRLF&" Do not redistribute!"&@CRLF&@CRLF)

;AutoIt includes a trailing backslash to @ScriptDir only when the script is run on the root of a drive,
;so we need to check if this is the case before doing anything as it could cause errors later on.
If StringTrimLeft(@ScriptDir, StringLen(@ScriptDir)-1)<>"\" Then
	$currentdir=@ScriptDir&"\"	;If the string doesn't have a current backslash, add it
Else
	$currentdir=@ScriptDir		;If it does, keep it that way
EndIf

;Here we define some file paths. Probably the most boring part of the entire script
$7zexedir=$currentdir&"bin\7z.exe"						;7z.exe's path
$7zdlldir=$currentdir&"bin\7z.dll"						;7z.dll's path
$aut2exedir=$currentdir&"bin\Aut2exe.exe"				;Aut2exe.exe's path
$templatedir=$currentdir&"res\UDTSFXCAB_Template.au3"	;UDTSFXCAB template script's path
$tempdir=@TempDir&"\UDTRebuildSFXCAB\"					;UDTRebuildSFXCAB temporary file directory - will be deleted when the script closes
$templatecopy=$tempdir&"UDTSFXCAB.au3"					;Path where the modified script needs to be copied
$tempcompile=$tempdir&"UDTSFXCAB.exe"					;Path where the modified scripts will be compiled
$cabdirective=$tempdir&"directive.txt"					;Path where MAKECAB's directive file will be generated
$outfile=$currentdir&"UDTREBUILT.exe"					;Output EXE path

;Rebuilding an empty SFXCAB file wouldn't make any sense, so we first have to check if extr is empty
$dirempty=DirGetSize($currentdir&"extr",1)
If @error<>0 Then
	_Cmsg($CONMSG_CRITICAL,"CRITICAL: The extr folder doesn't exist! Run UDTPrep first."&@CRLF)
	PauseExit()
EndIf
If $dirempty[1]==0 Then
	_Cmsg($CONMSG_CRITICAL,"CRITICAL: The extr folder is empty! Run UDTPrep first."&@CRLF)
	PauseExit()
EndIf

;We'll have to check if 7z.exe, 7z.dll, Aut2exe.exe and UDTSFXCAB_Template.au3 exist as those are essential to our script
;I know, that's a lot of IF statements, but we want to make sure to tell the user exactly what's missing
If FileExists($7zexedir) == 0 Then
	_Cmsg($CONMSG_CRITICAL,"CRITICAL: 7z.exe is missing in the BIN directory."&@CRLF)
	PauseExit()
EndIf
If FileExists($7zdlldir) == 0 Then
	_Cmsg($CONMSG_CRITICAL,"CRITICAL: 7z.dll is missing in the BIN directory."&@CRLF)
	PauseExit()
EndIf
If FileExists($aut2exedir) == 0 Then
	_Cmsg($CONMSG_CRITICAL,"CRITICAL: Aut2exe.exe is missing in the BIN directory."&@CRLF)
	PauseExit()
EndIf
If FileExists($templatedir) == 0 Then
	_Cmsg($CONMSG_CRITICAL,"CRITICAL: UDTSFXCAB_Template.au3 is missing in the RES directory."&@CRLF)
	Cout("You may need to redownload UDTranslation Kit.")
	PauseExit()
EndIf
If FileExists($currentdir&"res\Crypt.au3") == 0 Then
	_Cmsg($CONMSG_CRITICAL,"CRITICAL: Crypt.au3 is missing in the RES directory."&@CRLF)
	Cout("You may need to redownload UDTranslation Kit.")
	PauseExit()
EndIf
If FileExists($currentdir&"res\FileConstants.au3") == 0 Then
	_Cmsg($CONMSG_CRITICAL,"CRITICAL: FileConstants.au3 is missing in the RES directory."&@CRLF)
	Cout("You may need to redownload UDTranslation Kit.")
	PauseExit()
EndIf

;Create the temporary directory
DirCreate(@TempDir&"\UDTRebuildSFXCAB")

;Check if there is an icon in res, as we'll use it to rebuild the SFXCAB if it exists
$icon=$currentdir&"res\UNDERTALE.ico"
If FileExists($icon)==0 Then
	_Cmsg($CONMSG_WARNING,"WARNING: No icon has been found. The SFXCAB will be rebuilt without an icon.")
	Cout("Press [y] to proceed or any other key to abort."&@CRLF)
	If Getch()<>"y" Then
		_Cmsg($CONMSG_ERROR,"Operation aborted by the user."&@CRLF)
		PauseExit()
	EndIf
EndIf

;If everything's in place, it's time to generate the script...
_Cmsg($CONMSG_INFO,"Generating script..."&@CRLF)
FileCopy($templatedir,$templatecopy)
FileCopy($currentdir&"res\Crypt.au3",$tempdir&"Crypt.au3")
FileCopy($currentdir&"res\FileConstants.au3",$tempdir&"FileConstants.au3")
_ReplaceStringInFile($templatecopy, "<7ZEXE>", $7zexedir)
_ReplaceStringInFile($templatecopy, "<7ZDLL>", $7zdlldir)
_ReplaceStringInFile($templatecopy, "<EXEMD5>", _Crypt_HashFile($currentdir&"extr\UNDERTALE.exe", $CALG_MD5))

;...Then, compile it...
_Cmsg($CONMSG_INFO,"Compiling script..."&@CRLF)
$aut2exeexit=RunWait(@ComSpec & ' /C Aut2exe /In "'&$templatecopy&'" /Out "'&$tempcompile&'" /Icon "'&$icon&'" /x86',$currentdir&"bin",@SW_HIDE,$STDOUT_CHILD)

;...If there were any errors, notify the user and exit...
If $aut2exeexit<>0 Or FileExists($tempcompile)==0 Then
	_Cmsg($CONMSG_CRITICAL,"CRITICAL: An error occurred while compiling the script."&@CRLF)
	PauseExit()
EndIf

;...After that, we need to generate the directive file for MAKECAB...
_Cmsg($CONMSG_INFO,"Generating MAKECAB directive..."&@CRLF)
$extrlist=_FileListToArray($currentdir&"extr")
If @error<>0 Then
	_Cmsg($CONMSG_CRITICAL,"CRITICAL: An error occurred while listing extr's files."&@CRLF)
	PauseExit()
EndIf
Local $hdirective = FileOpen($cabdirective, $FO_OVERWRITE)
If $hdirective = -1 Then
	_Cmsg($CONMSG_CRITICAL,"CRITICAL: An error occurred while creating MAKECAB's directive file."&@CRLF)
	PauseExit()
EndIf
FileWriteLine($hdirective,"; This file has been generated by UDTRebuildSFXCAB")
FileWriteLine($hdirective,".Set CabinetNameTemplate=udtcab.cab")
FileWriteLine($hdirective,".Set DiskDirectoryTemplate=cab")
FileWriteLine($hdirective,".Set MaxDiskSize=0")
FileWriteLine($hdirective,".Set Cabinet=on")
FileWriteLine($hdirective,".Set Compress=on")
$i=0
Do
	FileWriteLine($hdirective,'"'&$currentdir&"extr\"&$extrlist[$i+1]&'"')
	$i+=1
Until $i==$extrlist[0]
FileClose($hdirective)

;...Then we run MAKECAB...
_Cmsg($CONMSG_INFO,"Running MAKECAB... This may take a while."&@CRLF)
$makecabexit=RunWait(@ComSpec & ' /C MAKECAB /F directive.txt',$tempdir&"")
If $makecabexit<>0 Or FileExists($tempdir&"cab\udtcab.cab")==0 Then
	_Cmsg($CONMSG_CRITICAL,"CRITICAL: An error occurred while generating the CAB file."&@CRLF)
	PauseExit()
EndIf

;...And then we append the CAB file to UDTSFXCAB.
_Cmsg($CONMSG_INFO,"Appending the CAB file to UDTSFXCAB.exe..."&@CRLF)
$copyexit=RunWait(@ComSpec & ' /C COPY /B UDTSFXCAB.exe + cab\udtcab.cab "'&$outfile&'"',$tempdir,@SW_HIDE,$STDOUT_CHILD)
If $copyexit<>0 Or FileExists($outfile)==0 Then
	_Cmsg($CONMSG_CRITICAL,"CRITICAL: An error occurred while appending the CAB file."&@CRLF)
	PauseExit()
EndIf
_Cmsg($CONMSG_SUCCESS,"All done!"&@CRLF)
PauseExit()

Func PauseExit()	;Displays "Press any key to exit", waits for user input, then exits
	Cout("Press any key to exit.")
	DirRemove($tempdir,1)	;Delete the temporary directory
	Cpause()
	Exit
EndFunc