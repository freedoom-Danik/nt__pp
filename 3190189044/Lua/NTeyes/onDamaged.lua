-- ===== NT Eyes (integrated) =====
function NT.DamageEye(targetCharacter, damage, damageType)
	--fill this functinon
	if damage == nil then
		return
	end
	local limb = LimbType.Head
	if HF.HasEyes(targetCharacter) then
		for _, eye in ipairs(NT.EyeProperty) do
			if HF.HasAffliction(targetCharacter, eye.type) then
				--apply damage to the eye
				HF.AddAfflictionLimb(targetCharacter, eye.damage, limb, damage)
			end
		end
	end
end

--lifted from NT ondamaged.lua, gets a damage reduction value based on armor worn
local function getCalculatedDamageReduction(armor, strength)
	if armor == nil then
		return 0
	end
	local reduction = 0

	if armor.HasTag("deepdiving") or armor.HasTag("deepdivinglarge") then
		local modifiers = armor.GetComponentString("Wearable").DamageModifiers
		for modifier in modifiers do
			if string.find(modifier.AfflictionIdentifiers, "concussion") ~= nil then
				reduction = strength - strength * modifier.DamageMultiplier
			end
		end
	elseif armor.HasTag("smallitem") then
		local modifiers = armor.GetComponentString("Wearable").DamageModifiers
		for modifier in modifiers do
			if string.find(modifier.AfflictionIdentifiers, "concussion") ~= nil then
				reduction = strength - strength * modifier.DamageMultiplier
			end
		end
	end
	return reduction
end


-- NOTE: the old duplicated Hook.Add("character.applyDamage", "NT.ondamaged") dispatcher was removed here.
-- It overwrote the base hook in Lua/Scripts/Server/ondamaged.lua (same hook name) and re-executed
-- ALL OnDamagedMethods on every hit (double afflictions). The eye methods below are plain table entries
-- now picked up by the single base dispatcher.

-- eye damage from combat hits (methods appended to base NT.OnDamagedMethods, see Server/ondamaged.lua)
NT.OnDamagedMethods.gunshotwound = function(character, strength, limbtype)
	--normalize limb value
	limbtype = HF.NormalizeLimbType(limbtype)

	--check if the head has been hit, if not return
	if limbtype ~= LimbType.Head then
		return
	end

	--define variables to be used
	local damage
	local damageType = "gunshotwound"
	--start the damage function if strength is above 1
	if strength >= 1 then
		--eyes only get his at a chance
		local hitChance = strength / 200
		if HF.Chance(hitChance) then
			--reduce damage strength based on armor
			local armor1 = character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
			local armor2 = character.Inventory.GetItemInLimbSlot(InvSlotType.Head)
			damage = strength
				- getCalculatedDamageReduction(armor1, strength)
				- getCalculatedDamageReduction(armor2, strength)
		end
	end
	--run the actual function that does damage
	NT.DamageEye(character, damage, damageType)
end

--cause eye damage by explosion
NT.OnDamagedMethods.explosiondamage = function(character, strength, limbtype)
	--normalize limb value
	limbtype = HF.NormalizeLimbType(limbtype)

	--check if the head has been hit, if not return
	if limbtype ~= LimbType.Head then
		return
	end

	--define variables to be used
	local damage
	local damageType = "explosiondamage"

	--start the damage function if strength is above 1
	if strength >= 1 then
		--eyes only get his at a chance
		local hitChance = strength / 200
		if HF.Chance(hitChance) then
			--reduce damage strength based on armor
			local armor1 = character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
			local armor2 = character.Inventory.GetItemInLimbSlot(InvSlotType.Head)
			damage = strength
				- getCalculatedDamageReduction(armor1, strength)
				- getCalculatedDamageReduction(armor2, strength)
		end
	end
	--run the actual function that does damage
	NT.DamageEye(character, damage, damageType)
end

--cause eye damage by bitewounds
NT.OnDamagedMethods.bitewounds = function(character, strength, limbtype)
	--normalize limb value
	limbtype = HF.NormalizeLimbType(limbtype)

	--check if the head has been hit, if not return
	if limbtype ~= LimbType.Head then
		return
	end

	--define variables to be used
	local damage
	local damageType = "bitewounds"

	--start the damage function if strength is above 1
	if strength >= 1 then
		--eyes only get his at a chance
		local hitChance = strength / 200
		if HF.Chance(hitChance) then
			--reduce damage strength based on armor
			local armor1 = character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
			local armor2 = character.Inventory.GetItemInLimbSlot(InvSlotType.Head)
			damage = strength
				- getCalculatedDamageReduction(armor1, strength)
				- getCalculatedDamageReduction(armor2, strength)
		end
	end
	--run the actual function that does damage
	NT.DamageEye(character, damage, damageType)
end

--cause eye damage by laceration
NT.OnDamagedMethods.lacerations = function(character, strength, limbtype)
	--normalize limb value
	limbtype = HF.NormalizeLimbType(limbtype)

	--check if the head has been hit, if not return
	if limbtype ~= LimbType.Head then
		return
	end

	--define variables to be used
	local damage
	local damageType = "lacerations"

	--start the damage function if strength is above 1
	if strength >= 1 then
		--eyes only get his at a chance
		local hitChance = strength / 200
		if HF.Chance(hitChance) then
			--reduce damage strength based on armor
			local armor1 = character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
			local armor2 = character.Inventory.GetItemInLimbSlot(InvSlotType.Head)
			damage = strength
				- getCalculatedDamageReduction(armor1, strength)
				- getCalculatedDamageReduction(armor2, strength)
		end
	end
	--run the actual function that does damage
	NT.DamageEye(character, damage, damageType)
end
