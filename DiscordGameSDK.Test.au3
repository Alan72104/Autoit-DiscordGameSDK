#include <GDIPlus.au3>
#include <GUIConstants.au3>
#include <Date.au3>
#include "DiscordGameSDK.au3"
#include "LibDebug.au3"

Global Const $gui = True
Global $hGui, $hPic
HotKeySet("{F7}", "Terminate")

; !!This SDK is quite unstable so random crash might occur!!
; !!Always refer to the official guide!!

; Issues:
;     Image fetching currently has a known bug causing it to always fail
;     _Discord_RelationshipManager_Filter() is not implemented on x86 bitness, thus the whole manager is unusable on x86

; First do the Step 1 and Get Set Up in the official guide
; https://discord.com/developers/docs/game-sdk/sdk-starter-guide
; Download the sdk, extract,
; rename the DLL in "discord_game_sdk\lib\x86_64" folder to "discord_game_sdk64.dll",
; then copy both DLLs in "\x86" and "\x86_64" to your main script folder and get going

Func Main()
    ; Init must be called once with a correct application id!
    If Not _Discord_Init(939233557233139742) Then
        Exit Throw("Main", "Failed to init", @error, @extended)
    EndIf
    
    If $gui Then
        ; Create the gui
        $hGui = GUICreate("DiscordGameSDK test", 500, 500)
        $hPic = GUICtrlCreatePic("", 0, 0, 100, 100, $SS_BITMAP)
        GUISetState(@SW_SHOW)
    EndIf
    
    ; Set the log handler
    _Discord_SetLogHook($DISCORD_LOGLEVEL_DEBUG, LogHookHandler)
    
    ; OnCurrentUserUpdate must be fired once before we can call GetCurrentUser
    _Discord_UserManager_OnCurrentUserUpdate(OnCurrentUserUpdateHandler)
    
    ; Test whether we have connection to the local discord client
    Local $locale = _Discord_ApplicationManager_GetCurrentLocale()
    c("Locale: $", 1, $locale)
    Local $locale = _Discord_ApplicationManager_GetCurrentBranch()
    c("Branch: $", 1, $locale)
    
    ; Get whatever user you want
    _Discord_UserManager_GetUser(159985870458322944, GetUserHandler)
    
    ; Set up the rich presence activity
    Local $now = _Date_Time_GetSystemTime()
    Local $unixUtc = _DateDiff('s', "1970/01/01 00:00:00", _Date_Time_SystemTimeToDateTimeStr($now, 1))
    Local $activity = _Discord_ActivityManager_MakeActivitySimple("State", "Details", _
                                                                  $unixUtc, $unixUtc + 30 * 60, _
                                                                  "axo", "Text for big image", _
                                                                  "ryzen", "Text for small image")
    
    ; Update the activity
    _Discord_ActivityManager_UpdateActivity($activity, UpdateActivityHandler)
    
    ; Assign this handle right away to get the initial relationships update
    ; This callback will only be fired when the whole list is initially loaded or was reset
    ; Wait for OnRefresh to fire to access a stable list
    _Discord_RelationshipManager_OnRefresh(RefreshHandler)
    
    Local $t = TimerInit()
    While TimerDiff($t) < 10000 * 1000
        ; You must keep runing all pending events in a loop
        Local $res = _Discord_RunCallbacks()
        If $res <> $DISCORD_RESULT_OK Then
            c("RunCallbacks failed with $", 1, _Discord_GetResultString($res))
            ExitLoop
        EndIf
        
        If $gui Then
            Local $msg = GUIGetMsg()
            Switch $msg
                Case $GUI_EVENT_CLOSE
                    ExitLoop
            EndSwitch
        EndIf
        Sleep(10)
    WEnd
EndFunc

Main()

; ==================================================

Func RefreshHandler()
    ; Filter a user's relationship list to be just friends
    ; Use this list as your base
    _Discord_RelationshipManager_Filter(FilterHandler)
    
    ; Loop over all friends a user has
    Local $count = _Discord_RelationshipManager_Count()
    For $i = 0 To $count - 1
        ; Get an individual relationship from the list
        Local $r = _Discord_RelationshipManager_GetAt($i)
        
        c("Relationships: $ $", 1, $r[0], $r[2])
        ; Save r off to a list of user's relationships...
    Next
