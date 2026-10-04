--function to spawn HUD items, sometimes roundstart fucks up
--thats why this is being called multiple times in the code
--kind of a failsafe
function NT.SpawnHUDItems()
	if not Submarine.MainSub then
		return
	end
	local SubPosition = Submarine.MainSub.WorldPosition
	local prefabs = {
		"misc_thermalhud",
		"misc_medicalhud",
		"misc_electricalhud",
	}

	--spawn the required items
	for _, prefabName in ipairs(prefabs) do
		local itemPrefab = ItemPrefab.GetItemPrefab(prefabName)
		if itemPrefab then
			Entity.Spawner.AddItemToSpawnQueue(itemPrefab, SubPosition, nil, nil, nil, function(item) end)
		else
			print("NT: Failed to find prefab: " .. prefabName)
		end
	end
end

Hook.Add("roundStart", "NT.SpawnHudItems", function()
	--Wait a moment to send spawn request
	Timer.Wait(function()
		NT.SpawnHUDItems()
	end, 1)
end)

--Receive item spawn request from client
local lastSpawnRequest = {}
Networking.Receive("NT.ItemSpawnRequest", function(message, client)
	--timer to prevent spam spawns
	local clientId = tostring(client.SteamID or client.Name or client) -- fallback if SteamID is unavailable
	local now = Timer.GetTime()
	local cooldown = 15 -- seconds

	if lastSpawnRequest[clientId] and now - lastSpawnRequest[clientId] < cooldown then
		print("NT: Spawn request rate-limited for client: " .. clientId)
		return
	end

	lastSpawnRequest[clientId] = now
	NT.SpawnHUDItems()
end)
