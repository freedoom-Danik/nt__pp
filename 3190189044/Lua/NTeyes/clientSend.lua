--send a request to spawn a sound effect item health scanner
function NT.PlayScannerSound(target)
	if not Game.IsMultiplayer then
		HF.GiveItem(target, NT.ScannerActive and "misc_sfx_fail" or "misc_sfx_selfscan")
		return
	end

	local message = Networking.Start(NT.ScannerActive and "PlayScannerSoundFail" or "PlayScannerSound")
	message.WriteString(target.ID)
	Networking.Send(message)
end

--send a request to spawn a sound effect item beep
function NT.PlayBeepSound(target)
	if not Game.IsMultiplayer then
		HF.GiveItem(target, "misc_sfx_beep")
		return
	end
	local message = Networking.Start("PlayBeepSound")
	message.WriteString(target.ID)
	Networking.Send(message)
end

--send a request to get config values
function NT.GetConfigValue()
	local message = Networking.Start("GetConfigValue")
	Networking.Send(message)
end
