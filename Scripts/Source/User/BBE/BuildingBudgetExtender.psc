Scriptname BBE:BuildingBudgetExtender extends Quest

workshopparentscript Property WorkshopParent Auto Const mandatory

; Event: OnInit()
; This event is triggered when the mod initializes.
Event OnInit()

	; Register for the "OnPlayerLoadGame" event when the game starts.
	RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")

	; Register for the "OnMenuOpenCloseEvent" event when the menu is opened or closed.
	RegisterForMenuOpenCloseEvent("WorkshopMenu")

	; Register for events related to the workshop system.
	RegisterForWorkshopEvents()

	; Display a debug notification to indicate the mod's version.
	Debug.Notification("[BuildingBudgetExtender] Version 4.3.1 initiated!")

EndEvent

; Event: ObjectReference.OnWorkshopObjectPlaced(ObjectReference akWorkshopRef, ObjectReference akPlacedRef)
; This event is triggered when an object is placed in a workshop.
Event ObjectReference.OnWorkshopObjectPlaced(ObjectReference akWorkshopRef, ObjectReference akPlacedRef)

	; Call the function to handle workshop budget extension.
	HandleWorkshopBudgetExtension(akWorkshopRef)

EndEvent

; Event: OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
; This event is triggered when the menu is opened or closed.
Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)

	; Check if the menu is being opened or closed.
    if(asMenuName == "WorkshopMenu")

		; Check if the menu is being opened.
		if(abOpening)

			; Get the workshop reference from the player's current location.
			WorkshopScript akWorkshopRef = WorkshopParent.GetWorkshopFromLocation(Game.GetPlayer().GetCurrentLocation())
			
			; Call the function to handle workshop budget extension.
			HandleWorkshopBudgetExtension(akWorkshopRef)

		endif
	endif
EndEvent

; Function: HandleWorkshopBudgetExtension(ObjectReference akWorkshopRef)
; This function handles the extension of the workshop budget when objects are placed.
Function HandleWorkshopBudgetExtension(ObjectReference akWorkshopRef)

	; Cast the workshop reference to a workshopscript.
	workshopscript WorkshopRef = akWorkshopRef as workshopscript

	; Get actor values related to workshop budget.
	ActorValue WorkshopMaxDraws = WorkshopParent.WorkshopMaxDraws
	ActorValue WorkshopMaxTriangles = WorkshopParent.WorkshopMaxTriangles

	; Retrieve default and current budget values.
	float DefaultMaxDraws = WorkshopRef.MaxDraws as float
	float DefaultMaxTriangles = WorkshopRef.MaxTriangles as float
	float CurrentMaxDraws = WorkshopRef.GetValue(WorkshopMaxDraws)
	float CurrentMaxTriangles = WorkshopRef.GetValue(WorkshopMaxTriangles)
	float CurrentDraws = WorkshopRef.GetValue(WorkshopParent.WorkshopCurrentDraws)
	float CurrentTriangles = WorkshopRef.GetValue(WorkshopParent.WorkshopCurrentTriangles)

	; Check if default budget values are non-positive and set them to reasonable defaults.
	; This is to prevent some custom settlement mods incompatibility.
	If (DefaultMaxDraws <= 0 as float)
		DefaultMaxDraws = 100000 as float
	EndIf
	If (DefaultMaxTriangles <= 0 as float)
		DefaultMaxTriangles = 100000 as float
	EndIf

	; Check if the current budget values are invalid, and set them back to their default values.
	If (CurrentMaxTriangles <= 0 as float)
		CurrentMaxTriangles = DefaultMaxTriangles
	EndIf
	If (CurrentMaxDraws <= 0 as float)
		CurrentMaxDraws = DefaultMaxDraws
	EndIf

	; Check if the current draws or triangles exceed the maximum.
	If (CurrentDraws >= CurrentMaxDraws || CurrentTriangles >= CurrentMaxTriangles)

		; Set the factor at which the budget increases.
		float BudgetIncreaseFactor = 1.5

		; Calculate new budget values by extending them by the specified factor.
		float NewMaxTriangles = CurrentMaxTriangles + Math.floor(DefaultMaxTriangles * BudgetIncreaseFactor) as float
		float NewMaxDraws = CurrentMaxDraws + Math.floor(DefaultMaxDraws * BudgetIncreaseFactor) as float

		; If the new values are greater than the current maximum, update the workshop's properties.
		If (NewMaxTriangles > CurrentMaxTriangles || NewMaxDraws > CurrentMaxDraws)

			; Temporarily close the workshop to update the budget properties.
			WorkshopRef.StartWorkshop(False)

			; Update the budget properties with the new values.
			WorkshopRef.SetValue(WorkshopMaxTriangles, NewMaxTriangles)
			WorkshopRef.SetValue(WorkshopMaxDraws, NewMaxDraws)

			; Re-open the workshop to apply the budget extension.
			WorkshopRef.StartWorkshop(True)

			; Display a debug notification indicating that the settlement building budget has been extended.
			Debug.Notification("[BuildingBudgetExtender] Settlement building budget extended!")

		EndIf
	EndIf

EndFunction

; Function: RegisterForWorkshopEvents()
; This function registers the script to listen for "OnWorkshopObjectPlaced" events for each workshop defined in the WorkshopParent.Workshops array.
Function RegisterForWorkshopEvents()

	workshopscript[] Workshops = WorkshopParent.Workshops
	int i = 0

	While (i < Workshops.length)

		; Register for the "OnWorkshopObjectPlaced" event for each workshop.
		RegisterForRemoteEvent(Workshops[i] as ObjectReference, "OnWorkshopObjectPlaced")
		i += 1

	EndWhile

EndFunction

; Event: Actor.OnPlayerLoadGame(Actor ActorRef)
; This event is triggered when a player loads a saved game.
Event Actor.OnPlayerLoadGame(Actor ActorRef)

	; Re-register the script for workshop events when the game is loaded.
	RegisterForWorkshopEvents()

EndEvent