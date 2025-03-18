local function PSC_RegisterSlashCommands()
    SLASH_PLAYERKILLANNOUNCE1 = "/playerkillannounce"
    SLASH_PLAYERKILLANNOUNCE2 = "/pka"
    SlashCmdList["PLAYERKILLANNOUNCE"] = PKA_SlashCommandHandler
end

local function Main()
    PSC_RegisterEvents()
    PSC_RegisterSlashCommands()
end

Main()
