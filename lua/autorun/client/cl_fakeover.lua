
local FindMetaTable, GetConVar, Material, next, GetHUDPanel, ScrW, ScrH, CurTime, RunConsoleCommand, collectgarbage = FindMetaTable, GetConVar, Material, next, GetHUDPanel, ScrW, ScrH, CurTime, RunConsoleCommand, collectgarbage
local gui = gui
local gui_HideGameUI = gui.HideGameUI
local gui_IsGameUIVisible = gui.IsGameUIVisible
local hook = hook
local hook_Add = hook.Add
local hook_Call = hook.Call
local hook_Remove = hook.Remove
local input = input
local input_GetCursorPos = input.GetCursorPos
local input_SetCursorPos = input.SetCursorPos
local input_IsMouseDown = input.IsMouseDown
local language = language
local language_GetPhrase = language.GetPhrase
local math = math
local math_random = math.random
local math_floor = math.floor
local math_rad = math.rad
local math_cos = math.cos
local math_sin = math.sin
local net = net
local net_SendToServer = net.SendToServer
local net_Start = net.Start
local net_Receive = net.Receive
local net_ReadString = net.ReadString
local net_WriteBit = net.WriteBit
local player = player
local player_GetAll = player.GetAll
local surface = surface
local surface_CreateFont = surface.CreateFont
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRect = surface.DrawTexturedRect
local surface_GetTextSize = surface.GetTextSize
local surface_DrawTexturedRectRotated = surface.DrawTexturedRectRotated
local surface_SetFont = surface.SetFont
local surface_DrawOutlinedRect = surface.DrawOutlinedRect
local surface_DrawRect = surface.DrawRect
local surface_SetTextColor = surface.SetTextColor
local surface_SetTextPos = surface.SetTextPos
local surface_DrawText = surface.DrawText
local string = string
local string_Implode = string.Implode
local string_char = string.char
local string_format = string.format
local vgui = vgui
local vgui_Create = vgui.Create

do
	local system = system
	local system_IsWindows = system.IsWindows
	local system_IsOSX = system.IsOSX
	local system_IsLinux = system.IsLinux
	local m_strDefaultFont -- Expanded into if-statement and variable for the sake of it.
	-- Thanks to Damianu and PixelToast for their assistance with fonts! :)
	-- But, this still has to be tested on another operating systems other than Windows... So, TODO.
	if system_IsWindows() then m_strDefaultFont = 'DermaDefault' -- Windows is good to go.
	elseif system_IsOSX() then m_strDefaultFont = 'Helvetica' -- TODO: Test.
	elseif system_IsLinux() then m_strDefaultFont = 'DejaVu Sans' -- TODO: Test.
	end
	surface_CreateFont('Tahoma16px', {
		font = m_strDefaultFont,
		size = system_IsLinux() and 17 or 16, -- Lets not expand this too. I am not sure of Linux's value.
		antialias = false
	})
end

local CONVAR = FindMetaTable 'ConVar' -- It should not fail.
local ConVar_GetFloat, ConVar_SetFloat = CONVAR.GetFloat, CONVAR.SetFloat
local PLAYER = FindMetaTable 'Player' -- It should not fail.
local Player_IsMuted, Player_SetMuted = PLAYER.IsMuted, PLAYER.SetMuted

local CV_snd_musicvolume, CV_volume = GetConVar 'snd_musicvolume', GetConVar 'volume'
local color_black, color_white = color_black, color_white -- If they are globals, we cache and localize all of them.
local m_BackgroundMaterial = Material '../html/img/bg.jpg'
local m_GModLogoBraveMaterial = Material '../html/img/gmod_logo_brave.png'
--local m_vMaterial = Material 'fakeover/v.png'
local DialogAlpha = 252 -- TODO: I am not sure of this value. It looks somewhat right.
local DialogOutlineColor = Color(40, 40, 40)
local DialogBackColor = Color(110, 113, 116, DialogAlpha) --Color(179, 180, 181, DialogAlpha)
local DialogXForeColor = Color(179, 180, 181) -- x sign. Font: Marlett, Char: r.
local CloseButtonInactiveBackColor = Color(227, 227, 227)
local CloseButtonInactiveForeColor = Color(82, 82, 82)
local CloseButtonActiveBackColor = Color(240, 240, 240)
local CloseButtonActiveForeColor = Color(46, 114, 178)
local CloseButtonOutlineColor = color_black
local MessageTextColor = color_white

