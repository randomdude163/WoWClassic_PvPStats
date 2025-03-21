local function PSC_RegisterSlashCommands()
    SLASH_PVPSTATSCLASSIC1 = "/pvpstatsclassic"
    SLASH_PVPSTATSCLASSIC2 = "/psc"
    SlashCmdList["PVPSTATSCLASSIC"] = PSC_SlashCommandHandler
end

local function Main()
    PSC_RegisterEvents()
    PSC_RegisterSlashCommands()
end

Main()
