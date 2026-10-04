-- NT Eyes (integrated): eye item methods
-- NOTE: previously this file re-registered its own Hook.Add("item.applyTreatment", ...) dispatcher,
-- which OVERWROTE Neurotrauma's base item-use hook (same hook name "NT.itemused") and dropped the
-- manualCall logic from Lua/Scripts/Server/items.lua. Now we only define eye methods and merge them
-- into NT.ItemMethods / NT.ItemStartsWithMethods at the end of this file; the single dispatcher
-- (UseItemMethod) lives in Lua/Scripts/Server/items.lua.

-- NOTE: it_scalpel_eye, advretractors_eyes, tweezers_eyes and needle_eyes are NOT defined here:
-- they were integrated directly into Lua/Scripts/Server/items.lua (the base dispatcher calls them).
-- Everything below writes straight into NT.ItemMethods, which is safe because this file runs after items.lua.

--table to define eye afflictions/items
NT.EyeProperty = {
	{ type = "vi_human", damage = "dm_human", item = "it_humaneye", biological = true },
	{ type = "vi_cyber", damage = "dm_cyber", item = "it_cybereye", biological = false },
	{ type = "vi_enhanced", damage = "dm_enhanced", item = "it_enhancedeye", biological = true },
	{ type = "vi_plastic", damage = "dm_plastic", item = "it_plasticeye", biological = false },
	{ type = "vi_crawler", damage = "dm_crawler", item = "it_crawlereye", biological = true },
	{ type = "vi_mudraptor", damage = "dm_mudraptor", item = "it_mudraptoreye", biological = true },
	{ type = "vi_hammerhead", damage = "dm_hammerhead", item = "it_hammerheadeye", biological = true },
	{ type = "vi_watcher", damage = "dm_watcher", item = "it_watchereye", biological = true },
	{ type = "vi_husk", damage = "dm_husk", item = "it_huskeye", biological = true },
	{ type = "vi_charybdis", damage = "dm_charybdis", item = "it_charybdiseye", biological = true },
	{ type = "vi_latcher", damage = "dm_latcher", item = "it_latchereye", biological = true },
	{ type = "vi_terror", damage = "dm_terror", item = "it_terroreye", biological = false },
	{ type = "sr_removedeyes", damage = 0, item = "" },
	{ type = "mc_deadeyes", damage = 0, item = "" },
}

NT.LensProperty = {
	{ affliction = "lt_medical", item = "it_medicallens" },
	{ affliction = "lt_electrical", item = "it_electricallens" },
	{ affliction = "lt_night", item = "it_nightlens" },
	{ affliction = "lt_thermal", item = "it_thermallens" },
}

--define helper functions
--checks if targetCharacter has eyes
function HF.HasEyes(targetCharacter)
	return not HF.HasAffliction(targetCharacter, "sr_removedeyes")
		and not HF.HasAffliction(targetCharacter, "th_amputation")
		and not HF.HasAffliction(targetCharacter, "sh_amputation")
end

--removes all eye afflictions from the targetCharacter
function HF.NukeEyeAfflictions(targetCharacter)
	for key, affliction in pairs(NT.UpdateAfflictions) do
		local afflictionName = tostring(key)
		targetCharacter.CharacterHealth.ReduceAfflictionOnAllLimbs(afflictionName, 1000)
	end
end

--gives item based on the eye affliction
function HF.GiveEyeItem(targetCharacter, usingCharacter)
	if not HF.HasEyes(targetCharacter) then
		return
	end

	for _, eye in ipairs(NT.EyeProperty) do
		if HF.HasAffliction(targetCharacter, eye.type) then
			if eye.damage ~= nil then
				local afflictionDamage = HF.GetAfflictionStrength(targetCharacter, eye.damage, 0)
				if
					HF.HasAffliction(targetCharacter, "sr_removedeye")
					or HF.HasAffliction(targetCharacter, "mc_deadeye")
					or HF.HasAffliction(targetCharacter, "mc_mismatch")
				then
					if (usingCharacter ~= nil) and (eye.item ~= "") then
						--give one item
						HF.GiveItemAtCondition(usingCharacter, eye.item, (100 - afflictionDamage * 2))
					end
				else
					if (usingCharacter ~= nil) and (eye.item ~= "") then
						--give two items
						HF.GiveItemAtCondition(usingCharacter, eye.item, (100 - afflictionDamage))
						HF.GiveItemAtCondition(usingCharacter, eye.item, (100 - afflictionDamage))
					end
				end
			end
		end
	end
