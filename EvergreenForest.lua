-----------------------------------------------------------------------------------------------
-- Client Lua Script for EvergreenForest
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- EvergreenForest Module Definition
-----------------------------------------------------------------------------------------------
local EvergreenForest = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999

 local ktEvergreenDirectory = {
 	[59] = {player = "Noxxi Greenrose", plotName = "Dreamer's grove", owner = "Noxxi Greenrose", description = "Hidden away, deep in the forest, one can find plant based remedies in this pleasant and welcoming grove.", features = "", public = true, },
 	[22] = {player = "Vlinn Vineweaver", plotName = "Mellow Glade", owner = "Vlinn Vineweaver", description = "In this dark and wild part of the forest, a safe sanctuary awaits.", features = "", public = true, },
 	[15] = {player = "Daerin Frostwind", plotName = "Tallflower Retreat", owner = "Daerin Frostwind", description = "Daerin's house lays on top of a huge tree, whose roots reach deep in the earth of the forest.", features = "", public = true, }
}

 local ktWaitingStrings = {
	"Recombobulating teleporter to %s.",
	"Searching ProtostarMaps for best route to %s.",
	"Waving down cabbie for trip to %s.",
	"Recalculating best route to %s.",
	"Asking for directions to %s.",
 }
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function EvergreenForest:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
	self.bSearch = false
    -- initialize variables here

    return o
end

function EvergreenForest:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- EvergreenForest OnLoad
-----------------------------------------------------------------------------------------------
function EvergreenForest:OnLoad()
    -- load our form file
	Apollo.LoadSprites("EvergreenForestSprites.xml", "EvergreenForestSprites")
	self.xmlDoc = XmlDoc.CreateFromFile("EvergreenForest.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- EvergreenForest OnDocLoaded
-----------------------------------------------------------------------------------------------
function EvergreenForest:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "EvergreenForestForm", nil, self)
		self.wndTicker = self.wndMain:FindChild("wnd_Ticker")		
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
	    self.wndMain:Show(false, true)
				
		for i,v in pairs(ktEvergreenDirectory) do
			local btnCurr = self.wndMain:FindChild(tostring(i))
			local xmlTooltip = XmlDoc.new()
			xmlTooltip:StartTooltip(Tooltip.TooltipWidth)
			-- string, color, font, align
			xmlTooltip:AddLine(v.plotName, "FF00FF99", "CRB_Header14_O", "Center")
			if v.owner and string.len(v.owner) > 0 then
				xmlTooltip:AddLine(string.format("Owner: %s", v.owner), "FF00FFFF", "CRB_Interface10_BO", "Left")
			end
			xmlTooltip:AddLine(v.description, "FFFFFFFF", "CRB_Interface12_O")
			if v.features and string.len(v.features) > 0 then
				xmlTooltip:AddLine("――――――――――――――――", "FF00FF99", "CRB_Interface12_BO", "Center")
				xmlTooltip:AddLine(v.features, "FF00FF00", "CRB_Interface12_O")
			end
			
			if v.public == true then
				btnCurr:SetTextColor("FF00FF00")
			else
				btnCurr:SetTextColor("FFFFFF00")
				xmlTooltip:AddLine(string.format("Player, %s, has not made this plot pubic.", v.player), "FF991111", "CRB_Interface10_I")
			end
			btnCurr:SetTooltipDoc(xmlTooltip)
			btnCurr:SetData(v.player)
		end

		self.xmlDoc = nil
		
		Apollo.RegisterSlashCommand("evergreen", "OnEvergreenForestOn", self)
		Apollo.RegisterEventHandler("HousingRandomResidenceListRecieved", "TimeToCheck", self)
		Apollo.RegisterEventHandler("ToggleAddon_Evergreen", "OnEvergreenForestOn", self)
		Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
	end
end

function EvergreenForest:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "Evergreen's Forest", {"ToggleAddon_Evergreen", "", ""})
end

-----------------------------------------------------------------------------------------------
-- EvergreenForest Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/evergreen"
function EvergreenForest:OnEvergreenForestOn()
	self.wndMain:Invoke() -- show the window
