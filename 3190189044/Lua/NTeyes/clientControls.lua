--key to activate lenses (make this configurable)
NT.LensActivationKey = Keys.F

--Medical Scanner key (make this configurable)
NT.MedicalScannerKey = Keys.F

--this enables recognition of selected limb in health UI
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.CharacterHealth"], "selectedLimbIndex")

--I dont recall what this does, probably enable keyboard input
Hook.HookMethod("Barotrauma.Character", "ControlLocalPlayer", function(instance, ptable)
	NT.MedicalLensScanner()
	NT.HudToggle()
end, Hook.HookMethodType.After)

--function to enable/disable HUD
function NT.HudToggle()
	for _, hud in pairs(NT.HUDValues) do
		if HF.HasAffliction(Character.Controlled, hud.affliction) and not CharacterHealth.OpenHealthWindow then
			if PlayerInput.KeyHit(NT.LensActivationKey) then
				if NT.HUDEnabled then
					--print("NTEyes: Disabling Client HUD")
					NT.HUDEnabled = false
					NT.PlayBeepSound(Character.Controlled)
				else
					--print("NTEyes: Enabling Client HUD")
					NT.HUDEnabled = true
					NT.PlayBeepSound(Character.Controlled)
				end
			end
		end
	end
end

--or GUI.InputBlockingMenuOpen
--or GUI.PauseMenuOpen
--or GUI.SettingsMenuOpen

--health UI scanner function for medical lens
function NT.MedicalLensScanner()
	--check if the player has a medical lens
	if not HF.HasAffliction(Character.Controlled, "lt_medical") then
		return
	end
	if not CharacterHealth.OpenHealthWindow or NT.ScannerActive then
		return
	end

	if PlayerInput.KeyHit(NT.MedicalScannerKey) then
		local scannerUser = Character.Controlled
		local scannerTarget = Character.Controlled.SelectedCharacter or scannerUser
		local limbIndex = CharacterHealth.OpenHealthWindow.selectedLimbIndex

		-- Prevent scanning own head
		if limbIndex == 0 and scannerUser == scannerTarget then
			HF.DMClient(
				HF.CharacterToClient(scannerUser),
				"‖color:255,100,100‖You can't see your own head.‖color:end‖"
			)
			NT.ScannerActive = true
			NT.PlayScannerSound(scannerUser)
			Timer.Wait(function()
				NT.ScannerActive = false
			end, 500)
			return
		end

		-- Map limb index to LimbType
		local limbTypes = {
			[0] = LimbType.Head,
			[1] = LimbType.Torso,
			[2] = LimbType.LeftArm,
			[3] = LimbType.RightArm,
			[4] = LimbType.LeftLeg,
			[5] = LimbType.RightLeg,
		}
		local limb = limbTypes[limbIndex]
		if not limb then
			return
		end

		-- Perform scan
		NT.HealthScanner(scannerUser, scannerTarget, limb)
		NT.ScannerActive = true
	end
end
