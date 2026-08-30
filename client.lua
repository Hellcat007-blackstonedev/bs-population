local debugEnabled = false
local current = { peds = 1.0, traffic = 1.0, parked = 1.0 }
local applied = { peds = 1.0, traffic = 1.0, parked = 1.0 }
local target = { peds = 1.0, traffic = 1.0, parked = 1.0 }
local profileBase = { peds = 1.0, traffic = 1.0, parked = 1.0 }
local observed = { peds = 0, vehicles = 0, parked = 0, radius = 100.0 }
local applyStats = { frames = 0, lastTick = 0 }
local state = {
    zone = 'UNKNOWN',
    areaType = Config.DefaultAreaType,
    areaLabel = 'Unknown',
    profile = 'Unknown',
    hour = 0,
    minute = 0,
    clockMinutes = 0,
    zoneMapped = true,
}

local initialized = false
local lastClockMinutes = nil
local warnedUnknownZones = {}

local function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function parseTime(value)
    local hour, minute = value:match('^(%d%d?):(%d%d)$')
    hour = tonumber(hour) or 0
    minute = tonumber(minute) or 0
    return (hour * 60) + minute
end

local function timeInRange(now, startMinutes, endMinutes)
    if startMinutes <= endMinutes then
        return now >= startMinutes and now < endMinutes
    end

    return now >= startMinutes or now < endMinutes
end

local function getActiveProfile(hour, minute)
    local now = (hour * 60) + minute

    for _, profile in ipairs(Config.TimeProfiles) do
        if timeInRange(now, parseTime(profile.startTime), parseTime(profile.endTime)) then
            return profile
        end
    end

    return Config.TimeProfiles[1]
end

local function getClock()
    return GetClockHours(), GetClockMinutes()
end

local function validDensity(value)
    return type(value) == 'number' and value >= 0.0
end

local function validateConfig()
    local warnings = 0

    local function warn(message)
        warnings = warnings + 1
        print(('^3[bs-population] CONFIG WARNING:^7 %s'):format(message))
    end

    if not Config.AreaTypes or not Config.AreaTypes[Config.DefaultAreaType] then
        warn(('DefaultAreaType "%s" does not exist in Config.AreaTypes.'):format(tostring(Config.DefaultAreaType)))
    end

    if type(Config.TimeProfiles) ~= 'table' or #Config.TimeProfiles == 0 then
        warn('Config.TimeProfiles is empty. At least one time profile is required.')
    else
        for index, profile in ipairs(Config.TimeProfiles) do
            if not profile.name then
                warn(('Time profile #%d has no name.'):format(index))
            end

            if type(profile.startTime) ~= 'string' or not profile.startTime:match('^%d%d?:%d%d$') then
                warn(('Time profile "%s" has an invalid startTime. Use HH:MM.'):format(profile.name or index))
            end

            if type(profile.endTime) ~= 'string' or not profile.endTime:match('^%d%d?:%d%d$') then
                warn(('Time profile "%s" has an invalid endTime. Use HH:MM.'):format(profile.name or index))
            end

            for _, key in ipairs({ 'peds', 'traffic', 'parked' }) do
                if not validDensity(profile[key]) then
                    warn(('Time profile "%s" has an invalid %s value.'):format(profile.name or index, key))
                end
            end
        end
    end

    if type(Config.ZoneTypes) == 'table' then
        for zone, areaType in pairs(Config.ZoneTypes) do
            if not Config.AreaTypes[areaType] then
                warn(('Zone %s references unknown area type "%s".'):format(zone, tostring(areaType)))
            end
        end
    end

    if Config.PrintStartupMessage then
        if warnings == 0 then
            print('^2[bs-population]^7 Loaded successfully. Configuration validation passed.')
        else
            print(('^3[bs-population]^7 Loaded with %d configuration warning(s).'):format(warnings))
        end
    end
end

