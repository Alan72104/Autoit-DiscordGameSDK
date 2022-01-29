#include <Date.au3>
#include "DiscordGameSDK.au3"
#include "LibDebug.au3"

HotKeySet("{F7}", "Terminate")

Func Main()
    If Not _Discord_Init(935375293437337630) Then
        Exit Throw("Main", "Failed to init", @error, @extended)
    EndIf
    
    _Discord_SetLogHook($DISCORD_LOGLEVEL_DEBUG, LogHookHandler)
    
    _Discord_UserManager_OnCurrentUserUpdate(OnCurrentUserUpdateHandler)
    
    Local $locale = _Discord_ApplicationManager_GetCurrentLocale()
    c("Locale: $", 1, $locale)
    
    _Discord_UserManager_GetUser(450285582585692161, GetUserHandler)
    
    Local $now = _Date_Time_GetSystemTime()
    Local $unixUtc = _DateDiff('s', "1970/01/01 00:00:00", _Date_Time_SystemTimeToDateTimeStr($now, 1))
    Local $aActivity[18]
    $aActivity[1] = 935375293437337630
    $aActivity[2] = "name"
    $aActivity[3] = "state"
    $aActivity[4] = "details"
    $aActivity[5] = $unixUtc
    $aActivity[6] = $unixUtc + 30 * 60
    $aActivity[7] = "iconwithpadding"
    $aActivity[9] = "ay"
    
    _Discord_ActivityManager_UpdateActivity($aActivity, UpdateActivityHandler)
    
    Local $t = TimerInit()
    While TimerDiff($t) < 1000 * 1000
        If Not _Discord_RunCallbacks() Then
            c("RunCallbacks failed with $", 1, _Discord_GetErrorString(@error))
        EndIf
    WEnd
    
    ; ca($__Discord_apMethodPtrs)
    ; _WinAPI_DisplayStruct($__Discord_atMethodInterfaces[$__DISCORD_CORE], $__DISCORD_tagCOREMETHODS)
    ; _WinAPI_DisplayStruct($__Discord_atMethodInterfaces[$__DISCORD_APPLICATIONMANAGER], $__DISCORD_tagAPPLICATIONMANAGERMETHODS)
EndFunc

Main()

Func UpdateActivityHandler($result)
    If $result <> $DISCORD_OK Then
        c("UpdateActivity failed with $", 1, _Discord_GetErrorString(@error))
    Else
        c("UpdateActivity succeeded")
    EndIf
EndFunc

Func GetUserHandler($result, $user)
    If $result <> $DISCORD_OK Then
        c("GetUser failed with $", 1, _Discord_GetErrorString(@error))
    Else
        c("Got user\n  Id: $\n  Username: $\n  Discriminator: $\n  Avatar: $\n  Bot: $", 1, $user[0], $user[1], $user[2], $user[3], $user[4])
    EndIf
EndFunc

Func LogHookHandler($level, $msg)
    c("Log: level $, $", 1, $level, $msg)
EndFunc

Func OnCurrentUserUpdateHandler()
    c("OnCurrentUserUpdateHandler fired")
    Local $user = _Discord_UserManager_GetCurrentUser()
    If $user = False Then
        c("GetCurrentUser failed with $", 1, _Discord_GetErrorString(@error))
    Else
        c("User updated\n  Id: $\n  Username: $\n  Discriminator: $\n  Avatar: $\n  Bot: $", 1, $user[0], $user[1], $user[2], $user[3], $user[4])
    EndIf
EndFunc

Func Terminate()
    Exit
EndFunc