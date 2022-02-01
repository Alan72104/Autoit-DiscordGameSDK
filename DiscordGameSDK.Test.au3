#include <Date.au3>
#include "DiscordGameSDK.au3"
#include "LibDebug.au3"

HotKeySet("{F7}", "Terminate")

Func Main()
    ; Init must be called once with a correct application id
    If Not _Discord_Init(935375293437337630) Then
        Exit Throw("Main", "Failed to init", @error, @extended)
    EndIf
    
    ; Set the log handler
    _Discord_SetLogHook($DISCORD_LOGLEVEL_DEBUG, LogHookHandler)
    
    ; OnCurrentUserUpdate must be fired once before we can call GetCurrentUser
    _Discord_UserManager_OnCurrentUserUpdate(OnCurrentUserUpdateHandler)
    
    ; Test whether or not we have connection to the local discord client
    Local $locale = _Discord_ApplicationManager_GetCurrentLocale()
    c("Locale: $", 1, $locale)
    
    ; Get whatever user you want
    _Discord_UserManager_GetUser(450285582585692161, GetUserHandler)
    
    ; Set up the rich presense activity array
    Local $now = _Date_Time_GetSystemTime()
    Local $unixUtc = _DateDiff('s', "1970/01/01 00:00:00", _Date_Time_SystemTimeToDateTimeStr($now, 1))
    Local $aActivity[18]
    $aActivity[3] = "state"
    $aActivity[4] = "details"
    $aActivity[5] = $unixUtc
    $aActivity[6] = $unixUtc + 30 * 60
    $aActivity[7] = "iconwithpadding"
    $aActivity[9] = "ay"
    
    ; Update the activity
    _Discord_ActivityManager_UpdateActivity($aActivity, UpdateActivityHandler)
    
    Local $t = TimerInit()
    While TimerDiff($t) < 10000 * 1000
        ; You must keep runing all pending callbacks in loop
        Local $res = _Discord_RunCallbacks()
        If $res <> $DISCORD_RESULT_OK Then
            c("RunCallbacks failed with $", 1, _Discord_GetResultString($res))
            ExitLoop
        EndIf
    WEnd
EndFunc

Main()

Func UpdateActivityHandler($result)
    If $result <> $DISCORD_RESULT_OK Then
        c("UpdateActivity failed with $", 1, _Discord_GetResultString($result))
    Else
        c("UpdateActivity succeeded")
    EndIf
EndFunc

Func GetUserHandler($result, $user)
    If $result <> $DISCORD_RESULT_OK Then
        c("GetUser failed with $", 1, _Discord_GetResultString($result))
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
        c("GetCurrentUser failed with $", 1, _Discord_GetResultString(@error))
    Else
        c("User updated\n  Id: $\n  Username: $\n  Discriminator: $\n  Avatar: $\n  Bot: $", 1, $user[0], $user[1], $user[2], $user[3], $user[4])
    EndIf
EndFunc

Func Terminate()
    Exit
EndFunc