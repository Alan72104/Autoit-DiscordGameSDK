#AutoIt3Wrapper_Run_AU3Check=Y
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#AutoIt3Wrapper_AU3Check_Stop_OnWarning=Y
#include-once
#include "DiscordGameSDK.Constants.au3"

#region Internal variables
Global $__Discord_hDll = 0
Global $__Discord_atEventInterfaces[$__DISCORD_CLASSCOUNT]  ; Event tables (Callback function ptr tables)
Global $__Discord_atMethodInterfaces[$__DISCORD_CLASSCOUNT] ; Method tables
Global $__Discord_apMethodPtrs[$__DISCORD_CLASSCOUNT]       ; Method table pointers
Global $__Discord_hLogHookCallback = 0
Global $__Discord_fnLogHookCallbackHandler = 0

Global $__Discord_ActivityManager_ahCallbacks[4]
Global $__Discord_ActivityManager_afnCallbackHandlers[4]
Global $__Discord_ActivityManager_hUpdateActivityCallback = 0
Global $__Discord_ActivityManager_fnUpdateActivityCallbackHandler = 0
Global $__Discord_ActivityManager_hClearActivityCallback = 0
Global $__Discord_ActivityManager_fnClearActivityCallbackHandler = 0
Global $__Discord_ActivityManager_hSendRequestReplyCallback = 0
Global $__Discord_ActivityManager_fnSendRequestReplyCallbackHandler = 0
Global $__Discord_ActivityManager_hSendInviteCallback = 0
Global $__Discord_ActivityManager_fnSendInviteCallbackHandler = 0
Global $__Discord_ActivityManager_hAcceptInviteCallback = 0
Global $__Discord_ActivityManager_fnAcceptInviteCallbackHandler = 0

Global $__Discord_ApplicationManager_hValidateOrExitCallback = 0
Global $__Discord_ApplicationManager_fnValidateOrExitCallbackHandler = 0
Global $__Discord_ApplicationManager_hGetOAuth2TokenCallback = 0
Global $__Discord_ApplicationManager_fnGetOAuth2TokenCallbackHandler = 0
Global $__Discord_ApplicationManager_hGetTicketCallback = 0
Global $__Discord_ApplicationManager_fnGetTicketCallbackHandler = 0

Global $__Discord_UserManager_ahCallbacks[1]
Global $__Discord_UserManager_afnCallbackHandlers[1]
Global $__Discord_UserManager_hGetUserCallback = 0
Global $__Discord_UserManager_fnGetUserCallbackHandler = 0
#endregion Internal variables

