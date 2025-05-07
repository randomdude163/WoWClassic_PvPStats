local addonName, PVPSC = ...

-- Communication constants
PSC_MESSAGE_PREFIX = "PSC"
local PSC_MESSAGE_QUEUE = {}
local PSC_LAST_SEND_TIME = 0
local PSC_DEFAULT_THROTTLE = 0.3  -- Start conservative
local PSC_CURRENT_THROTTLE = PSC_DEFAULT_THROTTLE
local PSC_MAX_THROTTLE = 2.0  -- Don't wait longer than this
local PSC_BACKOFF_MULTIPLIER = 1.5 -- Increase wait time by this when throttled
local PSC_MESSAGE_TIMEOUT = 5.0 -- Seconds to wait for response before considering throttled

-- Track message statistics for debugging
local PSC_DEBUG = {
    enabled = true,
    messagesSent = 0,
    messagesQueued = 0,
    throttledAttempts = 0,
    lastThrottleTime = 0,
    avgProcessingTime = 0
}

-- Message types
local MSG_TYPE_BASIC_STATS = 1
local MSG_TYPE_CLASS_DATA = 2
local MSG_TYPE_RACE_DATA = 3
local MSG_TYPE_LEVEL_DATA = 4

-- Priority values
local PRIORITY_HIGH = 1
local PRIORITY_NORMAL = 2
local PRIORITY_LOW = 3

-- Enable/disable debug mode
function PSC_SetDebugMode(enabled)
    PSC_DEBUG.enabled = enabled
    if enabled then
        print("[PSC Debug] Communication debugging enabled")
    end
end

-- Detect if we're being throttled and adjust accordingly
function PSC_DetectThrottling(messageId)
    -- If we never got a response for this message, assume throttled
    PSC_DEBUG.throttledAttempts = PSC_DEBUG.throttledAttempts + 1
    PSC_DEBUG.lastThrottleTime = GetTime()

    -- Increase throttle interval (with cap)
    PSC_CURRENT_THROTTLE = math.min(PSC_MAX_THROTTLE, PSC_CURRENT_THROTTLE * PSC_BACKOFF_MULTIPLIER)

    if PSC_DEBUG.enabled then
        print("[PSC Debug] Throttling detected. Increasing delay to " .. PSC_CURRENT_THROTTLE)
    end
end

-- Gradually reduce throttle if things are working well
function PSC_ReduceThrottleIfPossible()
    if GetTime() - PSC_DEBUG.lastThrottleTime > 10 and PSC_CURRENT_THROTTLE > PSC_DEFAULT_THROTTLE then
        PSC_CURRENT_THROTTLE = math.max(PSC_DEFAULT_THROTTLE, PSC_CURRENT_THROTTLE * 0.9)

        if PSC_DEBUG.enabled then
            print("[PSC Debug] Reducing throttle to " .. PSC_CURRENT_THROTTLE)
        end
    end
end

-- Queue a message with priority
function PSC_QueueMessage(messageType, data, channel, priority)
    local message = {
        type = messageType,
        data = data,
        channel = channel or "GUILD",
        priority = priority or PRIORITY_NORMAL,
        id = time() .. "-" .. math.random(1000),
        timestamp = GetTime()
    }

    table.insert(PSC_MESSAGE_QUEUE, message)
    PSC_DEBUG.messagesQueued = PSC_DEBUG.messagesQueued + 1

    if PSC_DEBUG.enabled then
        print("[PSC Debug] Queued message type " .. messageType .. " (" .. #PSC_MESSAGE_QUEUE .. " in queue)")
    end

    PSC_ProcessMessageQueue()
end

-- Process the message queue respecting throttling
function PSC_ProcessMessageQueue()
    if #PSC_MESSAGE_QUEUE == 0 then return end

    local currentTime = GetTime()
    if currentTime - PSC_LAST_SEND_TIME < PSC_CURRENT_THROTTLE then
        C_Timer.After(PSC_CURRENT_THROTTLE - (currentTime - PSC_LAST_SEND_TIME), PSC_ProcessMessageQueue)
        return
    end

    -- Sort queue by priority
    table.sort(PSC_MESSAGE_QUEUE, function(a, b)
        return a.priority < b.priority
    end)

    local message = table.remove(PSC_MESSAGE_QUEUE, 1)
    local success = PSC_SendMessage(message.type, message.data, message.channel)

    if success then
        PSC_LAST_SEND_TIME = currentTime
        PSC_DEBUG.messagesSent = PSC_DEBUG.messagesSent + 1

        -- Periodically try to reduce throttling if we've been successful
        PSC_ReduceThrottleIfPossible()

        if PSC_DEBUG.enabled then
            print("[PSC Debug] Sent message type " .. message.type .. " to " .. message.channel .. ", data: " .. message.data)
        end
    else
        -- Re-queue with lower priority if send failed
        message.priority = message.priority + 1
        table.insert(PSC_MESSAGE_QUEUE, message)

        if PSC_DEBUG.enabled then
            print("[PSC Debug] Failed to send message, re-queued with lower priority")
        end
    end

    -- Process next message if queue not empty
    if #PSC_MESSAGE_QUEUE > 0 then
        C_Timer.After(PSC_CURRENT_THROTTLE, PSC_ProcessMessageQueue)
    end
end

-- Send a single message
function PSC_SendMessage(messageType, data, channel)
    local success = C_ChatInfo.SendAddonMessage(PSC_MESSAGE_PREFIX, messageType .. ":" .. data, channel)
    return success
end

-- Initialize communication system
function PSC_InitCommunication()
    C_ChatInfo.RegisterAddonMessagePrefix(PSC_MESSAGE_PREFIX)

    -- Debug command
    SLASH_PSCDEBUG1 = "/pscdebug"
    SlashCmdList["PSCDEBUG"] = function(msg)
        if msg == "on" then
            PSC_SetDebugMode(true)
        elseif msg == "off" then
            PSC_SetDebugMode(false)
        elseif msg == "stats" then
            print("[PSC Debug] Stats:")
            print("  Messages sent: " .. PSC_DEBUG.messagesSent)
            print("  Messages queued: " .. PSC_DEBUG.messagesQueued)
            print("  Throttling events: " .. PSC_DEBUG.throttledAttempts)
            print("  Current throttle: " .. PSC_CURRENT_THROTTLE)
        end
    end

    if PSC_DEBUG.enabled then
        print("[PSC Debug] Communication system initialized")
    end
end