do
	-- Generates random junk string of specified length.
	local GenerateRandomString = function(length)
		local s = {}
		for i = 1, length do s[i] = string_char(math_random(32, 126)) end
		return string_Implode('', s)
	end

	-- Apparently ":v" is rotating from its center, so this function is unused.
	--local surface_DrawTexturedRectRotatedPoint = function(x, y, w, h, ang, x0, y0)
	--	x0, y0 = x0 or 0, y0 or 0
	--	local c, s = math_cos(math_rad(ang)), math_sin(math_rad(ang))
	--	surface_DrawTexturedRectRotated(x + ((y0 * s) - (x0 * c)), y + ((y0 * c) + (x0 * s)), w, h, ang)
	--end

	local IsPointWithinAbsRect = function(x1, y1, x2, y2, x3, y3)
		return x1 >= x2 and y1 >= y2 and x1 <= x3 and y1 <= y3
	end

	local m_bWasLeftMouseDown = false
	net_Receive('fakeover_show', function() -- The name of this network message is fixed/hardcoded, ding.
		local m_strScreenMessage = net_ReadString()
		local HookID = CurTime() .. GenerateRandomString(32) -- Lets not hardcode hook ID, so we add some sugar for those who try to stop it from working.
		-- We need some panel to keep mouse on the screen.
		local DummyPanelForMouse = vgui_Create('DFrame', GetHUDPanel()) -- We need UI panel in order to show mouse...
		DummyPanelForMouse:SetSize(0, 0)
		DummyPanelForMouse:MakePopup()
		input_SetCursorPos(ScrW() * .5, ScrH() * .5) -- Set the cursor in the center of the screen. (Won't work if the game's window is inactive.)
		local m_MutedPlayers = {}
		for _, ply in next, player_GetAll() do m_MutedPlayers[ply] = Player_IsMuted(ply) end -- Save a copy muted players. For restoration after the fake overlay is closed.
		local m_fMusicVolume = ConVar_GetFloat(CV_snd_musicvolume)
		RunConsoleCommand('snd_musicvolume', 0.0) --ConVar_SetFloat(CV_snd_musicvolume, 0.0) -- Mute music sounds. Will be restored after the fake overlay is closed.
		local m_fVolume = ConVar_GetFloat(CV_volume)
		RunConsoleCommand('volume', 0.0) --ConVar_SetFloat(CV_volume, 0.0) -- Mute game sounds. Will be restored after the fake overlay is closed.
		local RemoveFakeOverlay = function(clickedWhat) -- Run this function to remove the fake overlay.
			clickedWhat = clickedWhat or false
			if IsValid(DummyPanelForMouse) then
				--DummyPanelForMouse:SetVisible(false)
				--DummyPanelForMouse:Remove()
				DummyPanelForMouse:Close()
			end
			hook_Remove('DrawOverlay', HookID)
			for _, ply in next, player_GetAll() do Player_SetMuted(ply, m_MutedPlayers[ply] or false) end -- Restore (un)muted players.
			RunConsoleCommand('snd_musicvolume', m_fMusicVolume) --ConVar_SetFloat(CV_snd_musicvolume, m_fMusicVolume) -- Restore the music volume.
			RunConsoleCommand('volume', m_fVolume) --ConVar_SetFloat(CV_volume, m_fVolume) -- Restore the game volume.
			net_Start 'fakeover_onclose'
			net_WriteBit(clickedWhat)
			net_SendToServer()
			hook_Call('CaptainPRICE.FakeOverlay.OnClose', nil, clickedWhat) -- For 3rd party addons support.
			return collectgarbage()
		end
		hook_Add('DrawOverlay', HookID, function()
			if gui_IsGameUIVisible() then gui_HideGameUI() end -- Hide game UI, because it interferes with mouse, etc.

			-- Mute all players locally. It must be done in here to cover the case when new player joins the game :/
			for _, ply in next, player_GetAll() do Player_SetMuted(ply, true) end

			-- Paint the background.
			surface_SetDrawColor(color_white)
			surface_SetMaterial(m_BackgroundMaterial)
			surface_DrawTexturedRect(0, 0, ScrW(), ScrH())

			-- Paint the "gmod_logo_brave".
			-- ( W=201px,  H=149px )
			local cx, cy, bh, fx, fy, ih, vwh = ScrW() * .5, ScrH() * .5, 18, 201, 195, 149, 28
			surface_SetMaterial(m_GModLogoBraveMaterial)
			surface_DrawTexturedRect(cx - math_floor(fx * .5), cy - ih - bh, 201, 149)

			-- Break line ( H=18px )
			ih = ih + bh

			-- Paint the ":v".
			-- ( WH=28px )
			--ih = ih + vwh
			--surface_SetMaterial(m_vMaterial) -- :v
			--surface_DrawTexturedRectRotated(cx, cy + math_floor(vwh * .5) + 2, vwh, vwh, -(CurTime() * 36 % 360.0)) -- It takes 10 seconds to make a full circle (clockwise). I'm not sure if that modulo calc is correct..

			-- Paint the dialog. Oh gosh!
			local m_iCursorX, m_iCursorY = input_GetCursorPos()
			surface_SetFont 'Tahoma16px'
			local message = string_format('%s: %s.', language_GetPhrase 'GameUI_Disconnect', m_strScreenMessage)
			local msgTextWidth, msgTextHeight = surface_GetTextSize(message)
			local width_of_dialog, height_of_dialog = 380, 116 -- TODO: Figure the height of the 1 font's line, then multiply by that with how many \n there are in message - to support any text height.
			local left_of_dialog, top_of_dialog = cx - (width_of_dialog * .5), cy - (height_of_dialog * .5)
			local right_of_dialog, bottom_of_dialog = left_of_dialog + width_of_dialog, top_of_dialog + height_of_dialog
			surface_SetDrawColor(DialogOutlineColor)
			surface_DrawOutlinedRect(left_of_dialog, top_of_dialog, width_of_dialog, height_of_dialog)
			surface_SetDrawColor(DialogBackColor)
			surface_DrawRect(left_of_dialog + 1, top_of_dialog + 1, width_of_dialog - 2, height_of_dialog - 2)
			-- Draw the text message.
			surface_SetTextColor(MessageTextColor)
			surface_SetTextPos(left_of_dialog + 20, top_of_dialog + 34)
			surface_DrawText(message)
			-- Paint the close button.
			surface_SetDrawColor(CloseButtonOutlineColor)
			local width_of_close_button, height_of_close_button = 72, 24
			local left_of_close_button, top_of_close_button = right_of_dialog - width_of_close_button - 20, bottom_of_dialog - height_of_close_button - 20
			local right_of_close_button, bottom_of_close_button = left_of_close_button + width_of_close_button, top_of_close_button + height_of_close_button
			local m_bIsCloseButtonHovered = IsPointWithinAbsRect(m_iCursorX, m_iCursorY, left_of_close_button, top_of_close_button, right_of_close_button, bottom_of_close_button)
			surface_DrawOutlinedRect(left_of_close_button, top_of_close_button, width_of_close_button, height_of_close_button)
			surface_SetDrawColor(m_bIsCloseButtonHovered and CloseButtonActiveBackColor or CloseButtonInactiveBackColor)
			surface_DrawRect(left_of_close_button + 1, top_of_close_button + 1, width_of_close_button - 2, height_of_close_button - 2)
			surface_SetTextColor(m_bIsCloseButtonHovered and CloseButtonActiveForeColor or CloseButtonInactiveForeColor)
			surface_SetTextPos(left_of_close_button + 6, top_of_close_button + 4)
			surface_DrawText(language_GetPhrase 'GameUI_Close')
			-- Draw the "x" sign.
			surface_SetFont 'Marlett'
			local width_of_x_sign, height_of_x_sign = surface_GetTextSize 'r' -- 14×14  (9×9 in reality)
			local left_of_x_sign, top_of_x_sign = right_of_dialog - width_of_x_sign - 9, top_of_dialog + 9
			local right_of_x_sign, bottom_of_x_sign = left_of_x_sign + width_of_x_sign, top_of_x_sign + height_of_x_sign
			local m_bIsXSignHovered = IsPointWithinAbsRect(m_iCursorX, m_iCursorY, left_of_x_sign, top_of_x_sign, right_of_x_sign, bottom_of_x_sign)
			surface_SetTextColor(DialogXForeColor)
			surface_SetTextPos(left_of_x_sign, top_of_x_sign)
			surface_DrawText 'r'

			-- Listen for mouse left click (this probably should not have been in this hook, but meh). Keep this at the very bottom.
			local m_bIsLeftMouseDown = input_IsMouseDown(MOUSE_LEFT)
			if m_bIsLeftMouseDown == m_bWasLeftMouseDown then return end
			m_bWasLeftMouseDown = m_bIsLeftMouseDown
			if m_bIsLeftMouseDown and (m_bIsCloseButtonHovered or m_bIsXSignHovered) then -- We only care if MOUSE_LEFT has been pressed.
				RemoveFakeOverlay(m_bIsXSignHovered)
			end
		end)
		net_Start 'fakeover_onshown'
		net_SendToServer()
		hook_Call('CaptainPRICE.FakeOverlay.OnShown', nil, m_strScreenMessage) -- For 3rd party addons support.
	end)
end
