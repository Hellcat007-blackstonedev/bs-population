Config = {}

--[[
    ============================================================================
    bs-population - Server Configuration
    ============================================================================

    Controls GTA V's AMBIENT pedestrians, moving traffic and parked vehicles.

    This resource does not delete or modify peds/vehicles spawned by jobs,
    missions or other resources. It only changes GTA's ambient population
    density multipliers.

    QUICK START
    --------------------------------------------------------------------------
    1. Leave the General Settings alone unless you have a reason to change them.
    2. Edit Config.TimeProfiles to decide how busy each time of day should be.
    3. Edit Config.AreaTypes to decide how busy different kinds of areas are.
    4. Edit Config.ZoneTypes if you want GTA zones classified differently.
    5. Enable Config.Debug while tuning, then disable it for production.

    DENSITY VALUES
    --------------------------------------------------------------------------
    0.00 = no new ambient population of that type
    0.50 = approximately half of GTA's normal density
    1.00 = GTA's normal density

    Values stack together. For example:
        Time profile traffic 0.50 x Rural traffic 0.40 = final traffic 0.20

    The final result is clamped by Config.Minimums / Config.Maximums.
    ============================================================================
]]

-- ============================================================================
-- 1. GENERAL SETTINGS
-- ============================================================================

-- Master switch for the resource's population control.
-- When false, GTA's normal 1.0 density values are applied instead.
Config.Enabled = true

-- How often, in milliseconds, the script recalculates the current GTA zone,
-- time profile and target densities. Density natives are still applied every
-- rendered frame because GTA requires that behaviour.
Config.UpdateInterval = 1000

-- How long normal density changes take to blend into the new target.
-- Set to 0.0 if you want changes to apply instantly.
Config.TransitionSeconds = 20.0

-- Time-sync/admin resources often jump the in-game clock by hours. When enabled,
-- large clock jumps snap immediately to the correct population profile instead
-- of slowly blending from the previous time of day.
Config.SnapOnClockJump = true
Config.ClockJumpThresholdMinutes = 15

-- GTA's current game clock is used, so bs-population automatically follows
-- whatever time-sync resource your server already uses.
Config.UseGameClock = true

-- Print a short startup/config validation message in the F8 console.
Config.PrintStartupMessage = true

-- ============================================================================
-- 2. TIME-OF-DAY PROFILES
-- ============================================================================
--
-- These are the BASE densities before area/zone modifiers are applied.
-- Times use 24-hour HH:MM format and ranges may pass through midnight.
--
-- Optional flags:
--   peakHour = true   -> enables peakTraffic multipliers / zone boosts
--   nightlife = true  -> enables nightlife multipliers / zone boosts
--
-- You can change the values and times freely. If you add/remove profiles,
-- make sure the full 24-hour day remains covered.

Config.TimeProfiles = {
    {
        name = 'Early Commute',
        startTime = '05:00',
        endTime = '06:30',
        peds = 0.25,
        traffic = 0.50,
        parked = 0.80,
    },
    {
        name = 'Morning Peak',
        startTime = '06:30',
        endTime = '09:00',
        peds = 0.75,
        traffic = 1.00,
        parked = 0.90,
        peakHour = true,
    },
    {
        name = 'Daytime',
        startTime = '09:00',
        endTime = '15:30',
        peds = 0.78,
        traffic = 0.82,
        parked = 0.86,
    },
    {
        name = 'Afternoon Peak',
        startTime = '15:30',
        endTime = '18:30',
        peds = 0.85,
        traffic = 1.00,
        parked = 0.92,
        peakHour = true,
    },
    {
        name = 'Evening',
        startTime = '18:30',
        endTime = '21:00',
        peds = 0.65,
        traffic = 0.72,
        parked = 0.88,
    },
    {
        name = 'Nightlife',
        startTime = '21:00',
        endTime = '02:00',
        peds = 0.35,
        traffic = 0.50,
        parked = 0.82,
        nightlife = true,
    },
    {
        name = 'Late Night',
        startTime = '02:00',
        endTime = '03:00',
        peds = 0.12,
        traffic = 0.25,
        parked = 0.76,
    },
    {
        -- Intentionally almost deserted. Existing entities are not deleted;
        -- they disappear naturally as players move away and GTA cleans them up.
        name = 'Dead Hours',
        startTime = '03:00',
        endTime = '05:00',
        peds = 0.00,
        traffic = 0.08,
        parked = 0.72,
    },
}

