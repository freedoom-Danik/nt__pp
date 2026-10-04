--variables to set HUD values
NT.HUDEnabled = false
NT.DrawnHUD = nil
NT.DisableHoverTextHUD = false

-- there will be a table this time instead of individual variables
NT.HUDValues = {
	thermal = {
		active = false,
		item = nil,
		itemPrefab = "misc_thermalhud",
		affliction = "lt_thermal",
	},
	medical = {
		active = false,
		item = nil,
		itemPrefab = "misc_medicalhud",
		affliction = "lt_medical",
	},
	electrical = {
		active = false,
		item = nil,
		itemPrefab = "misc_electricalhud",
		affliction = "lt_electrical",
	},
}

function NT.WriteHUD()
	local hudFound = false
	--check if the player has enabled the HUD
	if not NT.HUDEnabled then
		NT.DisableHUDs()
		return
	end
	--check if the player has any of the lens afflictions
	for _, hud in pairs(NT.HUDValues) do
		if HF.HasAffliction(Character.Controlled, hud.affliction) then
			hudFound = true
			if NT.DrawnHUD == nil then
				if hud.item == nil or hud.item.Removed then
					NT.ResetHUDValues()
					NT.GetHUDItemValues()
					NT.SendItemSpawnRequest()
					return
				end
				hud.active = true
				hud.item.Equip(Character.Controlled)
				NT.DrawnHUD = hud.item.GetComponentString("StatusHUD") --get hud component
				NT.HUDEnabled = true

				--check to disable hover text if medical hud
				if hud.affliction == "lt_medical" then
					NT.DisableHoverTextHUD = true
				end

				hudFound = true
			end
		end
	end
	if not hudFound then
		NT.DisableHUDs() --if you implement multiple huds at the same time this will cause issues
	end
end

--get the item values for the HUDs
function NT.GetHUDItemValues()
	for item in Item.ItemList do
		for _, hud in pairs(NT.HUDValues) do
			if item.Prefab.Identifier == hud.itemPrefab then
				hud.item = item
			end
		end
	end
end

function NT.DisableHUDs()
	for _, hud in pairs(NT.HUDValues) do
		if hud.active then
			if hud.item then
				hud.item.Unequip(Character.Controlled)
			end
			hud.active = false
			if hud.affliction == "lt_medical" then
				NT.DisableHoverTextHUD = false
			end
			NT.DrawnHUD = nil
			--NT.HUDEnabled = false
		end
	end
end

--sends a request for HUD items to spawn in case lua fucks up
function NT.SendItemSpawnRequest()
	if not Game.IsMultiplayer then
		NT.SpawnHUDItems()
		return
	end --singleplayer comp

	local message = Networking.Start("NT.ItemSpawnRequest")

	message.WriteString("")

	Networking.Send(message)
end

--resets HUD values to prevent bugs
function NT.ResetHUDValues()
	for _, hud in pairs(NT.HUDValues) do
		hud.active = false
		hud.item = nil
		NT.DrawnHUD = nil
		NT.HUDEnabled = false
		NT.DisableHoverTextHUD = false
	end
end

--resets hud parameters for client when character changes (for MCM and singleplayer)
Hook.Patch("Barotrauma.Character", "set_Controlled", function(instance, ptable)
	--disables all HUDs
	for _, hud in pairs(NT.HUDValues) do
		hud.active = false
	end
	--sets the global variable to false
	NT.HUDEnabled = false
	NT.DrawnHUD = nil

	NT.DisableHoverTextHUD = false
end)

--deletes duplicate player text from medical hud
Hook.Patch("Barotrauma.CharacterHUD", "DrawCharacterHoverTexts", function(instance, ptable)
	ptable.PreventExecution = NT.DisableHoverTextHUD
	return nil
end, Hook.HookMethodType.Before)

--draws the written eye huds
Hook.Patch("Barotrauma.CharacterHUD", "Draw", function(instance, ptable)
	if NT.DrawnHUD == nil then
		return
	end

	NT.DrawnHUD.DrawHUD(ptable["spriteBatch"], Character.Controlled) --draws the huds
end)