#region Core public functions
; #FUNCTION# ====================================================================================================================
; Name...........: _Discord_Init
; Description ...: Inits the Discord SDK, events and functions
; Syntax.........: _Discord_Init($iDiscordId [, $iFlags = $DISCORD_CREATEFLAGS_DEFAULT [, $sDllFolderPath = @ScriptDir]])
; Parameters ....: $iDiscordId     - [Int64]                  Your application's client id
;                  $iFlags         - [CREATEFLAGS] [Optional] Whether to connect to local Discord client or make a standalone
;                                  +                          connection
;                  $sDllFolderPath - [String]      [Optional] Full path to the "folder" of your dll, can contain trailing slash
; Return values .: Success - True
;                  Failure - False and sets @error
;                          | 1 - Id is not Int64
;                          | 2 - Invalid flag
;                          | 3 - Already initialized
;                          | 4 - Failed to open dll
;                          | 5 - Failed to call dll with @extended = DllCall error
;                          | 6 - Discord error with @extended = Discord result
; Author ........: Alan72104#4011
; Modified.......: 
; Remarks .......: Remember to pass "application client id" not your user id, or will result in undefined behavior or crash
;                  All SDK enum names share a template of $DISCORD_{TYPE}_{VALUE} e.g. $DISCORD_LOGLEVEL_INFO
;                  Enum types in function parameter lists are shown in ALLCAP     e.g. LOGLEVEL
;                  AbcHandler in function parameter lists are callback functions  e.g. LogHookCallbackHandler
; Related .......: $DISCORD_CREATEFLAGS...
; Link ..........: https://discord.com/developers/docs/game-sdk/discord#create
; ===============================================================================================================================
Func _Discord_Init($iDiscordId, $iFlags = $DISCORD_CREATEFLAGS_DEFAULT, $sDllFolderPath = @ScriptDir)
    If VarGetType($iDiscordId) <> "Int64" Then
        Return SetError(1, 0, False)
    EndIf
    If VarGetType($iFlags) <> "Int32" Or $iFlags < $DISCORD_CREATEFLAGS_DEFAULT Or $iFlags > $DISCORD_CREATEFLAGS_NOREQUIREDISCORD Then
        Return SetError(2, 0, False)
    EndIf
    If $__Discord_hDll Then
        Return SetError(3, 0, False)
    EndIf

    Local $tParams = DllStructCreate($__DISCORD_tagFFICREATEPARAMS)
    DllStructSetData($tParams, "ClientId", $iDiscordId)
    DllStructSetData($tParams, "Flags", $iFlags)
    ; Reference to core instance obj that will be sent back on static callback to dispatch to instance objects, OOP isn't used there
    DllStructSetData($tParams, "Events", Null)
    $__Discord_atEventInterfaces[$__DISCORD_CORE] = DllStructCreate($__DISCORD_tagCOREEVENTS)
    DllStructSetData($tParams, "EventData", DllStructGetPtr($__Discord_atEventInterfaces[$__DISCORD_CORE]))
    $__Discord_atEventInterfaces[$__DISCORD_APPLICATIONMANAGER] = DllStructCreate($__DISCORD_tagCOREEVENTS)
    DllStructSetData($tParams, "ApplicationEvents", DllStructGetPtr($__Discord_atEventInterfaces[$__DISCORD_APPLICATIONMANAGER]))
    DllStructSetData($tParams, "ApplicationVersion", 1)
    $__Discord_atEventInterfaces[$__DISCORD_USERMANAGER] = DllStructCreate($__DISCORD_tagUSERMANAGEREVENTS)
    DllStructSetData($tParams, "UserEvents", DllStructGetPtr($__Discord_atEventInterfaces[$__DISCORD_USERMANAGER]))
    DllStructSetData($tParams, "UserVersion", 1)
    $__Discord_atEventInterfaces[$__DISCORD_IMAGEMANAGER] = DllStructCreate($__DISCORD_tagIMAGEMANAGEREVENTS)
    DllStructSetData($tParams, "ImageEvents", DllStructGetPtr($__Discord_atEventInterfaces[$__DISCORD_IMAGEMANAGER]))
    DllStructSetData($tParams, "ImageVersion", 1)
    $__Discord_atEventInterfaces[$__DISCORD_ACTIVITYMANAGER] = DllStructCreate($__DISCORD_tagACTIVITYMANAGEREVENTS)
    DllStructSetData($tParams, "ActivityEvents", DllStructGetPtr($__Discord_atEventInterfaces[$__DISCORD_ACTIVITYMANAGER]))
    DllStructSetData($tParams, "ActivityVersion", 1)
    $__Discord_atEventInterfaces[$__DISCORD_RELATIONSHIPMANAGER] = DllStructCreate($__DISCORD_tagRELATIONSHIPMANAGEREVENTS)
    DllStructSetData($tParams, "RelationshipEvents", DllStructGetPtr($__Discord_atEventInterfaces[$__DISCORD_RELATIONSHIPMANAGER]))
    DllStructSetData($tParams, "RelationshipVersion", 1)
    $__Discord_atEventInterfaces[$__DISCORD_LOBBYMANAGER] = DllStructCreate($__DISCORD_tagLOBBYMANAGEREVENTS)
    DllStructSetData($tParams, "LobbyEvents", DllStructGetPtr($__Discord_atEventInterfaces[$__DISCORD_LOBBYMANAGER]))
    DllStructSetData($tParams, "LobbyVersion", 1)
    $__Discord_atEventInterfaces[$__DISCORD_NETWORKMANAGER] = DllStructCreate($__DISCORD_tagNETWORKMANAGEREVENTS)
    DllStructSetData($tParams, "NetworkEvents", DllStructGetPtr($__Discord_atEventInterfaces[$__DISCORD_NETWORKMANAGER]))
    DllStructSetData($tParams, "NetworkVersion", 1)
    $__Discord_atEventInterfaces[$__DISCORD_OVERLAYMANAGER] = DllStructCreate($__DISCORD_tagOVERLAYMANAGEREVENTS)
    DllStructSetData($tParams, "OverlayEvents", DllStructGetPtr($__Discord_atEventInterfaces[$__DISCORD_OVERLAYMANAGER]))
    DllStructSetData($tParams, "OverlayVersion", 1)
    $__Discord_atEventInterfaces[$__DISCORD_STORAGEMANAGER] = DllStructCreate($__DISCORD_tagSTORAGEMANAGEREVENTS)
    DllStructSetData($tParams, "StorageEvents", DllStructGetPtr($__Discord_atEventInterfaces[$__DISCORD_STORAGEMANAGER]))
    DllStructSetData($tParams, "StorageVersion", 1)
    $__Discord_atEventInterfaces[$__DISCORD_STOREMANAGER] = DllStructCreate($__DISCORD_tagSTOREMANAGEREVENTS)
    DllStructSetData($tParams, "StoreEvents", DllStructGetPtr($__Discord_atEventInterfaces[$__DISCORD_STOREMANAGER]))
    DllStructSetData($tParams, "StoreVersion", 1)
    $__Discord_atEventInterfaces[$__DISCORD_VOICEMANAGER] = DllStructCreate($__DISCORD_tagVOICEMANAGEREVENTS)
    DllStructSetData($tParams, "VoiceEvents", DllStructGetPtr($__Discord_atEventInterfaces[$__DISCORD_VOICEMANAGER]))
    DllStructSetData($tParams, "VoiceVersion", 1)
    $__Discord_atEventInterfaces[$__DISCORD_ACHIEVEMENTMANAGER] = DllStructCreate($__DISCORD_tagACHIEVEMENTMANAGEREVENTS)
    DllStructSetData($tParams, "AchievementEvents", DllStructGetPtr($__Discord_atEventInterfaces[$__DISCORD_ACHIEVEMENTMANAGER]))
    DllStructSetData($tParams, "AchievementVersion", 1)

    Local $hDll = -1
    If StringRight($sDllFolderPath, 1) = "\" Or StringRight($sDllFolderPath, 1) = "/" Then
    Else
        $sDllFolderPath &= "\"
    EndIf
    If @AutoItX64 Then
        $hDll = DllOpen($sDllFolderPath & "discord_game_sdk64.dll")
    Else
        $hDll = DllOpen($sDllFolderPath & "discord_game_sdk32.dll")
    EndIf
    If $hDll = -1 Then
        Return SetError(4, 0, False)
    EndIf
    $__Discord_hDll = $hDll

    OnAutoItExitRegister("__Discord_Dispose")
    __Discord_InitEvents()

    ; Result DiscordCreate(UInt32 version, ref FFICreateParams createParams, out IntPtr manager);
    Local $aResult = DllCall($__Discord_hDll, "int:cdecl", "DiscordCreate", "uint", 2, "ptr", DllStructGetPtr($tParams), "ptr*", Null)
    $__Discord_apMethodPtrs[$__DISCORD_CORE] = $aResult[3]
    
    If @error Then
        Return SetError(5, @error, False)
    EndIf

    If $aResult[0] <> $DISCORD_RESULT_OK Then
        __Discord_Dispose()
        Return SetError(6, $aResult[0], False)
    EndIf

    ; Retrieve the method ptr table for this core instance
    $__Discord_atMethodInterfaces[$__DISCORD_CORE] = DllStructCreate($__DISCORD_tagCOREMETHODS, $__Discord_apMethodPtrs[$__DISCORD_CORE])

    __Discord_AchievementManager_Init()
    __Discord_ActivityManager_Init()
    __Discord_ApplicationManager_Init()
    __Discord_ImageManager_Init()
    __Discord_LobbyManager_Init()
    __Discord_NetworkManager_Init()
    __Discord_OverlayManager_Init()
    __Discord_RelationshipManager_Init()
    __Discord_StorageManager_Init()
    __Discord_StoreManager_Init()
    __Discord_UserManager_Init()
    __Discord_VoiceManager_Init()
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Discord_SetLogHook
; Description ...: Registers a logging callback function with the minimum level of message to receive
; Syntax.........: _Discord_SetLogHook($iLogLevel, $fnHandler)
; Parameters ....: $iLogLevel - [LOGLEVEL]               The minimum level of event to log
;                  $fnHandler - [LogHookCallbackHandler] The callback function to catch the messages
;                             + void LogHookCallbackHandler(LOGLEVEL level, String message)
; Return values .: Success            - True
;                  Invalid parameters - False
; Author ........: Alan72104#4011
; Modified.......: 
; Remarks .......: 
; Related .......: $DISCORD_LOGLEVEL...
; Link ..........: https://discord.com/developers/docs/game-sdk/discord#setloghook
; ===============================================================================================================================
Func _Discord_SetLogHook($iLogLevel, $fnHandler)
    If VarGetType($iLogLevel) <> "Int32" Or $iLogLevel < $DISCORD_LOGLEVEL_ERROR Or $iLogLevel > $DISCORD_LOGLEVEL_DEBUG Or VarGetType($fnHandler) <> "UserFunction" Then
        Return False
    EndIf
    If $__Discord_hLogHookCallback = 0 Then
        $__Discord_hLogHookCallback = DllCallbackRegister("__Discord_LogHookCallbackHandler", "none:cdecl", "ptr;int;str")
    EndIf
    $__Discord_fnLogHookCallbackHandler = $fnHandler
    DllCallAddress("none:cdecl", _
                   DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_CORE], "SetLogHook"), _
                   "ptr", $__Discord_apMethodPtrs[$__DISCORD_CORE], _
                   "int", $iLogLevel, _
                   "ptr", Null, _
                   "ptr", DllCallbackGetPtr($__Discord_hLogHookCallback))
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Discord_GetResultString
; Description ...: Gets the name of a Discord result code
; Syntax.........: _Discord_GetResultString($iError)
; Parameters ....: $iError - [RESULT] Discord result code
; Return values .: Success - Result string
;                  Failure - "Invalid result code"
; Author ........: Alan72104#4011
; Modified.......: 
; Remarks .......: Enum number to name
; Related .......: $DISCORD_RESULT...
; Link ..........: https://discord.com/developers/docs/game-sdk/discord#data-models
; ===============================================================================================================================
Func _Discord_GetResultString($iError)
    Switch $iError
        Case 0
            Return "Ok"
        Case 1
            Return "ServiceUnavailable"
        Case 2
            Return "InvalidVersion"
        Case 3
            Return "LockFailed"
        Case 4
            Return "InternalError"
        Case 5
            Return "InvalidPayload"
        Case 6
            Return "InvalidCommand"
        Case 7
            Return "InvalidPermissions"
        Case 8
            Return "NotFetched"
        Case 9
            Return "NotFound"
        Case 10
            Return "Conflict"
        Case 11
            Return "InvalidSecret"
        Case 12
            Return "InvalidJoinSecret"
        Case 13
            Return "NoEligibleActivity"
        Case 14
            Return "InvalidInvite"
        Case 15
            Return "NotAuthenticated"
        Case 16
            Return "InvalidAccessToken"
        Case 17
            Return "ApplicationMismatch"
        Case 18
            Return "InvalidDataUrl"
        Case 19
            Return "InvalidBase64"
        Case 20
            Return "NotFiltered"
        Case 21
            Return "LobbyFull"
        Case 22
            Return "InvalidLobbySecret"
        Case 23
            Return "InvalidFilename"
        Case 24
            Return "InvalidFileSize"
        Case 25
            Return "InvalidEntitlement"
        Case 26
            Return "NotInstalled"
        Case 27
            Return "NotRunning"
        Case 28
            Return "InsufficientBuffer"
        Case 29
            Return "PurchaseCanceled"
        Case 30
            Return "InvalidGuild"
        Case 31
            Return "InvalidEvent"
        Case 32
            Return "InvalidChannel"
        Case 33
            Return "InvalidOrigin"
        Case 34
            Return "RateLimited"
        Case 35
            Return "OAuth2Error"
        Case 36
            Return "SelectChannelTimeout"
        Case 37
            Return "GetGuildTimeout"
        Case 38
            Return "SelectVoiceForceRequired"
        Case 39
            Return "CaptureShortcutAlreadyListening"
        Case 40
            Return "UnauthorizedForAchievement"
        Case 41
            Return "InvalidGiftCode"
        Case 42
            Return "PurchaseError"
        Case 43
            Return "TransactionAborted"
        Case Else
            Return "Invalid result code"
    EndSwitch
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Discord_RunCallbacks
; Description ...: Runs all pending SDK callbacks
; Syntax.........: _Discord_RunCallbacks()
; Parameters ....: None
; Return values .: Discord result
; Author ........: Alan72104#4011
; Modified.......: 
; Remarks .......: Put this in your game's main event loop, like Update()
;                  This function also serves as a way to know that the local Discord client is still connected
;                  If the user closes Discord while playing your game, RunCallbacks() will return $DISCORD_RESULT_NOTRUNNING
; Related .......: $DISCORD_RESULT...
; Link ..........: https://discord.com/developers/docs/game-sdk/discord#runcallbacks
; ===============================================================================================================================
Func _Discord_RunCallbacks()
    Local $aResult = DllCallAddress("int:cdecl", _
                                    DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_CORE], "RunCallbacks"), _
                                    "ptr", $__Discord_apMethodPtrs[$__DISCORD_CORE])
    Return $aResult[0]
EndFunc
#endregion Core public functions

#region Core private functions
Func __Discord_InitEvents()
EndFunc

; Handler for: void SetLogHookCallback(IntPtr ptr, LogLevel level, [MarshalAs(UnmanagedType.LPStr)]string message)
Func __Discord_LogHookCallbackHandler($pPtr, $iLevel, $sMessage)
    #forceref $pPtr
    If $__Discord_fnLogHookCallbackHandler <> 0 Then
        $__Discord_fnLogHookCallbackHandler($iLevel, $sMessage)
    EndIf
EndFunc

Func __Discord_Dispose()
    OnAutoItExitUnRegister("__Discord_Dispose")
    __Discord_AchievementManager_Dispose()
    __Discord_ActivityManager_Dispose()
    __Discord_ApplicationManager_Dispose()
    __Discord_ImageManager_Dispose()
    __Discord_LobbyManager_Dispose()
    __Discord_NetworkManager_Dispose()
    __Discord_OverlayManager_Dispose()
    __Discord_RelationshipManager_Dispose()
    __Discord_StorageManager_Dispose()
    __Discord_StoreManager_Dispose()
    __Discord_UserManager_Dispose()
    __Discord_VoiceManager_Dispose()
    Local $timer = TimerInit()
    While TimerDiff($timer) < 250
        _Discord_RunCallbacks()
    WEnd
    If $__Discord_apMethodPtrs[$__DISCORD_CORE] Then
        ; ConsoleWrite("Disposing Discord" & @CRLF)
        DllCallAddress("none:cdecl", _
                       DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_CORE], "Destroy"), _
                       "ptr", $__Discord_apMethodPtrs[$__DISCORD_CORE])
        ; ConsoleWrite("Disposing Completed" & @CRLF)
        $__Discord_apMethodPtrs[$__DISCORD_CORE] = 0
    EndIf
    If $__Discord_hLogHookCallback Then
        DllCallbackFree($__Discord_hLogHookCallback)
        $__Discord_hLogHookCallback = 0
    EndIf
    If $__Discord_hDll Then
        DllClose($__Discord_hDll)
        $__Discord_hDll = 0
    EndIf