-- ============================================================================
-- 3. AREA TYPES
-- ============================================================================
--
-- Every GTA zone is assigned an area type in Config.ZoneTypes below.
-- These values multiply the active time profile.
--
-- peds / traffic / parked:
--     Normal area multipliers.
--
-- peakTraffic:
--     Extra moving-traffic multiplier only during profiles with peakHour=true.
--
-- nightlifePeds / nightlifeTraffic:
--     Extra multipliers only during profiles with nightlife=true.

Config.AreaTypes = {
    city = {
        label = 'City',
        peds = 1.00,
        traffic = 1.00,
        parked = 1.00,
        peakTraffic = 1.00,
        nightlifePeds = 1.00,
        nightlifeTraffic = 1.00,
    },

    suburbs = {
        label = 'Suburbs',
        peds = 0.72,
        traffic = 0.82,
        parked = 0.95,
        peakTraffic = 1.08,
        nightlifePeds = 0.55,
        nightlifeTraffic = 0.72,
    },

    -- Coastal recreation areas. GTA commonly reports OCEANA while standing
    -- on the sand, so this category intentionally keeps daytime foot traffic
    -- high while reducing road traffic compared with a normal city zone.
    beach = {
        label = 'Beach',
        peds = 1.10,
        traffic = 0.55,
        parked = 0.80,
        peakTraffic = 0.90,
        nightlifePeds = 0.55,
        nightlifeTraffic = 0.60,
    },

    ruralTown = {
        label = 'Rural Town',
        peds = 0.48,
        traffic = 0.55,
        parked = 0.82,
        peakTraffic = 0.95,
        nightlifePeds = 0.35,
        nightlifeTraffic = 0.48,
    },

    rural = {
        label = 'Rural',
        peds = 0.18,
        traffic = 0.38,
        parked = 0.55,
        peakTraffic = 0.85,
        nightlifePeds = 0.15,
        nightlifeTraffic = 0.35,
    },

    wilderness = {
        label = 'Wilderness',
        peds = 0.03,
        traffic = 0.12,
        parked = 0.15,
        peakTraffic = 0.60,
        nightlifePeds = 0.05,
        nightlifeTraffic = 0.20,
    },
}

-- ============================================================================
-- 4. SPECIAL ZONE BOOSTS
-- ============================================================================

-- Optional extra nightlife activity for specific GTA zones.
-- These values stack on top of the active Nightlife profile and AreaType.
-- Delete a zone from this table if you do not want a special nightlife boost.
Config.NightlifeZones = {
    DTVINE = { peds = 1.00, traffic = 1.00 }, -- Explicitly mapped; no extra boost by default
    DOWNT = { peds = 1.75, traffic = 1.25 },
    VINE = { peds = 2.10, traffic = 1.30 },
    WVINE = { peds = 1.85, traffic = 1.20 },
    DELPE = { peds = 1.70, traffic = 1.15 },
    BEACH = { peds = 1.55, traffic = 1.10 },
    VESP = { peds = 1.55, traffic = 1.10 },
    HAWICK = { peds = 1.45, traffic = 1.15 },
}

-- Optional extra traffic for commuter-heavy zones during peak-hour profiles.
Config.PeakTrafficZones = {
    DOWNT = 1.15,
    ALTA = 1.12,
    PBOX = 1.12,
    TEXTI = 1.10,
    VINE = 1.10,
    WVINE = 1.08,
    ROCKF = 1.08,
    MIRR = 1.08,
    DELPE = 1.08,
}