local function calculateTarget()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local zone = GetNameOfZone(coords.x, coords.y, coords.z)
    local configuredAreaType = Config.ZoneTypes[zone]
    local zoneMapped = configuredAreaType ~= nil
    local areaTypeName = configuredAreaType or Config.DefaultAreaType
    local area = Config.AreaTypes[areaTypeName] or Config.AreaTypes[Config.DefaultAreaType]

    if not zoneMapped and debugEnabled and not warnedUnknownZones[zone] then
        warnedUnknownZones[zone] = true
        print(('^3[bs-population] UNMAPPED ZONE:^7 "%s" is not in Config.ZoneTypes. Using fallback "%s".'):format(tostring(zone), tostring(Config.DefaultAreaType)))
    end

    local hour, minute = getClock()
    local profile = getActiveProfile(hour, minute)

    profileBase.peds = profile.peds
    profileBase.traffic = profile.traffic
    profileBase.parked = profile.parked

    local peds = profile.peds * area.peds
    local traffic = profile.traffic * area.traffic
    local parked = profile.parked * area.parked

    if profile.peakHour then
        traffic = traffic * (area.peakTraffic or 1.0)

        local zoneBoost = Config.PeakTrafficZones[zone]
        if zoneBoost then
            traffic = traffic * zoneBoost
        end
    end

    if profile.nightlife then
        peds = peds * (area.nightlifePeds or 1.0)
        traffic = traffic * (area.nightlifeTraffic or 1.0)

        local nightlife = Config.NightlifeZones[zone]
        if nightlife then
            peds = peds * (nightlife.peds or 1.0)
            traffic = traffic * (nightlife.traffic or 1.0)
        end
    end

    target.peds = clamp(peds, Config.Minimums.peds, Config.Maximums.peds)
    target.traffic = clamp(traffic, Config.Minimums.traffic, Config.Maximums.traffic)
    target.parked = clamp(parked, Config.Minimums.parked, Config.Maximums.parked)

    state.zone = zone
    state.areaType = areaTypeName
    state.areaLabel = area.label or areaTypeName
    state.profile = profile.name
    state.hour = hour
    state.minute = minute
    state.clockMinutes = (hour * 60) + minute
    state.zoneMapped = zoneMapped
end

local function lerp(currentValue, targetValue, alpha)
    return currentValue + ((targetValue - currentValue) * alpha)
end

local function countNearbyPopulation()
    local playerPed = PlayerPedId()
    local origin = GetEntityCoords(playerPed)
    local radius = Config.DebugSampleRadius or 100.0
    local radiusSq = radius * radius

    local pedCount = 0
    local vehicleCount = 0
    local parkedCount = 0

    for _, ped in ipairs(GetGamePool('CPed')) do
        if DoesEntityExist(ped) and ped ~= playerPed and not IsPedAPlayer(ped) then
            local coords = GetEntityCoords(ped)
            local dx = coords.x - origin.x
            local dy = coords.y - origin.y
            local dz = coords.z - origin.z
            if (dx * dx + dy * dy + dz * dz) <= radiusSq then
                pedCount = pedCount + 1
            end
        end
    end

    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if DoesEntityExist(vehicle) then
            local coords = GetEntityCoords(vehicle)
            local dx = coords.x - origin.x
            local dy = coords.y - origin.y
            local dz = coords.z - origin.z
            if (dx * dx + dy * dy + dz * dz) <= radiusSq then
                vehicleCount = vehicleCount + 1
                if GetEntitySpeed(vehicle) < 0.25 then
                    parkedCount = parkedCount + 1
                end
            end
        end
    end

    observed.peds = pedCount
    observed.vehicles = vehicleCount
    observed.parked = parkedCount
    observed.radius = radius
end

local function sendDebugState()
    if not debugEnabled then return end

    SendNUIMessage({
        action = 'update',
        data = {
            enabled = Config.Enabled,
            time = ('%02d:%02d'):format(state.hour, state.minute),
            zone = state.zone,
            area = state.areaLabel,
            zoneMapped = state.zoneMapped,
            fallbackArea = Config.DefaultAreaType,
            profile = state.profile,
            transitionSeconds = Config.TransitionSeconds,
            base = profileBase,
            target = target,
            applied = applied,
            observed = observed,
            applyStats = applyStats,
            ui = {
                brand = Config.DebugBrand or 'SERVER DEV',
                title = Config.DebugTitle or 'Population Monitor',
                key = Config.DebugKey or 'F7',
                command = Config.DebugCommand or 'popdebug',
            },
        }
    })
