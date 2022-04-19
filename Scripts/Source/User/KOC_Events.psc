Scriptname KOC_Events extends Quest
{Manage when to equp player with various restraints}

Import Game
Import KoFrameworkFunctions
Import Utility


KoFrameworkEvents Property KFManagerQuest Auto Const
RealHandcuffs:ThirdPartyApi Property RH_MainQuest Auto Const
Quest Property KOC_CollarPasswordHunt Auto Const
GlobalVariable Property KOC_CurrentPasscode Auto
ReferenceAlias Property AgressorAlias Auto


int Property HandcuffChance = 50 Auto
int Property CollarChance = 30 Auto
bool Property PasswordProtect = true Auto
int Property WrongCodeAction = 4 Auto
bool Property PunishEnable = false Auto
int Property PunishChance = 20 Auto
int Property MaxPunishTriggers = 2 Auto
int Property MinPunishTriggers = 1 Auto
int Property PunishDefer = 30 Auto
int Property CurrentPunishLevel Auto
Actor Property agressor Auto


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
    ;also checking that the player is not being KO'd by an unintelligent race
    If (victim != Getplayer() && (agressor.getRace().GetName() == "HumanRace" || agressor.getRace().GetName() == "GhoulRace"))
        Debug.MessageBox("Not a Human or ghoul")
        return 
    EndIf
    
    ;50% chance to get random handcuffs as long as the player does not have any currently equipped.
    ObjectReference[] restraint = Utility.VarToVarArray(RH_MainQuest.GetEquippedRestraintsWithEffect(victim, 2)) as ObjectReference[]
    If (RandomInt() <= HandcuffChance && restraint.Length == 0)
        RH_MainQuest.CreateAndEquipRandomHandcuffs(Getplayer(),20,20,"FlagAddRemoveObjectsSilently")
    EndIf

    ;chance to get collar if none is equipped.
    restraint = Utility.VarToVarArray(RH_MainQuest.GetEquippedRestraintsWithEffect(victim, 4)) as ObjectReference[]
    If (RandomInt() <= CollarChance && restraint.Length == 0)
        ;equip collar, (Player, Chance for Pulsing Shock Module, Chance for 4 Digit code, Flag:add to player silently)
        ObjectReference collar = RH_MainQuest.CreateRandomShockCollarEquipOnActor(GetPlayer(),20,100,2)
        
        ;set code
        String code
        If(PasswordProtect)
            If (RH_MainQuest.GetAccessCodeNumberOfDigits(collar) == 3)
                code = RH_MainQuest.SetAccessCode(collar, RandomInt(0, 999))
            Else
                code = RH_MainQuest.SetAccessCode(collar, RandomInt(0, 9999))
            EndIf
            ;start up the collar hunt quest
            KOC_CurrentPasscode.SetValue(code as float)
            KOC_CollarPasswordHunt.Start()
        EndIf
        
        ;set wrong code action
        If(WrongCodeAction == 4)
            RH_MainQuest.SetUnauthorizedAccessAction(collar, RandomInt(1,3))
        Else
            RH_MainQuest.SetUnauthorizedAccessAction(collar, WrongCodeAction)
        EndIf
        
        ;KO Framework has no method to check the length of time a player is KO'd. If the punish trigger is enabled immediatly, the player might die instantly.
        Wait(PunishDefer)
        ;set Punishment mode
        If(PunishEnable)
            If(RandomInt() <= PunishChance)
                CurrentPunishLevel = RandomInt(MinPunishTriggers, MaxPunishTriggers)
                RH_MainQuest.StartTortureMode(collar, CurrentPunishLevel))
            EndIf
        EndIf
    Else
        ;If the player is KO'd while wearing collar, we pause the effect
        If(RH_MainQuest.StopTortureMode(restraint[0]))
            Wait(PunishDefer)
            ;resume at previous level
            RH_MainQuest.StartTortureMode(restraint[0], CurrentPunishLevel)
        EndIf
    EndIf

    return
EndEvent