-- ============================================================================
-- 5. GTA ZONE CLASSIFICATION
-- ============================================================================
--
-- GTA reports a short zone code for the player's current location.
-- Each code below is mapped to one of the AreaTypes above.
--
-- The standard GTA V zone codes returned by GET_NAME_OF_ZONE are mapped below.
-- If a custom map/DLC/mod returns an unknown code, Config.DefaultAreaType is used
-- and bs-population will warn once in F8 while debug is enabled.
--
-- IMPORTANT: use the short code returned by GET_NAME_OF_ZONE (for example DTVINE),
-- not a street name, postal, or made-up label such as ROUTE68.

Config.DefaultAreaType = 'suburbs'

Config.ZoneTypes = {
    -- ========================================================================
    -- LOS SANTOS - DENSE URBAN / COMMERCIAL + COASTAL
    -- ========================================================================
    AIRP = 'city',       -- Los Santos International Airport
    ALTA = 'city',       -- Alta
    BANNING = 'city',    -- Banning
    BEACH = 'beach',     -- Vespucci Beach
    BURTON = 'city',     -- Burton
    CHAMH = 'city',      -- Chamberlain Hills
    DAVIS = 'city',      -- Davis
    DELBE = 'beach',     -- Del Perro Beach
    DELPE = 'city',      -- Del Perro
    DELSOL = 'city',     -- La Puerta
    DOWNT = 'city',      -- Downtown
    DTVINE = 'city',     -- Downtown Vinewood
    ELYSIAN = 'city',    -- Elysian Island
    HAWICK = 'city',     -- Hawick
    KOREAT = 'city',     -- Little Seoul
    LEGSQU = 'city',     -- Legion Square
    LOSPUER = 'city',    -- La Puerta
    PBOX = 'city',       -- Pillbox Hill
    SKID = 'city',       -- Mission Row
    STRAW = 'city',      -- Strawberry
    TEXTI = 'city',      -- Textile City
    TERMINA = 'city',    -- Terminal
    VCANA = 'city',      -- Vespucci Canals
    VESP = 'city',       -- Vespucci
    VINE = 'city',       -- Vinewood
    WVINE = 'city',      -- West Vinewood
    ZP_ORT = 'city',     -- Port of South Los Santos

    -- ========================================================================
    -- LOS SANTOS - LOWER DENSITY / RESIDENTIAL / INDUSTRIAL
    -- ========================================================================
    CYPRE = 'suburbs',   -- Cypress Flats
    EAST_V = 'suburbs',  -- East Vinewood
    EBURO = 'suburbs',   -- El Burro Heights
    GOLF = 'suburbs',    -- GWC and Golfing Society
    OBSERV = 'suburbs',  -- Galileo Observatory
    HORS = 'suburbs',    -- Vinewood Racetrack
    LMESA = 'suburbs',   -- La Mesa
    MIRR = 'suburbs',    -- Mirror Park
    MORN = 'suburbs',    -- Morningwood
    MOVIE = 'suburbs',   -- Richards Majestic
    MURRI = 'suburbs',   -- Murrieta Heights
    PBLUFF = 'suburbs',  -- Pacific Bluffs
    RANCHO = 'suburbs',  -- Rancho
    RGLEN = 'suburbs',   -- Richman Glen
    RICHM = 'suburbs',   -- Richman
    ROCKF = 'suburbs',   -- Rockford Hills
    STAD = 'suburbs',    -- Maze Bank Arena

    -- ========================================================================
    -- RURAL TOWNS / SMALL SETTLEMENTS
    -- ========================================================================
    GALFISH = 'ruralTown', -- Galilee
    GALLI = 'ruralTown',   -- Galileo Park
    GRAPES = 'ruralTown',  -- Grapeseed
    HARMO = 'ruralTown',   -- Harmony
    PALETO = 'ruralTown',  -- Paleto Bay
    SANDY = 'ruralTown',   -- Sandy Shores
    SLAB = 'ruralTown',    -- Stab City

    -- ========================================================================
    -- RURAL / HIGHWAYS / FARMLAND / FACILITIES
    -- ========================================================================
    ARMYB = 'rural',      -- Fort Zancudo
    BANHAMC = 'rural',    -- Banham Canyon Dr
    BAYTRE = 'rural',     -- Baytree Canyon
    BHAMCA = 'rural',     -- Banham Canyon
    CALAFB = 'rural',     -- Calafia Bridge
    CHU = 'rural',        -- Chumash
    DESRT = 'rural',      -- Grand Senora Desert
    GREATC = 'rural',     -- Great Chaparral
    HUMLAB = 'rural',     -- Humane Labs and Research
    JAIL = 'rural',       -- Bolingbroke Penitentiary
    LAGO = 'rural',       -- Lago Zancudo
    NCHU = 'rural',       -- North Chumash
    NOOSE = 'rural',      -- N.O.O.S.E
    PALHIGH = 'rural',    -- Palomino Highlands
    PALMPOW = 'rural',    -- Palmer-Taylor Power Station
    RTRAK = 'rural',      -- Redwood Lights Track
    SANAND = 'rural',     -- San Andreas
    SANCHIA = 'rural',    -- San Chianski Mountain Range
    TONGVAH = 'rural',    -- Tongva Hills
    TONGVAV = 'rural',    -- Tongva Valley
    WINDF = 'rural',      -- Ron Alternates Wind Farm
    ZANCUDO = 'rural',    -- Zancudo River
    ZQ_UAR = 'rural',     -- Davis Quartz

    -- ========================================================================
    -- REMOTE / MOUNTAIN / WILDERNESS / WATER
    -- ========================================================================
    ALAMO = 'wilderness', -- Alamo Sea
    BRADP = 'wilderness', -- Braddock Pass
    BRADT = 'wilderness', -- Braddock Tunnel
    CANNY = 'wilderness', -- Raton Canyon
    CCREAK = 'wilderness',-- Cassidy Creek
    CHIL = 'wilderness',  -- Vinewood Hills
    CMSW = 'wilderness',  -- Chiliad Mountain State Wilderness
    ELGORL = 'wilderness',-- El Gordo Lighthouse
    LACT = 'wilderness',  -- Land Act Reservoir
    LDAM = 'wilderness',  -- Land Act Dam
    MTCHIL = 'wilderness',-- Mount Chiliad
    MTGORDO = 'wilderness',-- Mount Gordo
    MTJOSE = 'wilderness',-- Mount Josiah
    OCEANA = 'beach',    -- Pacific Ocean / coastal sand strips
    PALCOV = 'wilderness',-- Paleto Cove
    PALFOR = 'wilderness',-- Paleto Forest
    PROCOB = 'beach',    -- Procopio Beach
    PROL = 'wilderness',  -- Prologue / North Yankton
    TATAMO = 'wilderness',-- Tataviam Mountains
}