EndFunc
#endregion Core private functions

#region Achievement manager private functions
Func __Discord_AchievementManager_Init()
    $__Discord_apMethodPtrs[$__DISCORD_ACHIEVEMENTMANAGER] = DllCallAddress("ptr:cdecl", _
                                                                            DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_CORE], "GetAchievementManager"), _
                                                                            "ptr", $__Discord_apMethodPtrs[$__DISCORD_CORE])[0]
    $__Discord_atMethodInterfaces[$__DISCORD_ACHIEVEMENTMANAGER] = DllStructCreate($__DISCORD_tagACHIEVEMENTMANAGERMETHODS, $__Discord_apMethodPtrs[$__DISCORD_ACHIEVEMENTMANAGER])
    __Discord_AchievementManager_InitEvents()
EndFunc

Func __Discord_AchievementManager_InitEvents()
EndFunc

Func __Discord_AchievementManager_Dispose()
EndFunc
#endregion Achievement manager private functions

#region Activity manager public functions
; #FUNCTION# ====================================================================================================================
; Name...........: _Discord_ActivityManager_OnActivityJoin
; Description ...: Sets the event handler
; Syntax.........: _Discord_ActivityManager_OnActivityJoin($fnHandler)
; Parameters ....: $fnHandler - [OnActivityJoinHandler] Fires when a user accepts a game chat invite or receives confirmation
;                             +                         from Asking to Join
;                             + void OnActivityJoinHandler(String secret)
; Return values .: Success            - True
;                  Invalid parameters - False
; Author ........: Alan72104#4011
; Modified.......: 
; Remarks .......: 
; Related .......: 
; Link ..........: https://discord.com/developers/docs/game-sdk/activities#onactivityjoin
; ===============================================================================================================================
Func _Discord_ActivityManager_OnActivityJoin($fnHandler)
    If VarGetType($fnHandler) <> "UserFunction" Then
        Return False
    EndIf
    $__Discord_ActivityManager_afnCallbackHandlers[0] = $fnHandler
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Discord_ActivityManager_OnActivitySpectate
; Description ...: Sets the event handler 
; Syntax.........: _Discord_ActivityManager_OnActivitySpectate($fnHandler)
; Parameters ....: $fnHandler - [OnActivitySpectateHandler] Fires when a user accepts a spectate chat invite or clicks the
;                             +                             Spectate button on a user's profile
;                             + void OnActivitySpectateHandler(String secret)
; Return values .: Success            - True
;                  Invalid parameters - False
; Author ........: Alan72104#4011
; Modified.......: 
; Remarks .......: 
; Related .......: 
; Link ..........: https://discord.com/developers/docs/game-sdk/activities#onactivityspectate
; ===============================================================================================================================
Func _Discord_ActivityManager_OnActivitySpectate($fnHandler)
    If VarGetType($fnHandler) <> "UserFunction" Then
        Return False
    EndIf
    $__Discord_ActivityManager_afnCallbackHandlers[1] = $fnHandler
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Discord_ActivityManager_OnActivityJoinRequest
; Description ...: Sets the event handler 
; Syntax.........: _Discord_ActivityManager_OnActivityJoinRequest($fnHandler)
; Parameters ....: $fnHandler - [OnActivityJoinRequestHandler] Fires when a user asks to join the current user's game
;                             + void OnActivityJoinRequestHandler(User user)
; Return values .: Success            - True
;                  Invalid parameters - False
; Author ........: Alan72104#4011
; Modified.......: 
; Remarks .......: 
; Related .......: User array [Int64 Id, String Username, String Discriminator, String Avatar, Bool Bot]
; Link ..........: https://discord.com/developers/docs/game-sdk/activities#onactivityjoinrequest
; ===============================================================================================================================
Func _Discord_ActivityManager_OnActivityJoinRequest($fnHandler)
    If VarGetType($fnHandler) <> "UserFunction" Then
        Return False
    EndIf
    $__Discord_ActivityManager_afnCallbackHandlers[2] = $fnHandler
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Discord_ActivityManager_OnActivityInvite
; Description ...: Sets the event handler 
; Syntax.........: _Discord_ActivityManager_OnActivityInvite($fnHandler)
; Parameters ....: $fnHandler - [OnActivityInviteHandler] Fires when the user receives a join or spectate invite
;                             + void OnActivityInviteHandler(ACTIVITYACTIONTYPE type, User user, Activity activity)
; Return values .: Success            - True
;                  Invalid parameters - False
; Author ........: Alan72104#4011
; Modified.......: 
; Remarks .......: 
; Related .......: User array [Int64 Id, String Username, String Discriminator, String Avatar, Bool Bot]
;                  Activity array [Int Type, Int64 ApplicationId, String Name, String State, String Details,
;                                  Int64 Timestamps_Start, Int64 Timerstamps_End, String Assets_LargeImage,
;                                  String Assets_LargeText, String Assets_SmallImage, String Assets_SmallText, String Party_Id,
;                                  Int Party_Size_CurrentSize, Int Party_Size_MaxSize, String Secrets_Match, String Secrets_Join,
;                                  String Secrets_Spectate, Bool Instance]
; Link ..........: https://discord.com/developers/docs/game-sdk/activities#onactivityinvite
; ===============================================================================================================================
Func _Discord_ActivityManager_OnActivityInvite($fnHandler)
    If VarGetType($fnHandler) <> "UserFunction" Then
        Return False
    EndIf
    $__Discord_ActivityManager_afnCallbackHandlers[3] = $fnHandler
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Discord_ActivityManager_RegisterCommand
; Description ...: Registers a command by which Discord can launch your game
; Syntax.........: _Discord_ActivityManager_RegisterCommand($sCommand)
; Parameters ....: $sCommand - [String] The command to register
; Return values .: Success - True
;                  Failure - False with @error = Discord result
; Author ........: Alan72104#4011
; Modified.......: 
; Remarks .......: This might be a custom protocol, like "my-awesome-game://", or a path to an executable
;                  It also supports any launch parameters that may be needed, like "game.exe --full-screen --no-hax"
; Related .......: $DISCORD_RESULT...
; Link ..........: https://discord.com/developers/docs/game-sdk/activities#registercommand
; ===============================================================================================================================
Func _Discord_ActivityManager_RegisterCommand($sCommand)
    Local $aResult = DllCallAddress("int:cdecl", _
                                    DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_ACTIVITYMANAGER], "RegisterCommand"), _
                                    "ptr", $__Discord_apMethodPtrs[$__DISCORD_ACTIVITYMANAGER], _
                                    "str", $sCommand)
    If $aResult[0] <> $DISCORD_RESULT_OK Then
        Return SetError($aResult[0], 0, False)
    EndIf
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Discord_ActivityManager_RegisterSteam
; Description ...: Used if you are distributing this SDK on Steam
;                  Registers your game's Steam app id for the protocol "steam://run-game-id/<id>"
; Syntax.........: _Discord_ActivityManager_RegisterSteam($iSteamId)
; Parameters ....: $iSteamId - [Uint] Your game's Steam app id
; Return values .: Success - True
;                  Failure - False with @error = Discord result
; Author ........: Alan72104#4011
; Modified.......: 
; Remarks .......: 
; Related .......: $DISCORD_RESULT...
; Link ..........: https://discord.com/developers/docs/game-sdk/activities#registersteam
; ===============================================================================================================================
Func _Discord_ActivityManager_RegisterSteam($iSteamId)
    Local $aResult = DllCallAddress("int:cdecl", _
                                    DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_ACTIVITYMANAGER], "RegisterSteam"), _
                                    "ptr", $__Discord_apMethodPtrs[$__DISCORD_ACTIVITYMANAGER], _
                                    "int", $iSteamId)
    If $aResult[0] <> $DISCORD_RESULT_OK Then
        Return SetError($aResult[0], 0, False)
    EndIf
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Discord_ActivityManager_UpdateActivity
; Description ...: Sets a user's presence in Discord to a new activity, this has a rate limit of 5 updates per 20 seconds
; Syntax.........: _Discord_ActivityManager_UpdateActivity($aActivity, $fnHandler)
; Parameters ....: $aActivity - [Activity] The new activity for the user
;                  $fnHandler - [UpdateActivityCallbackHandler] Callback which Discord returns the result to
;                             + void UpdateActivityCallbackHandler(RESULT result)
; Return values .: Success            - True
;                  Invalid parameters - False
; Author ........: Alan72104#4011
; Modified.......: 
; Remarks .......: 
; Related .......: Activity array [Int Type, Int64 ApplicationId, String Name, String State, String Details,
;                                  Int64 Timestamps_Start, Int64 Timerstamps_End, String Assets_LargeImage,
;                                  String Assets_LargeText, String Assets_SmallImage, String Assets_SmallText, String Party_Id,
;                                  Int Party_Size_CurrentSize, Int Party_Size_MaxSize, String Secrets_Match, String Secrets_Join,
;                                  String Secrets_Spectate, Bool Instance]
;                  $DISCORD_RESULT...
; Link ..........: https://discord.com/developers/docs/game-sdk/activities#updateactivity
; ===============================================================================================================================
Func _Discord_ActivityManager_UpdateActivity($aActivity, $fnHandler)
    If VarGetType($fnHandler) <> "UserFunction" Then
        Return False
    EndIf
    If UBound($aActivity) <> 18 Then
        Return False
    EndIf
    If $__Discord_ActivityManager_hUpdateActivityCallback = 0 Then
        $__Discord_ActivityManager_hUpdateActivityCallback = DllCallbackRegister("__Discord_ActivityManager_UpdateActivityCallbackHandler", "none:cdecl", "ptr;int")
    EndIf
    $__Discord_ActivityManager_fnUpdateActivityCallbackHandler = $fnHandler
    Local $tActivity = DllStructCreate($__DISCORD_tagACTIVITY)
    ; ActivityType is strictly for the purpose of handling events that you receive from Discord; though the SDK/our API will not reject a payload with an ActivityType sent, it will be discarded and will not change anything in the client.
    ; DllStructSetData($tActivity, "Type", $aActivity[0])
    DllStructSetData($tActivity, "ApplicationId", $aActivity[1])
    DllStructSetData($tActivity, "Name", $aActivity[2])
    DllStructSetData($tActivity, "State", $aActivity[3])
    DllStructSetData($tActivity, "Details", $aActivity[4])
    DllStructSetData($tActivity, "Timestamps_Start", $aActivity[5])
    DllStructSetData($tActivity, "Timerstamps_End", $aActivity[6])
    DllStructSetData($tActivity, "Assets_LargeImage", $aActivity[7])
    DllStructSetData($tActivity, "Assets_LargeText", $aActivity[8])
    DllStructSetData($tActivity, "Assets_SmallImage", $aActivity[9])
    DllStructSetData($tActivity, "Assets_SmallText", $aActivity[10])
    DllStructSetData($tActivity, "Party_Id", $aActivity[11])
    DllStructSetData($tActivity, "Party_Size_CurrentSize", $aActivity[12])
    DllStructSetData($tActivity, "Party_Size_MaxSize", $aActivity[13])
    DllStructSetData($tActivity, "Secrets_Match", $aActivity[14])
    DllStructSetData($tActivity, "Secrets_Join", $aActivity[15])
    DllStructSetData($tActivity, "Secrets_Spectate", $aActivity[16])
    DllStructSetData($tActivity, "Instance", $aActivity[17])
    DllCallAddress("none:cdecl", _
                   DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_ACTIVITYMANAGER], "UpdateActivity"), _
                   "ptr", $__Discord_apMethodPtrs[$__DISCORD_ACTIVITYMANAGER], _
                   "ptr", DllStructGetPtr($tActivity), _
                   "ptr", Null, _
                   "ptr", DllCallbackGetPtr($__Discord_ActivityManager_hUpdateActivityCallback))
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Discord_ActivityManager_ClearActivity
; Description ...: Clears a user's presence in Discord to make it show nothing
; Syntax.........: _Discord_ActivityManager_ClearActivity($fnHandler)
; Parameters ....: $fnHandler - [ClearActivityCallbackHandler] Callback which Discord returns the result to
;                             + void ClearActivityCallbackHandler(RESULT result)
; Return values .: Success            - True
;                  Invalid parameters - False
; Author ........: Alan72104#4011
; Modified.......: 
; Remarks .......: 
; Related .......: $DISCORD_RESULT...
; Link ..........: https://discord.com/developers/docs/game-sdk/activities#clearactivity
; ===============================================================================================================================
Func _Discord_ActivityManager_ClearActivity($fnHandler)
    If VarGetType($fnHandler) <> "UserFunction" Then
        Return False
    EndIf
    If $__Discord_ActivityManager_hClearActivityCallback = 0 Then
        $__Discord_ActivityManager_hClearActivityCallback = DllCallbackRegister("__Discord_ActivityManager_ClearActivityCallbackHandler", "none:cdecl", "ptr;int")
    EndIf
    $__Discord_ActivityManager_fnClearActivityCallbackHandler = $fnHandler
    DllCallAddress("none:cdecl", _
                   DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_ACTIVITYMANAGER], "ClearActivity"), _
                   "ptr", $__Discord_apMethodPtrs[$__DISCORD_ACTIVITYMANAGER], _
                   "ptr", Null, _
                   "ptr", DllCallbackGetPtr($__Discord_ActivityManager_hClearActivityCallback))
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Discord_ActivityManager_SendRequestReply
; Description ...: Sends a reply to an Ask to Join request
; Syntax.........: _Discord_ActivityManager_SendRequestReply($iUserId, $iReply, $fnHandler)
; Parameters ....: $iUserId   - [Int64] The user id of the person who asked to join
;                  $iReply    - [ACTIVITYJOINREQUESTREPLY] No, Yes, or Ignore
;                  $fnHandler - [SendRequestReplyCallbackHandler] Callback which Discord returns the result to
;                             + void SendRequestReplyCallbackHandler(RESULT result)
; Return values .: Success            - True
;                  Invalid parameters - False
; Author ........: Alan72104#4011
; Modified.......: 
; Remarks .......: 
; Related .......: $DISCORD_ACTIVITYJOINREQUESTREPLY..., $DISCORD_RESULT...
; Link ..........: https://discord.com/developers/docs/game-sdk/activities#sendrequestreply
; ===============================================================================================================================
Func _Discord_ActivityManager_SendRequestReply($iUserId, $iReply, $fnHandler)
    If VarGetType($fnHandler) <> "UserFunction" Then
        Return False
    EndIf
    If $__Discord_ActivityManager_hSendRequestReplyCallback = 0 Then
        $__Discord_ActivityManager_hSendRequestReplyCallback = DllCallbackRegister("__Discord_ActivityManager_SendRequestReplyCallbackHandler", "none:cdecl", "ptr;int")
    EndIf
    $__Discord_ActivityManager_fnSendRequestReplyCallbackHandler = $fnHandler
    DllCallAddress("none:cdecl", _
                   DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_ACTIVITYMANAGER], "SendRequestReply"), _
                   "ptr", $__Discord_apMethodPtrs[$__DISCORD_ACTIVITYMANAGER], _
                   "int64", $iUserId, _
                   "int", $iReply, _
                   "ptr", Null, _
                   "ptr", DllCallbackGetPtr($__Discord_ActivityManager_hSendRequestReplyCallback))
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Discord_ActivityManager_SendInvite
; Description ...: Sends a game invite to a given user
; Syntax.........: _Discord_ActivityManager_SendInvite($iUserId, $iType, $sContent, $fnHandler)
; Parameters ....: $iUserId   - [Int64] The id of the user to invite
;                  $iType     - [ACTIVITYACTIONTYPE] Marks the invite as an invitation to join or spectate
;                  $sContent  - [String] A message to send along with the invite
;                  $fnHandler - [SendInviteCallbackHandler] Callback which Discord returns the result to
;                             + void SendInviteCallbackHandler(RESULT result)
; Return values .: Success            - True
;                  Invalid parameters - False
; Author ........: Alan72104#4011
; Modified.......: 
; Remarks .......: If you do not have a valid activity with all the required fields, this call will error
;                  See Activity Action Field Requirements for the fields required to have join and spectate invites function
;                  properly
; Related .......: $DISCORD_ACTIVITYACTIONTYPE..., $DISCORD_RESULT...
; Link ..........: https://discord.com/developers/docs/game-sdk/activities#sendinvite
; ===============================================================================================================================
Func _Discord_ActivityManager_SendInvite($iUserId, $iType, $sContent, $fnHandler)
    If VarGetType($fnHandler) <> "UserFunction" Then
        Return False
    EndIf
    If $__Discord_ActivityManager_hSendInviteCallback = 0 Then
        $__Discord_ActivityManager_hSendInviteCallback = DllCallbackRegister("__Discord_ActivityManager_SendInviteCallbackHandler", "none:cdecl", "ptr;int")
    EndIf
    $__Discord_ActivityManager_fnSendInviteCallbackHandler = $fnHandler
    DllCallAddress("none:cdecl", _
                   DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_ACTIVITYMANAGER], "SendInvite"), _
                   "ptr", $__Discord_apMethodPtrs[$__DISCORD_ACTIVITYMANAGER], _
                   "int64", $iUserId, _
                   "int", $iType, _
                   "str", $sContent, _
                   "ptr", Null, _
                   "ptr", DllCallbackGetPtr($__Discord_ActivityManager_hSendInviteCallback))
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Discord_ActivityManager_AcceptInvite
; Description ...: Accepts a game invitation from a given userId
; Syntax.........: _Discord_ActivityManager_AcceptInvite($iUserId, $fnHandler)
; Parameters ....: $iUserId   - [Int64] The user id of the person who invited you
;                  $fnHandler - [AcceptInviteCallbackHandler] Callback which Discord returns the result to
;                             + void AcceptInviteCallbackHandler(RESULT result)
; Return values .: Success            - True
;                  Invalid parameters - False
; Author ........: Alan72104#4011
; Modified.......: 
; Remarks .......: 
; Related .......: $DISCORD_RESULT...
; Link ..........: https://discord.com/developers/docs/game-sdk/activities#acceptinvite
; ===============================================================================================================================
Func _Discord_ActivityManager_AcceptInvite($iUserId, $fnHandler)
    If VarGetType($fnHandler) <> "UserFunction" Then
        Return False
    EndIf
    If $__Discord_ActivityManager_hAcceptInviteCallback = 0 Then
        $__Discord_ActivityManager_hAcceptInviteCallback = DllCallbackRegister("__Discord_ActivityManager_AcceptInviteCallbackHandler", "none:cdecl", "ptr;int")
    EndIf
    $__Discord_ActivityManager_fnAcceptInviteCallbackHandler = $fnHandler
    DllCallAddress("none:cdecl", _
                   DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_ACTIVITYMANAGER], "AcceptInvite"), _
                   "ptr", $__Discord_apMethodPtrs[$__DISCORD_ACTIVITYMANAGER], _
                   "int64", $iUserId, _
                   "ptr", Null, _
                   "ptr", DllCallbackGetPtr($__Discord_ActivityManager_hAcceptInviteCallback))
    Return True
