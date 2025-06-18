local f = CreateFrame("Frame")
f:SetScript("OnEvent", function(self, event, ...)
	self.eventsHandler[event](event, ...)
end)

local function RegisterEvent(name, handler)
	if f.eventsHandler == nil then
		f.eventsHandler = {}
	end
	f.eventsHandler[name] = handler
	f:RegisterEvent(name)
end

local function Debug(...)
	if DEBUG then
		print("|cff00ff80WarbandBankLock|r:", ...)
	end
end

local function HasWarbandBankAccess()
	return #C_Bank.FetchPurchasedBankTabIDs(Enum.BankType.Account) > 0
end

local function AddXToButton(button, padding, thickness)
	if button.xLines then
		Debug("Already added X to the button:", button:GetName())
		for _, line in ipairs(button.xLines) do
			line:Show()
		end
		return
	end

	local l1 = button:CreateLine()
	l1:SetThickness(thickness)
	l1:SetColorTexture(1, 0, 0)
	l1:SetStartPoint("TOPLEFT", padding, -padding)
	l1:SetEndPoint("BOTTOMRIGHT", -padding, padding)

	local l2 = button:CreateLine()
	l2:SetThickness(thickness)
	l2:SetColorTexture(1, 0, 0)
	l2:SetStartPoint("TOPRIGHT", -padding, -padding)
	l2:SetEndPoint("BOTTOMLEFT", padding, padding)

	button.xLines = { l1, l2 }
end

local function RemoveXFromButton(button)
	if button.xLines == nil then
		return
	end

	for _, line in ipairs(button.xLines) do
		line:Hide()
	end
end

local function FindSpellButtons(spellID)
	local bars = {
		"ActionButton",
		"MultiBarBottomLeftButton",
		"MultiBarBottomRightButton",
		"MultiBarLeftButton",
		"MultiBarRightButton",
		"MultiBar5Button",
		"MultiBar6Button",
		"MultiBar7Button",
	}

	local buttons = {}
	for _, bar in ipairs(bars) do
		for i = 1, NUM_ACTIONBAR_BUTTONS do
			local button = _G[bar .. i]
			if button and button.action then
				local actionType, id = GetActionInfo(button.action)

				if actionType == "spell" and id == spellID then
					Debug("Found:", button:GetName())
					table.insert(buttons, button)
				end
			end
		end
	end

	return buttons
end

local WARBAND_BANK_SPELL_ID = 460905

RegisterEvent("PLAYER_ENTERING_WORLD", function(event, isInitialLogin, isReloadingUi)
	if isInitialLogin == false and isReloadingUi == false then
		return
	end

	local hasAccess = HasWarbandBankAccess()
	Debug("Access:", hasAccess)

	if hasAccess and DEBUG == nil then
		return
	end

	for _, button in ipairs(FindSpellButtons(WARBAND_BANK_SPELL_ID)) do
		C_Timer.NewTicker(1, function(timer)
			if InCombatLockdown() then
				return
			end
			button:SetAttribute("type", nil)
			timer:Cancel()
		end)

		AddXToButton(button, 4, 2)
	end

	hooksecurefunc(SpellFlyout, "Show", function()
		for i = 1, 19 do
			local button = _G["SpellFlyoutButton" .. i]

			if button == nil or not button:IsShown() then
				break
			end

			RemoveXFromButton(button)
			if button.spellID == WARBAND_BANK_SPELL_ID then
				AddXToButton(button, 4, 2)
			end
		end
	end)
end)
