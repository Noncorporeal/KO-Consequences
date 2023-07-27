Scriptname TriggerCollar extends ReferenceAlias

Import Game

RealHandcuffs:ThirdPartyApi Property RH_MainQuest Auto Const

Int Property AgressorTriggerMin = 10 Auto
Int Property AgressorTriggerMax = 30 Auto


Event OnCombatStateChanged(Actor akTarget, int aeCombatState)
    if (akTarget == GetPlayer())
        while (aeCombatState == 1)
            Debug.Notification("Triggering Collar")
            RH_MainQuest.NpcAimAndFireRemoteTrigger(self.GetActorRef(), akTarget, numberOfTimes = 1)
            Utility.Wait(Utility.RandomInt(10,15))
        EndWhile
    EndIf
EndEvent