EndFunc
#endregion Activity manager public functions

#region Activity manager private functions
Func __Discord_ActivityManager_Init()
    $__Discord_apMethodPtrs[$__DISCORD_ACTIVITYMANAGER] = DllCallAddress("ptr:cdecl", _
                                                                         DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_CORE], "GetActivityManager"), _
                                                                         "ptr", $__Discord_apMethodPtrs[$__DISCORD_CORE])[0]
    $__Discord_atMethodInterfaces[$__DISCORD_ACTIVITYMANAGER] = DllStructCreate($__DISCORD_tagACTIVITYMANAGERMETHODS, $__Discord_apMethodPtrs[$__DISCORD_ACTIVITYMANAGER])
    __Discord_ActivityManager_InitEvents()
EndFunc

Func __Discord_ActivityManager_InitEvents()
    $__Discord_ActivityManager_afnCallbackHandlers[0] = 0
    $__Discord_ActivityManager_ahCallbacks[0] = DllCallbackRegister("__DISCORD_ACTIVITYMANAGER_OnActivityJoinHandler", "none:cdecl", "ptr;str")
    DllStructSetData($__Discord_atEventInterfaces[$__DISCORD_ACTIVITYMANAGER], "OnActivityJoin", DllCallbackGetPtr($__Discord_ActivityManager_ahCallbacks[0]))
    $__Discord_ActivityManager_afnCallbackHandlers[1] = 0
    $__Discord_ActivityManager_ahCallbacks[1] = DllCallbackRegister("__DISCORD_ACTIVITYMANAGER_OnActivitySpectateHandler", "none:cdecl", "ptr;str")
    DllStructSetData($__Discord_atEventInterfaces[$__DISCORD_ACTIVITYMANAGER], "OnActivitySpectate", DllCallbackGetPtr($__Discord_ActivityManager_ahCallbacks[1]))
    $__Discord_ActivityManager_afnCallbackHandlers[2] = 0
    $__Discord_ActivityManager_ahCallbacks[2] = DllCallbackRegister("__DISCORD_ACTIVITYMANAGER_OnActivityJoinRequestHandler", "none:cdecl", "ptr;ptr")
    DllStructSetData($__Discord_atEventInterfaces[$__DISCORD_ACTIVITYMANAGER], "OnActivitySpectate", DllCallbackGetPtr($__Discord_ActivityManager_ahCallbacks[2]))
    $__Discord_ActivityManager_afnCallbackHandlers[3] = 0
    $__Discord_ActivityManager_ahCallbacks[3] = DllCallbackRegister("__DISCORD_ACTIVITYMANAGER_OnActivityInviteHandler", "none:cdecl", "ptr;int;ptr;ptr")
    DllStructSetData($__Discord_atEventInterfaces[$__DISCORD_ACTIVITYMANAGER], "OnActivitySpectate", DllCallbackGetPtr($__Discord_ActivityManager_ahCallbacks[3]))
