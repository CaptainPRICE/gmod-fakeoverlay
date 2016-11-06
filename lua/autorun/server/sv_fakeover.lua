
-- Send resources (such as materials) for clients to download.
do
	local resource = resource
	local resource_AddFile = resource.AddFile
	for _, resourcePath in next, {
		'materials/fakeover/bg.png',
		'materials/fakeover/gmod_logo_brave.png',
		'materials/fakeover/v.png'
	} do resource_AddFile(resourcePath) end
end

-- Register the network message.
local hook = hook
local hook_Call = hook.Call
do
	local hook_Add = hook.Add
	local util = util
	local util_AddNetworkString = util.AddNetworkString
	hook_Add('Initialize', 'fakeover.Initialize', function()
		-- It is safer in here.
		for _, messageName in next, {
			'fakeover_show',
			'fakeover_onclose',
			'fakeover_onshown'
		} do util_AddNetworkString(messageName) end
	end)
end

local FindMetaTable = FindMetaTable
local IsValid = IsValid
local ErrorNoHalt = ErrorNoHalt

local debug = debug
local _R = debug.getregistry()
local net = net

local PLAYER = FindMetaTable 'Player' -- It should not fail.
local Player_IsAdmin, Player_SteamID = PLAYER.IsAdmin, PLAYER.SteamID
local Entity_GetNWBool = PLAYER.MetaBaseClass.GetNWBool or _R.Entity.GetNWBool
local Entity_SetNWBool = PLAYER.MetaBaseClass.SetNWBool or _R.Entity.SetNWBool
local Entity_GetNWString = PLAYER.MetaBaseClass.GetNWString or _R.Entity.GetNWString
local Entity_SetNWString = PLAYER.MetaBaseClass.SetNWString or _R.Entity.SetNWString
do -- Register some helper functions on Player metatable :)
	-- Returns last message that has been shown on <self>'s fake overlay screen.
	PLAYER.GetLastFakeOverlayMessage = function(self)
		return IsValid(self) and Entity_GetNWString(self, 'LastFakeOverlayMessage', '') or ''
	end
	_R.Player.GetLastFakeOverlayMessage = PLAYER.GetLastFakeOverlayMessage

	-- Returns true if <self> has fake overlay screen; otherwise, false.
	PLAYER.HasFakeOverlayScreen = function(self)
		return IsValid(self) and Entity_GetNWBool(self, 'HasFakeOverlayScreen', false)
	end
	_R.Player.HasFakeOverlayScreen = PLAYER.HasFakeOverlayScreen

	local net_Start = net.Start
	local net_WriteString = net.WriteString
	local net_Send = net.Send
	-- Shows fake overlay with custom message on <self>'s screen.
	PLAYER.ShowFakeOverlayScreen = function(self, invoker, message)
		if not IsValid(self) or PLAYER.HasFakeOverlayScreen(sender) then return end -- Do not show if it is already being shown.
		message = message or ''
		Entity_SetNWString(self, 'LastFakeOverlayMessage', message)
		Entity_SetNWBool(self, 'HasFakeOverlayScreen', true)
		net_Start 'fakeover_show'
		net_WriteString(message)
		net_Send(self)
		hook_Call('CaptainPRICE.FakeOverlay.OnSend', nil, invoker or NULL, self, message) -- For 3rd party addons support.
	end
	_R.Player.ShowFakeOverlayScreen = PLAYER.ShowFakeOverlayScreen
end

-- Create a console command to make Fake Overlay usable, of course.
local concommand = concommand
local concommand_Add = concommand.Add
local player = player
local player_GetAll = player.GetAll
local player_GetBySteamID = player.GetBySteamID
local string = string
local string_Trim = string.Trim
local string_upper = string.upper
local string_find = string.find
concommand_Add('sv_send_fakeover', function(invoker, _, args)
	-- TODO: Add hook and check if player can run/execute this concommand.
	if (IsValid(invoker) and not Player_IsAdmin(invoker)) or #args ~= 2 then return end -- Console should be able to execute this command, too.
	local victim = player_GetBySteamID(args[1]) -- 1st argument should be the victim's Steam ID.
	if not victim then return ErrorNoHalt('fakeover: Could not find any player with Steam ID "' .. args[1] .. '"!\n') end
	-- Send it up to the victim's screen.
	PLAYER.ShowFakeOverlayScreen(victim, invoker, args[2]) -- 2nd argument should be the (text) message.
end, function(cmd, args)
	-- Autocompletion for Steam IDs.
	args = string_upper(string_Trim(args))
	local tbl = {}
	for _, ply in next, player_GetAll() do
		local m_strSteamID = Player_SteamID(ply)
		if string_find(string_upper(m_strSteamID), args) then
			tbl[#tbl + 1] = cmd .. ' \"' .. m_strSteamID .. '\"'
		end
	end
	return tbl
end, 'Sends a fake (loading) overlay with custom message to the specified player. Use it to prank players. ** BY DEFAULT, ONLY ADMINS CAN EXECUTE THIS COMMAND **\nExample usage (double-quotes matter!): sv_send_fakeover "STEAM_0:0:65979910" "everybody hates you"', FCVAR_NONE) -- TODO: Maybe use FCVAR_UNREGISTERED flag.

local net_Receive = net.Receive
local net_ReadBit = net.ReadBit
net_Receive('fakeover_onclose', function(length, sender)
	if length == 1 and PLAYER.HasFakeOverlayScreen(sender) then
		Entity_SetNWBool(sender, 'HasFakeOverlayScreen', false)
		hook_Call('CaptainPRICE.FakeOverlay.OnClose', nil, net_ReadBit(), sender) -- For 3rd party addons support.
	else
		hook_Call('CaptainPRICE.FakeOverlay.OnBadNetMsg', nil, sender) -- For 3rd party addons support. This normally can't happen, be sure to log such sender(s).
	end
end)

net_Receive('fakeover_onshown', function(length, sender)
	if length == 0 and PLAYER.HasFakeOverlayScreen(sender) then
		hook_Call('CaptainPRICE.FakeOverlay.OnShown', nil, PLAYER.GetLastFakeOverlayMessage(sender), sender) -- For 3rd party addons support.
	else
		hook_Call('CaptainPRICE.FakeOverlay.OnBadNetMsg', nil, sender) -- For 3rd party addons support. This normally can't happen, be sure to log such sender(s).
	end
end)