-- ============================================================================
-- 6. SAFETY LIMITS / ADVANCED TUNING
-- ============================================================================

-- Final densities are clamped between these values after every modifier has
-- been applied. Most servers should leave these at 0.0 and 1.0.
Config.Minimums = {
    peds = 0.0,
    traffic = 0.0,
    parked = 0.0,
}

Config.Maximums = {
    peds = 1.0,
    traffic = 1.0,
    parked = 1.0,
}

-- Additional multiplier specifically for GTA's random moving vehicles.
-- Leave at 1.0 unless you deliberately want random traffic below the normal
-- moving-traffic target.
Config.VehicleMultipliers = {
    randomVehicles = 1.0,
}

-- ============================================================================
-- 7. DEBUG / TUNING TOOLS
-- ============================================================================
--
-- Debug is disabled by default for a public/production server.
-- Enable it while tuning to display the Population Monitor UI.
--
-- The UI shows:
--   BASE     = active TimeProfile value
--   TARGET   = final value after area/zone modifiers
--   APPLIED  = exact value bs-population sends to GTA every frame
--   OBSERVED = nearby entity counts for real-world verification
--
-- GTA does not expose a getter for its internal density multipliers, so the
-- script cannot read a separate "actual GTA density" value back from the game.

Config.Debug = false
Config.DebugCommand = 'popdebug'
Config.DebugKey = 'F7'

-- Text shown at the top of the debug UI. Change this to your server/dev name.
Config.DebugBrand = 'SERVER DEV'
Config.DebugTitle = 'Population Monitor'

-- Radius and update speed used only for the nearby entity counters.
Config.DebugSampleRadius = 100.0
Config.DebugSampleInterval = 1000