EndFunc

; Handler for: void ActivityJoinHandler(IntPtr ptr, string secret)
Func __Discord_ActivityManager_OnActivityJoinHandler($pPtr, $sSecret)
    #forceref $pPtr
    If $__Discord_ActivityManager_afnCallbackHandlers[0] <> 0 Then
        $__Discord_ActivityManager_afnCallbackHandlers[0]($sSecret)
    EndIf
EndFunc

; Handler for: void ActivitySpectateHandler(IntPtr ptr, string secret)
Func __DISCORD_ACTIVITYMANAGER_OnActivitySpectateHandler($pPtr, $sSecret)
    #forceref $pPtr
    If $__Discord_ActivityManager_afnCallbackHandlers[1] <> 0 Then
        $__Discord_ActivityManager_afnCallbackHandlers[1]($sSecret)
    EndIf
EndFunc

; Handler for: void ActivityJoinRequestHandler(IntPtr ptr, ref User user)
Func __DISCORD_ACTIVITYMANAGER_OnActivityJoinRequestHandler($pPtr, $pUser)
    #forceref $pPtr
    If $__Discord_ActivityManager_afnCallbackHandlers[2] <> 0 Then
        Local $tUser = DllStructCreate($__DISCORD_tagUSER, $pUser)
        Local $aUser = [DllStructGetData($tUser, "Id"), _
                        DllStructGetData($tUser, "Username"), _
                        DllStructGetData($tUser, "Discriminator"), _
                        DllStructGetData($tUser, "Avatar"), _
                        DllStructGetData($tUser, "Bot")]
        $__Discord_ActivityManager_afnCallbackHandlers[2]($aUser)
    EndIf
EndFunc

; Handler for: void ActivityInviteHandler(IntPtr ptr, ActivityActionType type, ref User user, ref Activity activity)
Func __DISCORD_ACTIVITYMANAGER_OnActivityInviteHandler($pPtr, $iType, $pUser, $pActivity)
    #forceref $pPtr
    If $__Discord_ActivityManager_afnCallbackHandlers[3] <> 0 Then
        Local $tUser = DllStructCreate($__DISCORD_tagUSER, $pUser)
        Local $aUser = [DllStructGetData($tUser, "Id"), _
                        DllStructGetData($tUser, "Username"), _
                        DllStructGetData($tUser, "Discriminator"), _
                        DllStructGetData($tUser, "Avatar"), _
                        DllStructGetData($tUser, "Bot")]
        Local $tActivity = DllStructCreate($__DISCORD_tagACTIVITY, $pActivity)
        Local $aActivity = [DllStructGetData($tActivity, "Type"), _
                            DllStructGetData($tActivity, "ApplicationId"), _
                            DllStructGetData($tActivity, "Name"), _
                            DllStructGetData($tActivity, "State"), _
                            DllStructGetData($tActivity, "Details"), _
                            DllStructGetData($tActivity, "Timestamps_Start"), _
                            DllStructGetData($tActivity, "Timerstamps_End"), _
                            DllStructGetData($tActivity, "Assets_LargeImage"), _
                            DllStructGetData($tActivity, "Assets_LargeText"), _
                            DllStructGetData($tActivity, "Assets_SmallImage"), _
                            DllStructGetData($tActivity, "Assets_SmallText"), _
                            DllStructGetData($tActivity, "Party_Id"), _
                            DllStructGetData($tActivity, "Party_Size_CurrentSize"), _
                            DllStructGetData($tActivity, "Party_Size_MaxSize"), _
                            DllStructGetData($tActivity, "Secrets_Match"), _
                            DllStructGetData($tActivity, "Secrets_Join"), _
                            DllStructGetData($tActivity, "Secrets_Spectate"), _
                            DllStructGetData($tActivity, "Instance")]
        $__Discord_ActivityManager_afnCallbackHandlers[3]($iType, $aUser, $aActivity)
    EndIf
EndFunc

; Handler for: void UpdateActivityCallback(IntPtr ptr, Result result)
Func __Discord_ActivityManager_UpdateActivityCallbackHandler($pPtr, $iResult)
    #forceref $pPtr
    If $__Discord_ActivityManager_fnUpdateActivityCallbackHandler <> 0 Then
        $__Discord_ActivityManager_fnUpdateActivityCallbackHandler($iResult)
    EndIf
EndFunc

; Handler for: void ClearActivityCallback(IntPtr ptr, Result result)
Func __Discord_ActivityManager_ClearActivityCallbackHandler($pPtr, $iResult)
    #forceref $pPtr
    If $__Discord_ActivityManager_fnClearActivityCallbackHandler <> 0 Then
        $__Discord_ActivityManager_fnClearActivityCallbackHandler($iResult)
    EndIf
EndFunc

; Handler for: void SendRequestReplyCallback(IntPtr ptr, Result result)
Func __Discord_ActivityManager_SendRequestReplyCallbackHandler($pPtr, $iResult)
    #forceref $pPtr
    If $__Discord_ActivityManager_fnSendRequestReplyCallbackHandler <> 0 Then
        $__Discord_ActivityManager_fnSendRequestReplyCallbackHandler($iResult)
    EndIf
EndFunc

; Handler for: void SendInviteCallback(IntPtr ptr, Result result)
Func __Discord_ActivityManager_SendInviteCallbackHandler($pPtr, $iResult)
    #forceref $pPtr
    If $__Discord_ActivityManager_fnSendInviteCallbackHandler <> 0 Then
        $__Discord_ActivityManager_fnSendInviteCallbackHandler($iResult)
    EndIf
EndFunc

; Handler for: void AcceptInviteCallback(IntPtr ptr, Result result)
Func __Discord_ActivityManager_AcceptInviteCallbackHandler($pPtr, $iResult)
    #forceref $pPtr
    If $__Discord_ActivityManager_fnAcceptInviteCallbackHandler <> 0 Then
        $__Discord_ActivityManager_fnAcceptInviteCallbackHandler($iResult)
    EndIf
EndFunc

Func __Discord_ActivityManager_Dispose()
    For $i = 0 To UBound($__Discord_ActivityManager_ahCallbacks) - 1
        If $__Discord_ActivityManager_ahCallbacks[$i] Then
            DllCallbackFree($__Discord_ActivityManager_ahCallbacks[$i])
            $__Discord_ActivityManager_ahCallbacks[$i] = 0
        EndIf
    Next
    If $__Discord_ActivityManager_hUpdateActivityCallback Then
        DllCallbackFree($__Discord_ActivityManager_hUpdateActivityCallback)
        $__Discord_ActivityManager_hUpdateActivityCallback = 0
    EndIf
    If $__Discord_ActivityManager_hClearActivityCallback Then
        DllCallbackFree($__Discord_ActivityManager_hClearActivityCallback)
        $__Discord_ActivityManager_hClearActivityCallback = 0
    EndIf
    If $__Discord_ActivityManager_hSendRequestReplyCallback Then
        DllCallbackFree($__Discord_ActivityManager_hSendRequestReplyCallback)
        $__Discord_ActivityManager_hSendRequestReplyCallback = 0
    EndIf
    If $__Discord_ActivityManager_hSendInviteCallback Then
        DllCallbackFree($__Discord_ActivityManager_hSendInviteCallback)
        $__Discord_ActivityManager_hSendInviteCallback = 0
    EndIf
    If $__Discord_ActivityManager_hAcceptInviteCallback Then
        DllCallbackFree($__Discord_ActivityManager_hAcceptInviteCallback)
        $__Discord_ActivityManager_hAcceptInviteCallback = 0
    EndIf
