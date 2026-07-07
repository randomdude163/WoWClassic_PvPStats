local addonName, PVPSC = ...

local function BPP_RegisterSlashCommands()
    SLASH_BIGPPVPSTATS1 = "/bigppvpstats"
    SLASH_BIGPPVPSTATS2 = "/bpp"
    SlashCmdList["BIGPPVPSTATS"] = BPP_SlashCommandHandler
end

local function BPP_InitializeNetwork()
    -- Initialize network handler after a short delay to ensure everything is loaded
    C_Timer.After(2, function()
        if PVPSC.Network and PVPSC.Network.Initialize then
            PVPSC.Network:Initialize()
        end
    end)
end

local function Main()
    BPP_RegisterEvents()
    BPP_RegisterSlashCommands()
    BPP_InitializeNetwork()
end

Main()