end

--gives eye affliction based on item
function HF.ApplyEyeItem(targetCharacter, usingCharacter, item)
	local limb = LimbType.Head

	--eye application
	if --check if eye(s) removed, lid open
		(HF.HasAffliction(targetCharacter, "sr_removedeyes") or HF.HasAffliction(targetCharacter, "sr_removedeye"))
		and HF.HasAffliction(targetCharacter, "sr_heldlid", 99)
		and HF.HasAffliction(targetCharacter, "sr_eyeconnector", 99)
	then
		local skillrequired = 45

		--check for skill requirement
		if HF.GetSkillRequirementMet(usingCharacter, "medical", skillrequired) then
			for _, eye in ipairs(NT.EyeProperty) do
				--check if right property in the table is selected
				if (item.Prefab.Identifier == eye.item) and not (item.Prefab.Identifier == "") then
					--get eye damage affliction strength
					local strength = (100 - item.Condition) / 2

					--check how many eyes target has
					--if one eye removed:
					if HF.HasAffliction(targetCharacter, "sr_removedeye") then
						--add single eye
						--check if eye affliction matches the item
						if HF.HasAffliction(targetCharacter, eye.type) then
							HF.SetAfflictionLimb(targetCharacter, "sr_removedeye", limb, 0, usingCharacter) --remove eye affliction
							HF.SetAfflictionLimb(targetCharacter, "sr_eyeconnector", limb, 0, usingCharacter) --remove eye connector affliction
							HF.SetAfflictionLimb(targetCharacter, "mc_mismatch", limb, 0, usingCharacter) --remove mismatch affliction

							HF.SetAfflictionLimb(targetCharacter, eye.type, limb, 100, usingCharacter) --add eye indicator affliction
							HF.AddAfflictionLimb(targetCharacter, eye.damage, limb, strength, usingCharacter) --add eye damage affliction

							HF.AddAfflictionLimb(targetCharacter, "mc_visionsickness", limb, 50, usingCharacter) --add vision sickness
							item.Condition = 0 --remove item
						else --if it doesn't; add eye+mismatch
							HF.SetAfflictionLimb(targetCharacter, "sr_removedeye", limb, 0, usingCharacter) --remove eye affliction
							HF.SetAfflictionLimb(targetCharacter, "sr_eyeconnector", limb, 0, usingCharacter) --remove eye connector affliction

							HF.SetAfflictionLimb(targetCharacter, "mc_mismatch", limb, 100, usingCharacter) --add mismatch affliction
							HF.SetAfflictionLimb(targetCharacter, eye.type, limb, 100, usingCharacter) --add eye affliction
							HF.AddAfflictionLimb(targetCharacter, eye.damage, limb, strength, usingCharacter) --add eye damage affliction

							HF.AddAfflictionLimb(targetCharacter, "mc_visionsickness", limb, 50, usingCharacter) --add vision sickness
							item.Condition = 0 --remove item
						end
					else --if two eyes removed, add one eye
						if HF.HasAffliction(targetCharacter, "sr_removedeyes") then
							--add double eye
							HF.SetAfflictionLimb(targetCharacter, "sr_removedeyes", limb, 0, usingCharacter) --remove eye affliction
							HF.SetAfflictionLimb(targetCharacter, "sr_eyeconnector", limb, 0, usingCharacter) --remove eye connector affliction
							HF.SetAfflictionLimb(targetCharacter, "mc_mismatch", limb, 0, usingCharacter) --remove mismatch affliction

							HF.SetAfflictionLimb(targetCharacter, "sr_removedeye", limb, 100, usingCharacter) --add eye affliction
							HF.SetAfflictionLimb(targetCharacter, eye.type, limb, 100, usingCharacter) --add eye affliction
							HF.AddAfflictionLimb(targetCharacter, eye.damage, limb, strength, usingCharacter) --add eye damage affliction

							HF.AddAfflictionLimb(targetCharacter, "mc_visionsickness", limb, 100, usingCharacter) --add vision sickness
							item.Condition = 0 --remove item
						end
					end
				end
			end
		else
			item.Condition = item.Condition - 5 --damage eye item on fail
		end
	end