EndFunc
#endregion Activity manager private functions

#region Application manager public functions
; #FUNCTION# ====================================================================================================================
; Name...........: _Discord_ApplicationManager_GetCurrentLocale
; Description ...: Gets the locale the current user has Discord set to
; Syntax.........: _Discord_ApplicationManager_GetCurrentLocale()
; Parameters ....: None
; Return values .: The string
; Author ........: Alan72104#4011
; Modified.......: 
; Remarks .......: 
; Related .......: 
; Link ..........: https://discord.com/developers/docs/game-sdk/applications#getcurrentlocale
; ===============================================================================================================================
Func _Discord_ApplicationManager_GetCurrentLocale()
    Local $aResult = DllCallAddress("none:cdecl", _
                                    DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_APPLICATIONMANAGER], "GetCurrentLocale"), _
                                    "ptr", $__Discord_apMethodPtrs[$__DISCORD_APPLICATIONMANAGER], _
                                    "str", "")
    Local $sStr = $aResult[2]
    Return $sStr
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Discord_ApplicationManager_GetCurrentBranch
; Description ...: Gets the name of pushed branch on which the game is running
;                  These are branches that you created and pushed using Dispatch
; Syntax.........: _Discord_ApplicationManager_GetCurrentBranch()
; Parameters ....: None
; Return values .: The string
; Author ........: Alan72104#4011
; Modified.......: 
; Remarks .......: 
; Related .......: 
; Link ..........: https://discord.com/developers/docs/game-sdk/applications#getcurrentbranch
; ===============================================================================================================================
Func _Discord_ApplicationManager_GetCurrentBranch()
    Local $aResult = DllCallAddress("none:cdecl", _
                                    DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_APPLICATIONMANAGER], "GetCurrentBranch"), _
                                    "ptr", $__Discord_apMethodPtrs[$__DISCORD_APPLICATIONMANAGER], _
                                    "str", "")
    Local $sStr = $aResult[2]
    Return $sStr
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Discord_ApplicationManager_ValidateOrExit
; Description ...: Checks if the current user has the entitlement to run this game
; Syntax.........: _Discord_ApplicationManager_ValidateOrExit($fnHandler)
; Parameters ....: $fnHandler - [ValidateOrExitCallbackHandler] Callback which Discord returns the result to
;                             + void ValidateOrExitCallbackHandler(RESULT result)
; Return values .: Success            - True
;                  Invalid parameters - False
; Author ........: Alan72104#4011
; Modified.......: 
; Remarks .......: 
; Related .......: 
; Link ..........: https://discord.com/developers/docs/game-sdk/applications#validateorexit
; ===============================================================================================================================
Func _Discord_ApplicationManager_ValidateOrExit($fnHandler)
    If VarGetType($fnHandler) <> "UserFunction" Then
        Return False
    EndIf
    If $__Discord_ApplicationManager_hValidateOrExitCallback = 0 Then
        $__Discord_ApplicationManager_hValidateOrExitCallback = DllCallbackRegister("__Discord_ApplicationManager_ValidateOrExitCallbackHandler", "none", "ptr;int")
    EndIf
    $__Discord_ApplicationManager_fnValidateOrExitCallbackHandler = $fnHandler
    DllCallAddress("none:cdecl", _
                   DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_APPLICATIONMANAGER], "ValidateOrExit"), _
                   "ptr", $__Discord_apMethodPtrs[$__DISCORD_APPLICATIONMANAGER], _
                   "ptr", Null, _
                   "ptr", DllCallbackGetPtr($__Discord_ApplicationManager_hValidateOrExitCallback))
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Discord_ApplicationManager_GetOAuth2Token
; Description ...: Retrieve an oauth2 bearer token for the current user
; Syntax.........: _Discord_ApplicationManager_GetOAuth2Token($fnHandler)
; Parameters ....: $fnHandler - [GetOAuth2TokenHandler] Callback which Discord returns the result and OAuth2Token to
;                             + void GetOAuth2TokenHandler(RESULT result, OAuth2Token token)
; Return values .: Success            - True
;                  Invalid parameters - False
; Author ........: Alan72104#4011
; Modified.......: 
; Remarks .......: If your game was launched from Discord and you call this function, you will automatically receive the token
;                  If the game was not launched from Discord and this method is called,
;                  Discord will focus itself and prompt the user for authorization
; Related .......: $DISCORD_RESULT...
;                  OAuth2Token array [String AccessToken, String Scopes, Int64 Expires]
; Link ..........: https://discord.com/developers/docs/game-sdk/applications#validateorexit
; ===============================================================================================================================
Func _Discord_ApplicationManager_GetOAuth2Token($fnHandler)
    If VarGetType($fnHandler) <> "UserFunction" Then
        Return False
    EndIf
    If $__Discord_ApplicationManager_hGetOAuth2TokenCallback = 0 Then
        $__Discord_ApplicationManager_hGetOAuth2TokenCallback = DllCallbackRegister("__Discord_ApplicationManager_GetOAuth2TokenHandler", "none", "ptr;int;ptr")
    EndIf
    $__Discord_ApplicationManager_fnGetOAuth2TokenCallbackHandler = $fnHandler
    DllCallAddress("none:cdecl", _
                   DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_APPLICATIONMANAGER], "GetOAuth2Token"), _
                   "ptr", $__Discord_apMethodPtrs[$__DISCORD_APPLICATIONMANAGER], _
                   "ptr", Null, _
                   "ptr", DllCallbackGetPtr($__Discord_ApplicationManager_hGetOAuth2TokenCallback))
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Discord_ApplicationManager_GetTicket
; Description ...: Gets the signed app ticket for the current user
; Syntax.........: _Discord_ApplicationManager_GetTicket($fnHandler)
; Parameters ....: $fnHandler - [GetTicketCallbackHandler] Callback which Discord returns the result and ticket string to
;                             + void GetTicketCallbackHandler(RESULT result, String data)
; Return values .: Success            - True
;                  Invalid parameters - False
; Author ........: Alan72104#4011
; Modified.......: 
; Remarks .......: Please see the official documentation https://discord.com/developers/docs/game-sdk/applications#getticket
; Related .......: $DISCORD_RESULT...
; Link ..........: https://discord.com/developers/docs/game-sdk/applications#getticket
; ===============================================================================================================================
Func _Discord_ApplicationManager_GetTicket($fnHandler)
    If VarGetType($fnHandler) <> "UserFunction" Then
        Return False
    EndIf
    If $__Discord_ApplicationManager_hGetTicketCallback = 0 Then
        $__Discord_ApplicationManager_hGetTicketCallback = DllCallbackRegister("__Discord_ApplicationManager_GetTicketCallbackHandler", "none", "ptr;int;ptr")
    EndIf
    $__Discord_ApplicationManager_fnGetTicketCallbackHandler = $fnHandler
    DllCallAddress("none:cdecl", _
                   DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_APPLICATIONMANAGER], "GetTicket"), _
                   "ptr", $__Discord_apMethodPtrs[$__DISCORD_APPLICATIONMANAGER], _
                   "ptr", Null, _
                   "ptr", DllCallbackGetPtr($__Discord_ApplicationManager_hGetTicketCallback))
    Return True
EndFunc
#endregion Application manager public functions

#region Application manager private functions
; Handler for: void GetTicketCallback(IntPtr ptr, Result result, [MarshalAs(UnmanagedType.LPStr)]ref string data);
Func __Discord_ApplicationManager_GetTicketCallbackHandler($pPtr, $iResult, $sData)
    #forceref $pPtr
    If $__Discord_ApplicationManager_fnGetTicketCallbackHandler <> 0 Then
        $__Discord_ApplicationManager_fnGetTicketCallbackHandler($iResult, $sData)
    EndIf
EndFunc

; Handler for: void ValidateOrExitCallback(IntPtr ptr, Result result)
Func __Discord_ApplicationManager_ValidateOrExitCallbackHandler($pPtr, $iResult)
    #forceref $pPtr
    If $__Discord_ApplicationManager_fnValidateOrExitCallbackHandler <> 0 Then
        $__Discord_ApplicationManager_fnValidateOrExitCallbackHandler($iResult)
    EndIf
EndFunc

; Handler for: void GetOAuth2TokenCallback(IntPtr ptr, Result result, {string accessToken, string scopes, Int64 expires})
Func __Discord_ApplicationManager_GetOAuth2TokenHandler($pPtr, $iResult, $pOAuth2Token)
    #forceref $pPtr
    If $__Discord_ApplicationManager_fnGetOAuth2TokenCallbackHandler <> 0 Then
        Local $tOAuth2Token = DllStructCreate($__DISCORD_tagOAUTH2TOKEN, $pOAuth2Token)
        Local $aOAuth2Token = [DllStructGetData($tOAuth2Token, "AccessToken"), _
                               DllStructGetData($tOAuth2Token, "Scopes"), _
                               DllStructGetData($tOAuth2Token, "Expires")]
        $__Discord_ApplicationManager_fnGetOAuth2TokenCallbackHandler($iResult, $aOAuth2Token)
    EndIf
EndFunc