end

local function setDebugVisible(visible)
    debugEnabled = visible
    SendNUIMessage({ action = 'visible', visible = visible })

    if visible then
        calculateTarget()
        countNearbyPopulation()
        sendDebugState()
    end
end

CreateThread(function()
    while true do
        if Config.Enabled then
            calculateTarget()

            if not initialized then
                -- Do not spend the first 45 seconds pretending the server is at 100%.
                -- The very first calculation is the authoritative starting value.
                current.peds = target.peds
                current.traffic = target.traffic
                current.parked = target.parked
                initialized = true
            elseif Config.SnapOnClockJump and lastClockMinutes ~= nil then
                -- Admin/time-sync resources often jump the GTA clock by hours. Smoothly
                -- blending that test jump makes debugging look broken, so snap large jumps.
                local diff = math.abs(state.clockMinutes - lastClockMinutes)
                diff = math.min(diff, 1440 - diff)

                if diff >= (Config.ClockJumpThresholdMinutes or 15) then
                    current.peds = target.peds
                    current.traffic = target.traffic
                    current.parked = target.parked
                end
            end

            lastClockMinutes = state.clockMinutes
        else
            profileBase.peds = 1.0
            profileBase.traffic = 1.0
            profileBase.parked = 1.0
            target.peds = 1.0
            target.traffic = 1.0
            target.parked = 1.0
            current.peds = 1.0
            current.traffic = 1.0
            current.parked = 1.0
            initialized = true
        end

        Wait(Config.UpdateInterval)
    end
end)

CreateThread(function()
    while true do
        if debugEnabled and Config.Debug then
            countNearbyPopulation()
            sendDebugState()
            Wait(Config.DebugSampleInterval or 1000)
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    local transitionMs = math.max(1.0, Config.TransitionSeconds * 1000.0)

    while true do
        Wait(0)

        local frameMs = GetFrameTime() * 1000.0
        local alpha = clamp(frameMs / transitionMs, 0.0, 1.0)

        current.peds = lerp(current.peds, target.peds, alpha)
        current.traffic = lerp(current.traffic, target.traffic, alpha)
        current.parked = lerp(current.parked, target.parked, alpha)

        -- Capture the EXACT values that are sent to GTA this frame. The debug UI
        -- reads this table, so APPLIED can no longer disagree with the native calls.
        applied.peds = clamp(current.peds, 0.0, 1.0)
        applied.traffic = clamp(current.traffic, 0.0, 1.0)
        applied.parked = clamp(current.parked, 0.0, 1.0)

        local randomTraffic = clamp(applied.traffic * (Config.VehicleMultipliers.randomVehicles or 1.0), 0.0, 1.0)

        -- These natives are frame-scoped. They MUST be called every frame.
        -- Do not add a scenario-vehicle density call here: FiveM exposes the
        -- standard vehicle/random/parked density natives plus scenario PED density.
        SetPedDensityMultiplierThisFrame(applied.peds)
        SetScenarioPedDensityMultiplierThisFrame(applied.peds, applied.peds)
        SetVehicleDensityMultiplierThisFrame(applied.traffic)
        SetRandomVehicleDensityMultiplierThisFrame(randomTraffic)
        SetParkedVehicleDensityMultiplierThisFrame(applied.parked)

        applyStats.frames = applyStats.frames + 1
        applyStats.lastTick = GetGameTimer()
    end
end)

validateConfig()

if Config.Debug then
    RegisterCommand(Config.DebugCommand, function()
        setDebugVisible(not debugEnabled)
        print(('[bs-population] Debug UI %s'):format(debugEnabled and 'enabled' or 'disabled'))
    end, false)

    RegisterKeyMapping(
        Config.DebugCommand,
        'Toggle bs-population debug UI',
        'keyboard',
        Config.DebugKey
    )
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        SendNUIMessage({ action = 'visible', visible = false })
    end
end)
