Scriptname KOC_Events extends Quest
{Manage when to equp player with various restraints}

Import Game
Import KoFrameworkFunctions
Import Utility

;Script variables, Dont touch
KoFrameworkEvents Property KFManagerQuest Auto Const
RealHandcuffs:ThirdPartyApi Property RH_MainQuest Auto Const
Quest Property KOC_CollarPasswordHunt Auto Const
GlobalVariable Property KOC_CurrentPasscode Auto
ReferenceAlias Property AgressorAlias Auto
ReferenceAlias Property CurrentCollar Auto
Actor Property agressor Auto

;MCM Handcuff Settings
int Property HandcuffChance = 50 Auto
int Property HingedHandcuffs = 20 Auto
int Property HighSecurityHandcuffs = 20 Auto


int Property CollarChance = 30 Auto
bool Property PasswordProtect = true Auto
int Property WrongCodeAction = 4 Auto
bool Property PunishEnable = false Auto
int Property PunishChance = 20 Auto
int Property MaxPunishTriggers = 2 Auto
int Property MinPunishTriggers = 1 Auto
int Property PunishDefer = 30 Auto

int Property CurrentPunishLevel = 1 Auto ;Assuming not active at start of script



Event onInit()
    Debug.Notification("KOC Initatated")
    RegisterEvents()
EndEvent

Function RegisterEvents()
    RegisterForCustomEvent(KFManagerQuest, "OnKnockOutEnd")
    RegisterForCustomEvent(KFManagerQuest, "OnKnockOutStart")
EndFunction

Event KoFrameworkEvents.OnKnockOutStart(KoFrameworkEvents akSender, Var[] akArgs)
    agressor = akArgs[1] as Actor
    AgressorAlias.ForceRefTo(agressor)
EndEvent

Event KoFrameworkEvents.OnKnockOutEnd(KoFrameworkEvents akSender, Var[] akArgs)
    ;pulling out the received variables
    Actor victim = akArgs[0] as Actor

    ;checking that the player is the one being KO'd
    If (victim != Getplayer())
        return 
    EndIf

    ;The player knocked themselves out... somehow. We don't want to do anything except pause torture 
    If(agressor == GetPlayer() && victim == GetPlayer())
        DeferTorture()
        return
    EndIf

    ;If they're not humanoid, they're not gonna lock some shit onto the player
    If (agressor.getRace().GetName() != "HumanRace" && agressor.getRace().GetName() != "GhoulRace")
        DeferTorture()
        return
    EndIf
    
    ;We know the player is in a valid state, run the scripts
    EquipHandcuffs()
    EquipCollar()

    return
EndEvent

;----------------------------------------------------------------------------------------------------------------------------------------
;Handcuff Functions
;----------------------------------------------------------------------------------------------------------------------------------------

;Percent chance to get random handcuffs as long as the player does not have any currently equipped.
Function EquipHandcuffs()
    ;initial check that player does not have handcuffs equipped.
    ObjectReference[] restraint = Utility.VarToVarArray(RH_MainQuest.GetEquippedRestraintsWithEffect(GetPlayer(), 2)) as ObjectReference[]
    If (RandomInt() <= HandcuffChance && restraint.Length == 0)
        ;equip handcuffs, (Player, Chance for Hinged Handcuffs, Chance for High Security Handcuffs, Flag:add to player silently)
        RH_MainQuest.CreateAndEquipRandomHandcuffs(Getplayer(),HingedHandcuffs,20,"FlagAddRemoveObjectsSilently")
    EndIf
EndFunction

;----------------------------------------------------------------------------------------------------------------------------------------
;Collar Functions
;----------------------------------------------------------------------------------------------------------------------------------------

;Percent chance to get random collar as long as the player does not have any currently equipped.
Function EquipCollar()
    ;initial check that player does not have a collar equipped.
    ObjectReference[] restraint = Utility.VarToVarArray(RH_MainQuest.GetEquippedRestraintsWithEffect(GetPlayer(), 4)) as ObjectReference[]
    If (RandomInt() <= CollarChance && restraint.Length == 0)
        ;equip collar, (Player, Chance for Pulsing Shock Module, Chance for 4 Digit code/Torture Avalible, Flag:add to player silently)
        ObjectReference collar = RH_MainQuest.CreateRandomShockCollarEquipOnActor(GetPlayer(),20,100,2)
        
        If(PasswordProtect)
            SetCode(collar)
            SetWrongCodeAction(collar)
        EndIf
        
        If(PunishEnable)
            SetPunish(collar)
        EndIf

    Else ;Player had collar equipped or equip roll failed. 
        DeferTorture()
    EndIf
EndFunction

;Sets a random code onto the collar and store it in a global variable.
Function SetCode(ObjectReference collar)
    String code
    If (RH_MainQuest.GetAccessCodeNumberOfDigits(collar) == 3)
        code = RH_MainQuest.SetAccessCode(collar, RandomInt(0, 999))
    Else
        code = RH_MainQuest.SetAccessCode(collar, RandomInt(0, 9999))
    EndIf
    ;start up the collar hunt quest
    KOC_CurrentPasscode.SetValue(code as float)
    KOC_CollarPasswordHunt.Start()
EndFunction

;Sets the action to be triggered when the player 
Function SetWrongCodeAction(ObjectReference collar)
    If(WrongCodeAction == 4)
        RH_MainQuest.SetUnauthorizedAccessAction(collar, RandomInt(1,3))
    Else
        RH_MainQuest.SetUnauthorizedAccessAction(collar, WrongCodeAction)
    EndIf
EndFunction

;Sets the Punishment Mode, if avalible. Default is 
Function SetPunish(ObjectReference collar)
    If(RandomInt() <= PunishChance)
        CurrentPunishLevel = RandomInt(MinPunishTriggers, MaxPunishTriggers)
        StartTorture(collar)
    EndIf
EndFunction


;----------------------------------------------------------------------------------------------------------------------------------------
;KO Framework has no method to check the length of time a player is KO'd. 
;If the punish trigger is enabled immediatly, the player might die instantly.
;These functions enable and disable the mechanic to prevent the player 
;from dying from shocks while unconsious

;REALLY THOUGH, these should be in a different script altogether

Function DeferTorture()
    ObjectReference[] collar = Utility.VarToVarArray(RH_MainQuest.GetEquippedRestraintsWithEffect(GetPlayer(), 4)) as ObjectReference[]
        If(PauseTorture(collar[0]))
            StartTorture(collar[0])
        EndIf
EndFunction

Bool Function PauseTorture(ObjectReference collar)
    return RH_MainQuest.StopTortureMode(collar)
EndFunction

Function StartTorture(ObjectReference collar)
    Wait(PunishDefer)
    RH_MainQuest.StartTortureMode(collar, CurrentPunishLevel)
EndFunction