Func __Discord_ApplicationManager_Init()
    $__Discord_apMethodPtrs[$__DISCORD_APPLICATIONMANAGER] = DllCallAddress("ptr:cdecl", _
                                                                            DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_CORE], "GetApplicationManager"), _
                                                                            "ptr", $__Discord_apMethodPtrs[$__DISCORD_CORE])[0]
    $__Discord_atMethodInterfaces[$__DISCORD_APPLICATIONMANAGER] = DllStructCreate($__DISCORD_tagAPPLICATIONMANAGERMETHODS, $__Discord_apMethodPtrs[$__DISCORD_APPLICATIONMANAGER])
    __Discord_ApplicationManager_InitEvents()
EndFunc

Func __Discord_ApplicationManager_InitEvents()
EndFunc

Func __Discord_ApplicationManager_Dispose()
    If $__Discord_ApplicationManager_hValidateOrExitCallback Then
        DllCallbackFree($__Discord_ApplicationManager_hValidateOrExitCallback)
        $__Discord_ApplicationManager_hValidateOrExitCallback = 0
    EndIf
    If $__Discord_ApplicationManager_hGetOAuth2TokenCallback Then
        DllCallbackFree($__Discord_ApplicationManager_hGetOAuth2TokenCallback)
        $__Discord_ApplicationManager_hGetOAuth2TokenCallback = 0
    EndIf
    If $__Discord_ApplicationManager_hGetTicketCallback Then
        DllCallbackFree($__Discord_ApplicationManager_hGetTicketCallback)
        $__Discord_ApplicationManager_hGetTicketCallback = 0
    EndIf
EndFunc
#endregion Application manager private functions

#region Image manager private functions
Func __Discord_ImageManager_Init()
    $__Discord_apMethodPtrs[$__DISCORD_IMAGEMANAGER] = DllCallAddress("ptr:cdecl", _
                                                                      DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_CORE], "GetImageManager"), _
                                                                      "ptr", $__Discord_apMethodPtrs[$__DISCORD_CORE])[0]
    $__Discord_atMethodInterfaces[$__DISCORD_IMAGEMANAGER] = DllStructCreate($__DISCORD_tagIMAGEMANAGERMETHODS, $__Discord_apMethodPtrs[$__DISCORD_IMAGEMANAGER])
    __Discord_ImageManager_InitEvents()
EndFunc

Func __Discord_ImageManager_InitEvents()
EndFunc

Func __Discord_ImageManager_Dispose()
EndFunc
#endregion Image manager private functions

#region Lobby manager private functions
Func __Discord_LobbyManager_Init()
    $__Discord_apMethodPtrs[$__DISCORD_LOBBYMANAGER] = DllCallAddress("ptr:cdecl", _
                                                                      DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_CORE], "GetLobbyManager"), _
                                                                      "ptr", $__Discord_apMethodPtrs[$__DISCORD_CORE])[0]
    $__Discord_atMethodInterfaces[$__DISCORD_LOBBYMANAGER] = DllStructCreate($__DISCORD_tagLOBBYMANAGERMETHODS, $__Discord_apMethodPtrs[$__DISCORD_LOBBYMANAGER])
    __Discord_LobbyManager_InitEvents()
EndFunc

Func __Discord_LobbyManager_InitEvents()
EndFunc

Func __Discord_LobbyManager_Dispose()
EndFunc
#endregion Lobby manager private functions

#region Network manager private functions
Func __Discord_NetworkManager_Init()
    $__Discord_apMethodPtrs[$__DISCORD_NETWORKMANAGER] = DllCallAddress("ptr:cdecl", _
                                                                        DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_CORE], "GetNetworkManager"), _
                                                                        "ptr", $__Discord_apMethodPtrs[$__DISCORD_CORE])[0]
    $__Discord_atMethodInterfaces[$__DISCORD_NETWORKMANAGER] = DllStructCreate($__DISCORD_tagNETWORKMANAGERMETHODS, $__Discord_apMethodPtrs[$__DISCORD_NETWORKMANAGER])
    __Discord_NetworkManager_InitEvents()
EndFunc

Func __Discord_NetworkManager_InitEvents()
EndFunc

Func __Discord_NetworkManager_Dispose()
EndFunc
#endregion Network manager private functions

#region Overlay manager private functions
Func __Discord_OverlayManager_Init()
    $__Discord_apMethodPtrs[$__DISCORD_OVERLAYMANAGER] = DllCallAddress("ptr:cdecl", _
                                                                        DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_CORE], "GetOverlayManager"), _
                                                                        "ptr", $__Discord_apMethodPtrs[$__DISCORD_CORE])[0]
    $__Discord_atMethodInterfaces[$__DISCORD_OVERLAYMANAGER] = DllStructCreate($__DISCORD_tagOVERLAYMANAGERMETHODS, $__Discord_apMethodPtrs[$__DISCORD_OVERLAYMANAGER])
    __Discord_OverlayManager_InitEvents()
EndFunc

Func __Discord_OverlayManager_InitEvents()
EndFunc

Func __Discord_OverlayManager_Dispose()
EndFunc
#endregion Overlay manager private functions

#region Relationship manager private functions
Func __Discord_RelationshipManager_Init()
    $__Discord_apMethodPtrs[$__DISCORD_RELATIONSHIPMANAGER] = DllCallAddress("ptr:cdecl", _
                                                                             DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_CORE], "GetRelationshipManager"), _
                                                                             "ptr", $__Discord_apMethodPtrs[$__DISCORD_CORE])[0]
    $__Discord_atMethodInterfaces[$__DISCORD_RELATIONSHIPMANAGER] = DllStructCreate($__DISCORD_tagRELATIONSHIPMANAGERMETHODS, $__Discord_apMethodPtrs[$__DISCORD_RELATIONSHIPMANAGER])
    __Discord_RelationshipManager_InitEvents()
EndFunc

Func __Discord_RelationshipManager_InitEvents()
EndFunc

Func __Discord_RelationshipManager_Dispose()
EndFunc
#endregion Relationship manager private functions

#region Storage manager private functions
Func __Discord_StorageManager_Init()
    $__Discord_apMethodPtrs[$__DISCORD_STORAGEMANAGER] = DllCallAddress("ptr:cdecl", _
                                                                        DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_CORE], "GetStorageManager"), _
                                                                        "ptr", $__Discord_apMethodPtrs[$__DISCORD_CORE])[0]
    $__Discord_atMethodInterfaces[$__DISCORD_STORAGEMANAGER] = DllStructCreate($__DISCORD_tagSTORAGEMANAGERMETHODS, $__Discord_apMethodPtrs[$__DISCORD_STORAGEMANAGER])
    __Discord_StorageManager_InitEvents()
EndFunc

Func __Discord_StorageManager_InitEvents()
EndFunc

Func __Discord_StorageManager_Dispose()
EndFunc
#endregion Storage manager private functions

#region Store manager private functions
Func __Discord_StoreManager_Init()
    $__Discord_apMethodPtrs[$__DISCORD_STOREMANAGER] = DllCallAddress("ptr:cdecl", _
                                                                      DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_CORE], "GetStoreManager"), _
                                                                      "ptr", $__Discord_apMethodPtrs[$__DISCORD_CORE])[0]
    $__Discord_atMethodInterfaces[$__DISCORD_STOREMANAGER] = DllStructCreate($__DISCORD_tagSTOREMANAGERMETHODS, $__Discord_apMethodPtrs[$__DISCORD_STOREMANAGER])
    __Discord_StoreManager_InitEvents()
EndFunc

Func __Discord_StoreManager_InitEvents()
EndFunc

Func __Discord_StoreManager_Dispose()
EndFunc
#endregion Store manager private functions

#region Voice manager private functions
Func __Discord_VoiceManager_Init()
    $__Discord_apMethodPtrs[$__DISCORD_VOICEMANAGER] = DllCallAddress("ptr:cdecl", _
                                                                      DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_CORE], "GetVoiceManager"), _
                                                                      "ptr", $__Discord_apMethodPtrs[$__DISCORD_CORE])[0]
    $__Discord_atMethodInterfaces[$__DISCORD_VOICEMANAGER] = DllStructCreate($__DISCORD_tagVOICEMANAGERMETHODS, $__Discord_apMethodPtrs[$__DISCORD_VOICEMANAGER])
    __Discord_VoiceManager_InitEvents()
EndFunc

Func __Discord_VoiceManager_InitEvents()
EndFunc

Func __Discord_VoiceManager_Dispose()
EndFunc
#endregion Voice manager private functions

#region User manager public functions
; #FUNCTION# ====================================================================================================================
; Name...........: _Discord_UserManager_OnCurrentUserUpdate
; Description ...: Sets the event handler
; Syntax.........: _Discord_UserManager_OnCurrentUserUpdate($fnHandler)
; Parameters ....: $fnHandler - [OnCurrentUserUpdateHandler] Fires when the User struct of the currently connected user changes
;                             +                              They may have changed their avatar, username, or something else
;                             + void OnCurrentUserUpdateHandler()
; Return values .: Success            - True
;                  Invalid parameters - False
; Author ........: Alan72104#4011
; Modified.......: 
; Remarks .......: 
; Related .......: 
; Link ..........: https://discord.com/developers/docs/game-sdk/users#oncurrentuserupdate
; Example .......: ; GetCurrentUser will error until this fires once
;                  _Discord_UserManager_OnCurrentUserUpdate(OnCurrentUserUpdateHandler)
;                  Func OnCurrentUserUpdateHandler()
;                      Local currentUser = _Discord_UserManager_GetCurrentUser()
;                      ConsoleWrite("Username: " & $currentUser[0])
;                      ConsoleWrite("Id: " & $currentUser[1])
;                      ConsoleWrite("Discriminator: " & $currentUser[2])
;                      ConsoleWrite("Avatar: " & $currentUser[3])
;                      ConsoleWrite("Bot?: " & $currentUser[4])
;                  Endfunc
; ===============================================================================================================================
Func _Discord_UserManager_OnCurrentUserUpdate($fnHandler)
    If VarGetType($fnHandler) <> "UserFunction" Then
        Return False
    EndIf
    $__Discord_UserManager_afnCallbackHandlers[0] = $fnHandler
    Return True