end

--gives lens item based on affliction
function HF.GiveLensItem(targetCharacter, usingCharacter)
	local limb = LimbType.Head
	for _, lens in ipairs(NT.LensProperty) do
		if HF.HasAffliction(targetCharacter, lens.affliction) then
			HF.GiveItemAtCondition(usingCharacter, lens.item, 100)
		end
		HF.SetAfflictionLimb(targetCharacter, lens.affliction, limb, 0, usingCharacter)
	end
end

--gives lens affliction based on item
function HF.ApplyLensItem(targetCharacter, usingCharacter, item)
	local limb = LimbType.Head

	--lens application
	if --check if correct eyes are present, no mismatch, lid open, eyes popped
		HF.HasEyes(targetCharacter)
		and (HF.HasAffliction(targetCharacter, "vi_cyber") or HF.HasAffliction(targetCharacter, "vi_enhanced"))
		--and (not HF.HasAffliction(targetCharacter, "mc_mismatch")) --not sure if I should keep this or not
		and (
			HF.HasAffliction(targetCharacter, "sr_heldlid", 99)
			and HF.HasAffliction(targetCharacter, "sr_poppedeye", 99)
		)
	then
		for _, lens in ipairs(NT.LensProperty) do
			--check if a lens is present, return if so
			if HF.HasAffliction(targetCharacter, lens.affliction) then
				return
			end
		end

		for _, lens in ipairs(NT.LensProperty) do
			--check if right property is selected
			if item.Prefab.Identifier == lens.item then
				HF.SetAfflictionLimb(targetCharacter, lens.affliction, limb, 100, usingCharacter)
				item.Condition = 0
			end
		end
	end
end

--Laser Surgery Tool
NT.ItemMethods.it_lasersurgerytool = function(item, usingCharacter, targetCharacter, targetLimb)
	local limb = LimbType.Head
	-- check if the item is used on the head
	if targetLimb.type ~= limb then
		return
	end
	if not HF.CanPerformSurgeryOn(targetCharacter) then
		return
	end
	if not HF.HasEyes(targetCharacter) then
		return
	end
	if HF.HasAffliction(targetCharacter, "sr_heldlid", 99) then
		local skillrequired = 80
		if HF.GetSkillRequirementMet(usingCharacter, "medical", skillrequired) then
			HF.AddAfflictionLimb(
				targetCharacter,
				"sr_lasersurgery",
				limb,
				1 + HF.GetSurgerySkill(usingCharacter) / 4,
				usingCharacter
			)
		else
			if --give eye damage on fail
				HF.HasEyes(targetCharacter)
			then
				for _, eye in ipairs(NT.EyeProperty) do
					if HF.HasAffliction(targetCharacter, eye.type) then
						HF.AddAfflictionLimb(targetCharacter, eye.damage, limb, math.random(10, 100))
					end
				end
			end
		end
		HF.GiveItem(usingCharacter, "misc_sfx_slowlaser")
	end
end

--organic lens
NT.ItemMethods.it_organiclens = function(item, usingCharacter, targetCharacter, targetLimb)
	local limb = LimbType.Head
	--check if the item is used on the head
	if targetLimb.type ~= limb then
		return
	end
	--check if surgery can be performed
	if not HF.CanPerformSurgeryOn(targetCharacter) then
		return
	end
	--check if target has eyes
	if not HF.HasEyes(targetCharacter) then
		return
	end

	--organic lens application
	if
		HF.HasAffliction(targetCharacter, "sr_corneaincision", 99)
		and HF.HasAffliction(targetCharacter, "sr_emulsification", 99)
		and HF.HasAffliction(targetCharacter, "sr_heldlid", 99)
		and not HF.HasAffliction(targetCharacter, "sr_poppedeye", 99)
	then
		HF.SetAfflictionLimb(targetCharacter, "mc_cataract", limb, 0, usingCharacter) --remove cataracts
		HF.SetAfflictionLimb(targetCharacter, "sr_emulsification", limb, 0, usingCharacter) --remove emulsification
		HF.SetAfflictionLimb(targetCharacter, "sr_corneaincision", limb, 0, usingCharacter) --remove cornea incision

		item.Condition = 0 --remove item
	end
