include("shared.lua")
include("plymeta.lua")

include("vgui/cl_scoreboard.lua")
include("vgui/cl_voice.lua")
include("vgui/gui.lua")
include("vgui/gui_sourcemod.lua")
include("vgui/gui_gm9.lua")
include("vgui/gui_fretta.lua")
include("vgui/drawarc.lua")

CreateClientConVar("910_model", "", true, true, "Set your playermodel.")

function GM:GenerateFonts()
	surface.CreateFont("ImpactMassive", {
		font = "Impact",
		size = ScreenScale(17.5),
		weight = 200,
		antialias = true,
		extended = true
	})

	surface.CreateFont("DefaultShadow", {
		font = "Verdana",
		size = ScreenScale(6),
		weight = 700,
		antialias = true,
		shadow = true,
		extended = true
	})

	surface.CreateFont("LegacyDefault", {
		font = "Verdana",
		size = ScreenScale(6),
		weight = 700,
		antialias = true,
		extended = true
	})

	surface.CreateFont("LegacyDefaultThin", {
		font = "Verdana",
		size = ScreenScale(6),
		weight = 500,
		antialias = true,
		extended = true
	})

	surface.CreateFont("SourcemodScore", {
		font = "Tahoma Bold",
		size = ScreenScale(25),
		antialias = true
	})

	surface.CreateFont("SourcemodTime", {
		font = "Tahoma Bold",
		size = ScreenScale(26.75),
		antialias = true
	})

	surface.CreateFont("SourcemodWin", {
		font = "Tahoma Bold",
		size = ScreenScale(31.75),
		antialias = true,
		extended = true
	})

	surface.CreateFont("SourcemodWinScores", {
		font = "Trebuchet MS",
		size = ScreenScale(18),
		weight = 700,
		antialias = true,
		extended = true
	})

	surface.CreateFont( "FrettaHUDElement", {
		font = "Trebuchet MS",
		size = 32,
		weight = 800
	})

	surface.CreateFont( "SplashHuge", {
		font = "coolvetica",
		size = 44,
		weight = 500,
		extended = true
	})

	surface.CreateFont( "SplashMed", {
		font = "coolvetica",
		size = 30,
		weight = 500,
		extended = true
	})
end

local unsupported = {
	["el"] = "Η ελληνική γλώσσα δεν υποστηρίζεται. Συμβάλετε εδώ:",
	["et"] = "Eesti keel toetamata. Anna oma panus siin:",
	["fi"] = "Suomen kieltä ei tueta. Osallistu täällä:",
	["he"] = "אין תמיכה בשפה העברית. תרמו כאן:",
	-- ["hr"] = "Hrvatski jezik nije podržan. Doprinesite ovdje:",
	["ko"] = "한국어는 지원하지 않습니다. 여기에 기여하세요:",
	["lt"] = "lietuvių kalba nepalaikoma. Prisidėkite čia:",
	["nl"] = "Nederlandse taal niet ondersteund. Draag hier bij:",
	["no"] = "Norsk språk støttes ikke. Bidra her:",
	["pt-pt"] = "Língua portuguesa europeia não suportada. Contribua aqui:",
	["sk"] = "Slovenský jazyk nie je podporovaný. Prispejte sem:",
	-- ["sv-se"] = "Svenska språket stöds inte. Bidra här:",
	["tr"] = "Türkçe dil desteklenmiyor. Buraya katkıda bulunun:",
	["zh-cn"] = "不支持中文（简体）语言。 在这里贡献：",
	["zh-tw"] = "不支持中文（繁體）語言。 在這裡貢獻："
}

local titlemat = Material("gmod/gm_910/910")
function GM:InitPostEntity()
	self:GenerateFonts()

	if !self.ItemCount then self.ItemCount = {} end

	local lang = GetConVar("gmod_language"):GetString():lower()
	if unsupported[lang] then
		ply:ChatPrint("Selected language is unsupported. Contribute here: https://crowdin.com/project/melonracer")
		ply:ChatPrint(unsupported[lang] .. " https://crowdin.com/project/melonracer")
	end

	if game.GetMap() == "910_scramble" and !IsMounted("ep2") then
		chat.AddText("This map will have missing textures because you don't have Half-Life 2: Episode Two mounted.")
	end

	local shitfix = vgui.Create("DPanel") -- YOU AGAIN
	shitfix:SetPos(0, 0)
	shitfix:SetSize(1, 1)
	timer.Simple(7, function() shitfix:Remove() end)

	local w = ScrW()
	local h = ScrH()

	-- Intro Logo
	local title = vgui.Create("DPanel")
	title:SetSize(w * 0.35, h * 0.4)
	title:SetPos(w * 0.325, h * 0.3)

	title:AlphaTo(0, 1.5, 3, function(_, pnl) pnl:Remove() end) -- this doesn't work for whatever reason but it removes the panel at least

	title.Paint = function(s, x, y)
		surface.SetMaterial(titlemat)

		s:DrawTexturedRect()
	end

	net.Start("910_Ready")
	net.SendToServer()
end

function GM:PreCleanupMap()
	if !self.CurrentTeamID then return end

	for i = 1, self.CurrentTeamID do
		self.ItemCount[i] = 0
	end
end

local standardLangs = { -- we don't have umlauts and accents so we can get away with string.upper. another W for the bri'ish language
	["en"] = true, -- English
	["en-pt"] = true -- YARR!!
}

local capitalLangs = { -- anything that isn't latin, cyrillic, greek, or armenian doesn't use capitals
	["bg"] = true, -- Bulgarian
	["cs"] = true, -- Czech
	["da"] = true, -- Danish
	["de"] = true, -- German
	["el"] = true, -- Greek
	["es-es"] = true, -- Spanish
	["et"] = true, -- Estonian
	["fi"] = true, -- Finnish
	["fr"] = true, -- French
	["hr"] = true, -- Croatian
	["hu"] = true, -- Hungarian
	["it"] = true, -- Italian
	["lt"] = true, -- Lithuanian
	["nl"] = true, -- Dutch
	["no"] = true, -- Norwegian
	["pl"] = true, -- Polish
	["pt-br"] = true, -- Portuguese (Brazilian)
	["pt-pt"] = true, -- Portuguese
	["ru"] = true, -- Russian
	["sk"] = true, -- Slovakian
	["sv-se"] = true, -- Swedish
	["tr"] = true, -- Turkish
	["uk"] = true, -- Ukrainian
	["vi"] = true -- Vietnamese
}

-- do NOT call this every frame
function utf8upper(str)
	local curLang = GetConVar("gmod_language"):GetString():lower()
	if standardLangs[curLang] then return str:upper() end
	if !capitalLangs[curLang] then return str end

	local codes = {}

	for i = 1, utf8.len(str, 1, -1) do
		local char = utf8.sub(str, i, i)
		local code = utf8.codepoint(char)
		if (code >= 97 and code <= 122) or (code >= 224 and code <= 254) then
			code = code - 32
		end

		table.insert(codes, code)
	end

	return utf8.char(unpack(codes))
end

local function SetGamemodeVersion()
	GAMEMODE.GamemodeVersion = net.ReadUInt(2)
end
net.Receive("910_SendMode", SetGamemodeVersion)