EndFunc

Func FilterHandler($relationship)
    Return $relationship[0] = $DISCORD_RELATIONSHIPTYPE_FRIEND
EndFunc

; ==================================================

Func GetUserHandler($result, $user)
    If $result <> $DISCORD_RESULT_OK Then
        c("GetUser failed with $", 1, _Discord_GetResultString($result))
    Else
        c("Got user\n  Id: $\n  Username: $\n  Discriminator: $\n  Avatar: $\n  Bot: $", 1, $user[0], $user[1], $user[2], $user[3], $user[4])
        If $gui Then
            ; Request users' avatar data
            ; This can only be done after a user is successfully fetched
            ; 
            ; Currently this api only works with this one user, all else throws InternalError...
            Local $pfpHandle = _Discord_ImageManager_MakeHandle($DISCORD_IMAGETYPE_USER, 555488988379611156, 512)
            ; Local $pfpHandle = _Discord_ImageManager_MakeHandle($DISCORD_IMAGETYPE_USER, $user[0], 512)
            
            _Discord_ImageManager_Fetch($pfpHandle, True, FetchHandler)
        EndIf
    EndIf
EndFunc

Func FetchHandler($result, $handle)
    If $result <> $DISCORD_RESULT_OK Then
        c("Avatar fetch failed with $", 1, _Discord_GetResultString($result))
    Else
        c("Avatar fetch succeeded")
        If $gui Then
            ; Get the data and display on the gui
            Local $dataString = _Discord_ImageManager_GetData($handle)
            If $dataString == False Then Return c("But failed to get avatar data: $", 1, _Discord_GetResultString(@error))
            Local $dims = _Discord_ImageManager_GetDimensions($handle)
            If $dims == False Then Return c("But failed to get avatar dimensions: $", 1, _Discord_GetResultString(@error))
            
            Local $data = DllStructCreate("byte[" & $dims[0] * $dims[1] * 4 & "]")
            DllStructSetData($data, 1, $dataString)
            _GDIPlus_Startup()
            Local $bitmap = _GDIPlus_BitmapCreateFromScan0($dims[0], $dims[1], $GDIP_PXF32ARGB, $dims[0] * 4, DllStructGetPtr($data))
            Local $hBitmap = _GDIPlus_BitmapCreateHBITMAPFromBitmap($bitmap)
            GUICtrlSetPos($hPic, 500/2 - 150, 500/2 - 150, 300, 300)
            GUICtrlSendMsg($hPic, $STM_SETIMAGE, $IMAGE_BITMAP, $hBitmap)
            _WinAPI_DeleteObject($hBitmap)
            _GDIPlus_BitmapDispose($bitmap)
            _GDIPlus_Shutdown()
        EndIf
    EndIf
EndFunc

; ==================================================

Func UpdateActivityHandler($result)
    If $result <> $DISCORD_RESULT_OK Then
        c("UpdateActivity failed with $", 1, _Discord_GetResultString($result))
    Else
        c("UpdateActivity succeeded")
    EndIf
EndFunc

Func LogHookHandler($level, $msg)
    c("Log: level $, $", 1, $level, $msg)
EndFunc

Func OnCurrentUserUpdateHandler()
    c("OnCurrentUserUpdateHandler fired")
    Local $user = _Discord_UserManager_GetCurrentUser()
    If $user == False Then
        c("GetCurrentUser failed with $", 1, _Discord_GetResultString(@error))
    Else
        c("User updated\n  Id: $\n  Username: $\n  Discriminator: $\n  Avatar: $\n  Bot: $", 1, $user[0], $user[1], $user[2], $user[3], $user[4])
    EndIf
EndFunc

; ==================================================

Func Terminate()
    If $gui Then
        GUIDelete($hGui)
    EndIf
    Exit
EndFunc