end

--lens removal
NT.ItemMethods.screwdriver = function(item, usingCharacter, targetCharacter, targetLimb)
	local limb = LimbType.Head

	--check if the item is used on the head
	if targetLimb.type ~= limb then
		return
	end
	--check if surgery can be performed
	if not HF.CanPerformSurgeryOn(targetCharacter) then
		return
	end

	--lens removal
	if
		HF.HasAffliction(targetCharacter, "sr_poppedeye", 99) and HF.HasAffliction(targetCharacter, "sr_heldlid", 99)
	then
		local skillrequired = 40
		--check for skill requirement
		if HF.GetSkillRequirementMet(usingCharacter, "medical", skillrequired) then
			HF.GiveLensItem(targetCharacter, usingCharacter)
		else
			--cause bleeding and pain if fail
			HF.AddAfflictionLimb(targetCharacter, "severepain", limb, 100, usingCharacter)
			HF.AddAfflictionLimb(targetCharacter, "bleeding", limb, math.random(0, 5), usingCharacter)
			if --give eye damage on fail
				HF.HasEyes(targetCharacter)
			then
				if --give eye damage on fail
					HF.HasEyes(targetCharacter)
				then
					for _, eye in ipairs(NT.EyeProperty) do
						if HF.HasAffliction(targetCharacter, eye.type) then
							HF.AddAfflictionLimb(targetCharacter, eye.damage, limb, math.random(0, 7), usingCharacter)
						end
					end
				end
			end
		end
	end
end

--cyber lens removal
NT.ItemMethods.screwdriverdementonite = function(item, usingCharacter, targetCharacter, targetLimb)
	NT.ItemMethods.screwdriver(item, usingCharacter, targetCharacter, targetLimb)
end

--cyber lens removal
NT.ItemMethods.screwdriverhardened = function(item, usingCharacter, targetCharacter, targetLimb)
	NT.ItemMethods.screwdriver(item, usingCharacter, targetCharacter, targetLimb)
end

--cyber lens removal
NT.ItemMethods.repairpack = function(item, usingCharacter, targetCharacter, targetLimb)
	NT.ItemMethods.screwdriver(item, usingCharacter, targetCharacter, targetLimb)
end

--cyber eye repair
NT.ItemMethods.fpgacircuit = function(item, usingCharacter, targetCharacter, targetLimb)
	local limb = LimbType.Head

	-- check if the item is used on the head
	if targetLimb.type ~= limb then
		return
	end

	-- check if surgery can be performed
	if not HF.CanPerformSurgeryOn(targetCharacter) then
		return
	end

	-- check if target has held lid, popped eye, cyber eye
	if
		HF.HasAffliction(targetCharacter, "vi_cyber")
		and (
			HF.HasAffliction(targetCharacter, "sr_heldlid", 99)
			and HF.HasAffliction(targetCharacter, "sr_poppedeye", 99)
		)
	then
		if --if target has 1 cyber eye
			HF.HasAffliction(targetCharacter, "sr_removedeye")
			or HF.HasAffliction(targetCharacter, "mc_deadeye")
			or HF.HasAffliction(targetCharacter, "mc_mismatch")
		then
			HF.AddAffliction(targetCharacter, "dm_cyber", -(item.Condition / 2.5), usingCharacter) --reduce eye damage
			item.Condition = 0 --remove item
		else --if target has 2 cyber eyes
			HF.AddAffliction(targetCharacter, "dm_cyber", -(item.Condition / 5), usingCharacter) --reduce eye damage
			--changing these from AddAfflictionLimb to AddAffliction fixes the issue, idk why, and I am too tired to care
			item.Condition = 0 --remove item
		end
	end
end

