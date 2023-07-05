Scriptname KOC_PasswordNoteScript extends ObjectReference

Quest Property KOC_CollarPasswordHunt Auto Const

Event OnContainerChanged(ObjectReference newContainer, ObjectReference oldContainer)
	if (newContainer == Game.GetPlayer())
            KOC_CollarPasswordHunt.SetObjectiveCompleted(10)
		KOC_CollarPasswordHunt.SetStage(20)
	endif
EndEvent