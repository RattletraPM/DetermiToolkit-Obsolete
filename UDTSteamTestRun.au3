#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.15.0 (Beta)
 Author:         RattletraPM

 Script Function:
	Temporarily swaps Undertale's EXE file in Steam's installation directory
	with the extracted file, then runs it. Once it has been closed, the
	script deletes all the copied files and restores the old EXE.

	Part of UDTranslation Kit.

	This script has been commented in english so that other translators will be
	able to understand how it works and modify it to their own needs.

#ce ----------------------------------------------------------------------------

#include <FileConstants.au3>
#include <File.au3>
#include <Array.au3>

Opt("TrayIconHide",1)	;No tray icon

;AutoIt includes a trailing backslash to @ScriptDir only when the script is run on the root of a drive,
;so we need to check if this is the case before doing anything as it could cause errors later on.
If StringTrimLeft(@ScriptDir, StringLen(@ScriptDir)-1)<>"\" Then
	$currentdir=@ScriptDir&"\"	;If the string doesn't have a current backslash, add it
Else
	$currentdir=@ScriptDir		;If it does, keep it that way
EndIf

$namever="UDTSteamTestRun v0.3"
$configfname=$currentdir&"udtkit_config.cfg"
$undertaledir=""

;Check if extr exists and it's not empty
$dirempty=DirGetSize($currentdir&"extr",1)
If @error<>0 Then
	MsgBox(16,$namever,"The extr folder doesn't exist.")
	Exit
EndIf
If $dirempty[1]==0 Then
	MsgBox(16,$namever,"The extr folder is empty.")
	Exit
EndIf
If FileExists($configfname) Then	;If a cfg file has been previously created, read Undertale.exe's dir from here
	$configfile=FileOpen($configfname, $FO_READ)
	$undertaledir=FileReadLine($configfile,2)
	FileClose($configfile)
Else								;If there isn't, choose a directory and then create the cfg file
	$filechoose=FileOpenDialog("Select UNDERTALE's executable file", @ScriptDir, "Executable files (*.exe)", $FD_FILEMUSTEXIST)
	$undertaledir = StringTrimRight($filechoose,StringLen($filechoose)-StringInStr($filechoose,"\",0,-1))
	$configfile=FileOpen($configfname, $FO_OVERWRITE)
	FileWriteLine($configfile, "; Undertale installation dir (Steam)")
	FileWriteLine($configfile, $undertaledir)
	FileClose($configfile)
EndIf
If FileExists($undertaledir&"UNDERTALE.old") Then	;If UNDERTALE.old exists then it means that the script closed unexpectedly and $undertaledir needs to be cleaned up
	MsgBox(64,$namever,"UDTSteamTestRun has detected it has crashed before and will now clean up UNDERTALE's install directory.")
	RestoreInstallDir()
	MsgBox(64,$namever,"UNDERTALE's install directory has been cleaned up. Open this tool again to do a test run.")
EndIf
If FileExists($undertaledir&"UNDERTALE.exe")==0 Then	;If UNDERTALE.exe doesn't exist in the chosen directory...
	MsgBox(16,$namever,"UNDERTALE.exe doesn't exist in the chosen directory. udtkit_config.cfg will be erased.")
	FileDelete($configfname)	;Delete the config file automatically, so the user can choose another file on the next run
	Exit
EndIf

;Rename UNDERTALE.exe to UNDERTALE.old
FileMove($undertaledir&"UNDERTALE.exe",$undertaledir&"UNDERTALE.old")

;List all the files in the directory
$filelistarr=_FileListToArray($currentdir&"extr")

;Copy all the files from extr to $undertaledir
$i=0
Do
	FileCopy($currentdir&"extr\"&$filelistarr[$i+1],$undertaledir&$filelistarr[$i+1])
	$i+=1
Until $i==$filelistarr[0]

;Run UNDERTALE.exe and wait until it stops running - notice how I didn't use RunWait as it acutally won't wait until it closes because
;UNDERTALE.exe opens another process and closes the old one, so AutoIt thinks it has closed while it's acutally still running
RunWait($undertaledir&"UNDERTALE.exe", $undertaledir)
ProcessWait("UNDERTALE.exe")	;If we don't wait for the new process to open first, there's no point in waiting for it to close
ProcessWaitClose("UNDERTALE.exe")	;Now that we know it's open, we'll wait for it to close
RestoreInstallDir()	;It's time to delete all the files that have been copied & rename UNDERTALE.old back to UNDERTALE.exe

Func RestoreInstallDir()
	$filelistarr=_FileListToArray($undertaledir)	;First off, we generate an array with all the files in $undertaledir
	_ArrayDelete($filelistarr,_ArraySearch($filelistarr, "UNDERTALE.old"))	;We don't want to delete UNDERTALE.old, so we'll delete it from the array
	$i=0
	Do												;ERASE EVERYTHING! MUHUAHUAHUAHUA...Well, almost everything.
		FileDelete($undertaledir&$filelistarr[$i+1])
	$i+=1
	Until $i==$filelistarr[0]-1
	FileMove($undertaledir&"UNDERTALE.old",$undertaledir&"UNDERTALE.exe")
EndFunc