EndFunc

; return
; User {int64 id, string username, string discriminator, string avatar, bool bot} good
; #FUNCTION# ====================================================================================================================
; Name...........: _Discord_UserManager_GetCurrentUser
; Description ...: Fetch information about the currently connected user account
; Syntax.........: _Discord_UserManager_GetCurrentUser()
; Parameters ....: None
; Return values .: Success - User array
;                  Failure - False with @error = Discord result
; Author ........: Alan72104#4011
; Modified.......: 
; Remarks .......: 
; Related .......: User array [Int64 Id, String Username, String Discriminator, String Avatar, Bool Bot]
; Link ..........: https://discord.com/developers/docs/game-sdk/users#getcurrentuser
; Example .......: ; GetCurrentUser will error until this fires once
;                  _Discord_UserManager_OnCurrentUserUpdate(OnCurrentUserUpdateHandler)
;                  Func OnCurrentUserUpdateHandler()
;                      Local currentUser = _Discord_UserManager_GetCurrentUser()
;                      ConsoleWrite("Username: " & $currentUser[0])
;                      ConsoleWrite("Id: " & $currentUser[1])
;                      ConsoleWrite("Discriminator: " & $currentUser[2])
;                      ConsoleWrite("Avatar: " & $currentUser[3])
;                      ConsoleWrite("Bot?: " & $currentUser[4])
;                  Endfunc
; ===============================================================================================================================
Func _Discord_UserManager_GetCurrentUser()
    Local $tUser = DllStructCreate($__DISCORD_tagUSER)
    Local $aResult = DllCallAddress("int:cdecl", _
                                    DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_USERMANAGER], "GetCurrentUser"), _
                                    "ptr", $__Discord_apMethodPtrs[$__DISCORD_USERMANAGER], _
                                    "ptr", DllStructGetPtr($tUser))
    If $aResult[0] <> $DISCORD_RESULT_OK Then
        Return SetError($aResult[0], 0, False)
    EndIf
    Local $aUser = [DllStructGetData($tUser, "Id"), _
                    DllStructGetData($tUser, "Username"), _
                    DllStructGetData($tUser, "Discriminator"), _
                    DllStructGetData($tUser, "Avatar"), _
                    DllStructGetData($tUser, "Bot")]
    Return $aUser
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Discord_UserManager_GetUser
; Description ...: Gets the user information for a given id
; Syntax.........: _Discord_UserManager_GetUser($iUserId, $fnHandler)
; Parameters ....: $iUserId   - [Int64] The id of the user to fetch
;                  $fnHandler - [GetUserHandler] Callback which Discord returns result and the user to
;                             + void GetUserHandler(RESULT result, User user)
; Return values .: Success            - True
;                  Invalid parameters - False
; Author ........: Alan72104#4011
; Modified.......: 
; Remarks .......: 
; Related .......: $DISCORD_RESULT...
;                  User array [Int64 Id, String Username, String Discriminator, String Avatar, Bool Bot]
; Link ..........: https://discord.com/developers/docs/game-sdk/users#oncurrentuserupdate
; ===============================================================================================================================
Func _Discord_UserManager_GetUser($iUserId, $fnHandler)
    If Not IsInt($iUserId) Then
        Return False
    EndIf
    If VarGetType($fnHandler) <> "UserFunction" Then
        Return False
    EndIf
    If $__Discord_UserManager_hGetUserCallback = 0 Then
        $__Discord_UserManager_hGetUserCallback = DllCallbackRegister("__Discord_UserManager_GetUserCallbackHandler", "none:cdecl", "ptr;int;ptr")
    EndIf
    $__Discord_UserManager_fnGetUserCallbackHandler = $fnHandler
    DllCallAddress("none:cdecl", _
                   DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_USERMANAGER], "GetUser"), _
                   "ptr", $__Discord_apMethodPtrs[$__DISCORD_USERMANAGER], _
                   "int64", $iUserId, _
                   "ptr", Null, _
                   "ptr", DllCallbackGetPtr($__Discord_UserManager_hGetUserCallback))
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Discord_UserManager_GetCurrentUserPremiumType
; Description ...: Gets the PREMIUMTYPE for the currently connected user
; Syntax.........: _Discord_UserManager_GetCurrentUserPremiumType()
; Parameters ....: None
; Return values .: Success - PREMIUMTYPE
;                  Failure - False with @error = Discord result
; Author ........: Alan72104#4011
; Modified.......: 
; Remarks .......: 
; Related .......: $DISCORD_PREMIUMTYPE..., $DISCORD_RESULT...
; Link ..........: https://discord.com/developers/docs/game-sdk/users#getcurrentuserpremiumtype
; ===============================================================================================================================
Func _Discord_UserManager_GetCurrentUserPremiumType()
    Local $aResult = DllCallAddress("int:cdecl", _
                                    DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_USERMANAGER], "GetCurrentUserPremiumType"), _
                                    "ptr", $__Discord_apMethodPtrs[$__DISCORD_USERMANAGER], _
                                    "int", 0)
    If $aResult[0] <> $DISCORD_RESULT_OK Then
        Return SetError($aResult[0], 0, False)
    EndIf
    Local $iPremiumType = $aResult[2]
    Return $iPremiumType
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Discord_UserManager_CurrentUserHasFlag
; Description ...: Sees whether or not the current user has a certain USERFLAG on their account
; Syntax.........: _Discord_UserManager_CurrentUserHasFlag()
; Parameters ....: $iFlag - [USERFLAG] The flag to check on the user's account
; Return values .: Success - Bool
;                  Failure - False with @error = Discord result
; Author ........: Alan72104#4011
; Modified.......: 
; Remarks .......: 
; Related .......: $DISCORD_USERFLAG...
; Link ..........: https://discord.com/developers/docs/game-sdk/users#currentuserhasflag
; ===============================================================================================================================
Func _Discord_UserManager_CurrentUserHasFlag($iFlag)
    Local $aResult = DllCallAddress("int:cdecl", _
                                    DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_USERMANAGER], "CurrentUserHasFlag"), _
                                    "ptr", $__Discord_apMethodPtrs[$__DISCORD_USERMANAGER], _
                                    "int", $iFlag, _
                                    "boolean", 0)
    If $aResult[0] <> $DISCORD_RESULT_OK Then
        Return SetError($aResult[0], 0, False)
    EndIf
    Local $bHasFlag = $aResult[2]
    Return $bHasFlag
EndFunc
#endregion User manager public functions

#region User manager private functions
; Handler for: void GetUserCallback(IntPtr ptr, Result result, ref User user)
Func __Discord_UserManager_GetUserCallbackHandler($pPtr, $iResult, $pUser)
    #forceref $pPtr
    If $__Discord_UserManager_fnGetUserCallbackHandler <> 0 Then
        Local $tUser = DllStructCreate($__DISCORD_tagUSER, $pUser)
        Local $aUser = [DllStructGetData($tUser, "Id"), _
                        DllStructGetData($tUser, "Username"), _
                        DllStructGetData($tUser, "Discriminator"), _
                        DllStructGetData($tUser, "Avatar"), _
                        DllStructGetData($tUser, "Bot")]
        $__Discord_UserManager_fnGetUserCallbackHandler($iResult, $aUser)
    EndIf
EndFunc

Func __Discord_UserManager_Init()
    $__Discord_apMethodPtrs[$__DISCORD_USERMANAGER] = DllCallAddress("ptr:cdecl", _
                                                                     DllStructGetData($__Discord_atMethodInterfaces[$__DISCORD_CORE], "GetUserManager"), _
                                                                     "ptr", $__Discord_apMethodPtrs[$__DISCORD_CORE])[0]
    $__Discord_atMethodInterfaces[$__DISCORD_USERMANAGER] = DllStructCreate($__DISCORD_tagUSERMANAGERMETHODS, $__Discord_apMethodPtrs[$__DISCORD_USERMANAGER])
    __Discord_UserManager_InitEvents()
EndFunc

Func __Discord_UserManager_InitEvents()
    $__Discord_UserManager_afnCallbackHandlers[0] = 0
    $__Discord_UserManager_ahCallbacks[0] = DllCallbackRegister("__Discord_UserManager_OnCurrentUserUpdateHandler", "none:cdecl", "ptr")
    DllStructSetData($__Discord_atEventInterfaces[$__DISCORD_USERMANAGER], "OnCurrentUserUpdate", DllCallbackGetPtr($__Discord_UserManager_ahCallbacks[0]))
EndFunc

; Handler for: void CurrentUserUpdateHandler(IntPtr ptr)
Func __Discord_UserManager_OnCurrentUserUpdateHandler($pPtr)
    #forceref $pPtr
    If $__Discord_UserManager_afnCallbackHandlers[0] <> 0 Then
        $__Discord_UserManager_afnCallbackHandlers[0]()
    EndIf
EndFunc

Func __Discord_UserManager_Dispose()
    For $i = 0 To UBound($__Discord_UserManager_ahCallbacks) - 1
        If $__Discord_UserManager_ahCallbacks[$i] Then
            DllCallbackFree($__Discord_UserManager_ahCallbacks[$i])
            $__Discord_UserManager_ahCallbacks[$i] = 0
        EndIf
    Next
    If $__Discord_UserManager_hGetUserCallback Then
        DllCallbackFree($__Discord_UserManager_hGetUserCallback)
        $__Discord_UserManager_hGetUserCallback = 0
    EndIf
EndFunc
#endregion User manager private functions
