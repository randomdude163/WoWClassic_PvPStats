local function RegisterSlashCommands()
    SLASH_PLAYERKILLANNOUNCE1 = "/playerkillannounce"
    SLASH_PLAYERKILLANNOUNCE2 = "/pka"
    SlashCmdList["PLAYERKILLANNOUNCE"] = PKA_SlashCommandHandler
end

local function Main()
    RegisterEvents()
    RegisterSlashCommands()
end

Main()