end

-----------------------------------------------------------------------------------------------
-- EvergreenForestForm Functions
-----------------------------------------------------------------------------------------------
function EvergreenForest:ReturnHome()
	HousingLib.RequestTakeMeHome()
	self.wndTicker:StopDoogie()
	self.wndTicker:SetText("")
	self.wndMain:Show(false)
end

function EvergreenForest:OnCancel()
	self.wndMain:Close() -- hide the window
end

function EvergreenForest:OnPlotClick(wndHandler, wndControl, eMouseButton)
	local strOwner = wndControl:GetData()
	if strOwner == nil then return end
	if strOwner == GameLib.GetPlayerUnit():GetName() then
		HousingLib.RequestTakeMeHome()
		self.wndTicker:StopDoogie()
		self.wndTicker:SetText("")
		self.wndMain:Show(false)

		self.wndMain:Show(false)
		return
	end
	self.wndMain:SetData(strOwner)
	-- Taken from The Visitor Addon
	if HousingLib.IsHousingWorld() == false then
		Print("You must enter a housing plot first.")
		return
	end
	
	for i, v in pairs(ktEvergreenDirectory) do
		if v.player == strOwner then
			local xmlWaiting = XmlDoc.new()
			xmlWaiting:AddLine()
			xmlWaiting:AppendImage("CRB_Anim_Spinner:sprAnim_SpinnerLarge", 48, 48)
			xmlWaiting:AppendText(string.format(ktWaitingStrings[math.random(1, #ktWaitingStrings)], v.plotName), "FF00FF99", "CRB_Header12_O", "Left")
			self.wndTicker:SetDoc(xmlWaiting)
			self.wndTicker:BeginDoogie(150)
		end
	end
	
	self.iTotalSearches = 1
	self.tTotalNameList = {}
	--check if neighbor
	local tNeightborList = HousingLib.GetNeighborList()
	for i, v in pairs(tNeightborList) do
		if tNeightborList[i].strCharacterName == strOwner then
			HousingLib.VisitNeighborResidence(tNeightborList[i].nId)
			self.wndTicker:StopDoogie()
			self.wndTicker:SetText("")
			self.wndMain:Show(false)
			return
		end
	end
	--find target
	self.bSearch = true;
	self.iTotalSearches = 1;
	self.tTotalNameList = {}

	HousingLib.RequestRandomResidenceList();
end

function EvergreenForest:TimeToCheck()
	if HousingLib.IsHousingWorld() == false then
		Print("You must enter a housing plot first.")
		self.bSearch = false;
		return;
	end;
		
	if self.bSearch == false then 
		return;
	end
	--		Print("Looking");
	local strPlayerName = self.wndMain:GetData()
	strPlayerName = strPlayerName:lower()

	local bFound = false;
	local tCurrRandomSet = HousingLib.GetRandomResidenceList();

	local i=0;
		while i < #tCurrRandomSet do
		i=i+1;
		if tCurrRandomSet[i] == nil  then
		i=i+100;
		else
		   --update favorite
			local strOwnerrName = tCurrRandomSet[i].strCharacterName;
			self.tTotalNameList[strOwnerrName]=1;
			
			if string.lower(strOwnerrName) == strPlayerName  then 
				bFound = true;
				self.bSearch = false;
				self.iTotalSearches = 0
				self.tTotalNameList = {}
				HousingLib.RequestRandomVisit(tCurrRandomSet[i].nId);
				Print(tostring(tCurrRandomSet[i].nId))
				self.wndTicker:StopDoogie()
				self.wndTicker:SetText("")
				self.wndMain:Show(false)
				return
			end
		end

	end
	if bFound == false then
		self.iTotalSearches =self.iTotalSearches +1;
	end
	HousingLib.RequestRandomResidenceList();
end

-----------------------------------------------------------------------------------------------
-- EvergreenForest Instance
-----------------------------------------------------------------------------------------------
local EvergreenForestInst = EvergreenForest:new()
EvergreenForestInst:Init()