--eye connectors
NT.ItemMethods.it_eyeconnector = function(item, usingCharacter, targetCharacter, targetLimb)
	local limb = LimbType.Head
	--check if the item is used on the head
	if targetLimb.type ~= limb then
		return
	end
	--check if surgery can be performed
	if not HF.CanPerformSurgeryOn(targetCharacter) then
		return
	end

	--application
	if --check if eye(s) removed, lid open
		(HF.HasAffliction(targetCharacter, "sr_removedeyes") or HF.HasAffliction(targetCharacter, "sr_removedeye"))
		and HF.HasAffliction(targetCharacter, "sr_heldlid")
	then
		local skillrequired = 45
		--check for skill requirement
		if HF.GetSkillRequirementMet(usingCharacter, "medical", skillrequired) then
			--apply connector
			HF.SetAfflictionLimb(
				targetCharacter,
				"sr_eyeconnector",
				limb,
				1 + HF.GetSurgerySkill(usingCharacter) / 2,
				usingCharacter
			)
			item.Condition = 0 --remove item
		else --cause pain on fail
			HF.AddAfflictionLimb(targetCharacter, "severepain", limb, 10)
		end
	end
end

--human eye
NT.ItemMethods.it_humaneye = function(item, usingCharacter, targetCharacter, targetLimb)
	local limb = LimbType.Head
	--check if the item is used on the head
	if targetLimb.type ~= limb then
		return
	end
	--check if surgery can be performed
	if not HF.CanPerformSurgeryOn(targetCharacter) then
		return
	end

	--give eye affliction
	HF.ApplyEyeItem(targetCharacter, usingCharacter, item)
end
--plastic eye
NT.ItemMethods.it_plasticeye = function(item, usingCharacter, targetCharacter, targetLimb)
	local limb = LimbType.Head
	--check if the item is used on the head
	if targetLimb.type ~= limb then
		return
	end
	--check if surgery can be performed
	if not HF.CanPerformSurgeryOn(targetCharacter) then
		return
	end

	--give eye affliction
	HF.ApplyEyeItem(targetCharacter, usingCharacter, item)
end
--enhanced eye
NT.ItemMethods.it_enhancedeye = function(item, usingCharacter, targetCharacter, targetLimb)
	local limb = LimbType.Head
	--check if the item is used on the head
	if targetLimb.type ~= limb then
		return
	end
	--check if surgery can be performed
	if not HF.CanPerformSurgeryOn(targetCharacter) then
		return
	end

	--give eye affliction
	HF.ApplyEyeItem(targetCharacter, usingCharacter, item)
end
--cyber eye
NT.ItemMethods.it_cybereye = function(item, usingCharacter, targetCharacter, targetLimb)
	local limb = LimbType.Head
	--check if the item is used on the head
	if targetLimb.type ~= limb then
		return
	end
	--check if surgery can be performed
	if not HF.CanPerformSurgeryOn(targetCharacter) then
		return
	end

	--give eye affliction
	HF.ApplyEyeItem(targetCharacter, usingCharacter, item)
end
--crawler eye
NT.ItemMethods.it_crawlereye = function(item, usingCharacter, targetCharacter, targetLimb)
	local limb = LimbType.Head
	--check if the item is used on the head
	if targetLimb.type ~= limb then
		return
	end
	--check if surgery can be performed
	if not HF.CanPerformSurgeryOn(targetCharacter) then
		return
	end

	--give eye affliction
	HF.ApplyEyeItem(targetCharacter, usingCharacter, item)
end
--mudraptor eye
NT.ItemMethods.it_mudraptoreye = function(item, usingCharacter, targetCharacter, targetLimb)
	local limb = LimbType.Head
	--check if the item is used on the head
	if targetLimb.type ~= limb then
		return
	end
	--check if surgery can be performed
	if not HF.CanPerformSurgeryOn(targetCharacter) then
		return
	end

	--give eye affliction
	HF.ApplyEyeItem(targetCharacter, usingCharacter, item)
end
--hammerhead eye
NT.ItemMethods.it_hammerheadeye = function(item, usingCharacter, targetCharacter, targetLimb)
	local limb = LimbType.Head
	--check if the item is used on the head
	if targetLimb.type ~= limb then
		return
	end
	--check if surgery can be performed
	if not HF.CanPerformSurgeryOn(targetCharacter) then
		return
	end

	--give eye affliction
	HF.ApplyEyeItem(targetCharacter, usingCharacter, item)
