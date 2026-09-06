# bs-population

Dynamic ambient population control for FiveM. `bs-population` changes GTA V's naturally generated pedestrians, moving traffic, and parked vehicles according to time of day and location.

## About

bs-population is a dynamic population controller for FiveM that adjusts ambient pedestrian and vehicle density based on both time of day and player location.

Rather than applying one population setting across the entire map, each player experiences population levels appropriate to where they are. For example, a player standing on Vinewood Boulevard around midnight can experience a busy nightlife population, while another player in Strawberry at exactly the same time can experience significantly quieter streets.

Population naturally changes throughout the day, including morning and afternoon peak traffic, daytime activity, nightlife, late-night decline, and near-empty early-morning streets.

## Features
- Time-based population — Different densities throughout the in-game day.  
- Location-aware population — Population varies between GTA V zones and area types.  
- Peak-hour traffic — Increased traffic during morning and afternoon commuting periods.  
- Nightlife activity — Selected areas remain busier into the night.  
- Dead hours — Near-zero pedestrian activity and heavily reduced traffic during the quietest hours.  
- Independent density control — Separate control of pedestrians, traffic and parked vehicles.  
- Smooth transitions — Population changes gradually between normal profiles.  
- Full GTA V zone mapping — Standard GTA V zones are configured out of the box.  
- Server-owner friendly configuration — Easily customise profiles, zones, area types and density levels.  
- Built-in debug monitor — View zones, profiles, target/applied densities and nearby population in real time.  
- Integration exports — Other resources can access current or zone-specific population data.  
- Standalone & lightweight — No framework, database or external assets required.  

## Installation

1. Place the `bs-population` folder in your server resources directory.
2. Add `ensure bs-population` to `server.cfg`.
3. Restart the resource/server.
4. Tune `config.lua` for your community.

No SQL, framework, target system, or external dependency is required.

## Configuration

Most server owners only need to edit `config.lua`.

### Time profiles

`Config.TimeProfiles` defines the base population for each time period. Density values normally range from `0.0` to `1.0`.

- `peds` - ambient pedestrians
- `traffic` - moving ambient traffic
- `parked` - parked ambient vehicles
- `peakHour = true` - enables peak-hour traffic modifiers
- `nightlife = true` - enables nightlife modifiers

Make sure your time profiles collectively cover the full 24-hour day.

### Area types

`Config.AreaTypes` controls how strongly each type of region scales the active time profile. By default the resource includes:

- `city`
- `suburbs`
- `ruralTown`
- `rural`
- `wilderness`

Example: a time profile with `traffic = 0.50` in an area with `traffic = 0.40` produces a final traffic target of `0.20`.

### Zone mapping

`Config.ZoneTypes` maps GTA's short zone codes to an area type. Enable the debug UI and stand in an area to see its current GTA zone code.

Any zone not listed uses `Config.DefaultAreaType`.

### Nightlife and peak-hour boosts

`Config.NightlifeZones` and `Config.PeakTrafficZones` are optional extra multipliers for specific locations. Remove an entry if you do not want that location to receive a special boost.

## Debug Monitor

Debug is disabled by default for production servers.

Set:

```lua
Config.Debug = true
```

Then use the configured command/key (default `/popdebug` or `F7`).

The monitor displays:

- **BASE** - the active time-profile density
- **TARGET** - the final calculated density after area/zone modifiers
- **APPLIED** - the exact value `bs-population` passes into GTA's frame-scoped density natives
- **OBSERVED NEARBY** - nearby peds, vehicles, and stopped vehicles
- **APPLY LOOP** - confirms the frame application thread is still running

The debug brand/title can be changed with `Config.DebugBrand` and `Config.DebugTitle`.

## Important GTA/FiveM Behaviour

Density natives are frame-scoped, so `bs-population` applies them every rendered frame.

Lowering density does not instantly delete entities that already exist. It reduces new ambient spawning; existing entities disappear naturally as players move away and GTA cleans them up.

GTA/FiveM exposes density setters but not a reliable getter for the internal population multiplier. For that reason the debug UI shows the exact value sent by this resource plus nearby entity counts rather than pretending it can read a separate engine value back.

### Conflicts with other population resources

Do not run multiple resources that continuously call GTA's population-density natives unless you know how they interact. Another resource applying its own density values every frame can override or fight `bs-population`.

Typical natives involved include pedestrian density, scenario pedestrian density, vehicle density, random vehicle density, and parked vehicle density.

## Support/Tuning Tip

If population does not look correct:

1. Enable the debug monitor.
2. Confirm **APPLY LOOP** says `RUNNING` and the frame counter increases.
3. Check that **TARGET** matches your expected profile/area settings.
4. Confirm **APPLIED** moves toward **TARGET**.
5. Drive into a new area and allow existing entities time to clean up.
6. Check for another resource controlling population density.

## Version

1.5.0

## GTA zone coverage

`Config.ZoneTypes` ships with the standard GTA V short zone codes returned by `GetNameOfZone()`. The mapping is based on Cfx.re's GTA V zone reference. Custom maps can still return unexpected codes; when debug is enabled the monitor will show `UNMAPPED` and the resource will use `Config.DefaultAreaType`.

Do not invent street-based codes such as `ROUTE68`: GTA zone codes describe map zones, not road names.

## Need help?

You can join our development Discord here: https://discord.gg/dw5KbvB9MJ