end
--huskified eye
NT.ItemMethods.it_huskeye = function(item, usingCharacter, targetCharacter, targetLimb)
	local limb = LimbType.Head
	--check if the item is used on the head
	if targetLimb.type ~= limb then
		return
	end
	--check if surgery can be performed
	if not HF.CanPerformSurgeryOn(targetCharacter) then
		return
	end

	--give eye affliction
	HF.ApplyEyeItem(targetCharacter, usingCharacter, item)
end
--watcher eye
NT.ItemMethods.it_watchereye = function(item, usingCharacter, targetCharacter, targetLimb)
	local limb = LimbType.Head
	--check if the item is used on the head
	if targetLimb.type ~= limb then
		return
	end
	--check if surgery can be performed
	if not HF.CanPerformSurgeryOn(targetCharacter) then
		return
	end

	--give eye affliction
	HF.ApplyEyeItem(targetCharacter, usingCharacter, item)
end
--[[charybdis eye
NT.ItemMethods.it_charybdiseye = function(item, usingCharacter, targetCharacter, targetLimb)
	local limb = LimbType.Head
	--check if the item is used on the head
	if targetLimb.type ~= limb then
		return
	end
	--check if surgery can be performed
	if not HF.CanPerformSurgeryOn(targetCharacter) then
		return
	end

	--give eye affliction
	HF.ApplyEyeItem(targetCharacter, usingCharacter, item)
end --]]
--latcher eye
NT.ItemMethods.it_latchereye = function(item, usingCharacter, targetCharacter, targetLimb)
	local limb = LimbType.Head
	--check if the item is used on the head
	if targetLimb.type ~= limb then
		return
	end
	--check if surgery can be performed
	if not HF.CanPerformSurgeryOn(targetCharacter) then
		return
	end

	--give eye affliction
	HF.ApplyEyeItem(targetCharacter, usingCharacter, item)
end
--terror eye
NT.ItemMethods.it_terroreye = function(item, usingCharacter, targetCharacter, targetLimb)
	local limb = LimbType.Head
	--check if the item is used on the head
	if targetLimb.type ~= limb then
		return
	end
	--check if surgery can be performed
	if not HF.CanPerformSurgeryOn(targetCharacter) then
		return
	end

	--give eye affliction
	HF.ApplyEyeItem(targetCharacter, usingCharacter, item)
end

--cyber/enhanced eye lenses
--medical lens
NT.ItemMethods.it_medicallens = function(item, usingCharacter, targetCharacter, targetLimb)
	local limb = LimbType.Head
	HF.ApplyLensItem(targetCharacter, usingCharacter, item)
end
--electrical lens
NT.ItemMethods.it_electricallens = function(item, usingCharacter, targetCharacter, targetLimb)
	local limb = LimbType.Head
	HF.ApplyLensItem(targetCharacter, usingCharacter, item)
end
--nightvision lens
NT.ItemMethods.it_nightlens = function(item, usingCharacter, targetCharacter, targetLimb)
	local limb = LimbType.Head
	HF.ApplyLensItem(targetCharacter, usingCharacter, item)
end
NT.ItemMethods.it_thermallens = function(item, usingCharacter, targetCharacter, targetLimb)
	local limb = LimbType.Head
	HF.ApplyLensItem(targetCharacter, usingCharacter, item)
end

--eye drop
NT.ItemMethods.it_eyedrop = function(item, usingCharacter, targetCharacter, targetLimb)
	local limb = LimbType.Head
	--check if the item is used on the head
	if targetLimb.type ~= LimbType.Head then
		return
	end
	--check if character has eyes
	if not HF.HasEyes(targetCharacter) then
		return
	end
	--give affliction if able
	if not HF.HasAffliction(targetCharacter, "vi_cyber") and not HF.HasAffliction(targetCharacter, "vi_plastic") then
		HF.AddAfflictionLimb(targetCharacter, "sr_eyedrops", limb, 100)
		item.Condition = item.Condition - 25 --remove item condition
	end
end
