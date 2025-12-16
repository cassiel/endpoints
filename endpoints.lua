-- ## endpoints
-- Utility for presenting MIDI,
-- grid and arc endpoints as
-- params.
-- Enc 1 = page (MIDI/Grids/Arcs).
--
-- Nick Rothwell, nick@cassiel.com.

-- Development: purge lib on reload:

for k, _ in pairs(package.loaded) do
    if k:find("endpoints.", 1, true) == 1 then
        print("purge " .. k)
        package.loaded[k] = nil
    end
end

local ports = require "endpoints.lib.endpoints"
local UI = require "ui"

-- endpoints will eventually be {midi=xxx, arcs=xxx, grids=xxx}
local endpoints = { }

local pageNames = {"MIDI", "Grids", "Arcs"}
local pages = UI.Pages.new(1, #pageNames)
local devGroupNames = {"midi", "grids", "arcs"}     -- See calls in init().

--[[
    A table which specifies which activity "LEDs"
    are on because of device input. No entry == off.
    These are common across all display pages.
]]

local leds_on = { }

local function led_level(key)
    -- print("leds_on[" .. key .. "] = " .. (leds_on[key] and "T" or "F"))
    return (leds_on[key] and 15 or 1)
end

local coroutine_ids = { }

--[[
    "Fire" an LED: turn it on for a fraction of a second.
    (It might be an LED that's not on the current page,
    but we redraw anyway.)
]]

local function fire_led(key)
    -- Kill any existing "off"-timer:
    local cr = coroutine_ids[key]
    if cr then clock.cancel(cr) end

    -- Timer for the "off":
    coroutine_ids[key] = clock.run(
        function()
            leds_on[key] = true
            redraw()
            clock.sleep(0.1)
            leds_on[key] = false
            redraw()
        end
    )
end

--[[
    Configuration for MIDI input: just flash the
    on-screen LED blocks.
]]

local function midi_config(id, name)
    return {
        name=name,
        event=function(_) fire_led(id) end
    }
end

--[[
    Configuration for grids (respond to "key"
    by lighting on-device LED).
]]

local function grid_config(id, name)
    return {
        name=name,
        key=function (x, y, state)
            fire_led(id)
            if endpoints.grids then
                local dev = endpoints.grids[id]
                dev:led(x, y, ((state == 1) and 15 or 0))
                dev:refresh()
            else
                print("no endpoint for " .. id)
            end
        end
    }
end

--[[
    Configuration for arc.
]]

local function arc_config(id, name)
    return {
        name=name,
        delta=function (n, d) fire_led(id) end,
        key=function (n, z) fire_led(id) end
    }
end

local config = {
    --[[
        For MIDI we have three app-level endpoints for which
        we're indexing as "keys", "pads" and "knobs". We
        indicate MIDI activity from them (we aren't
        yet sending anything in this demo).
        
        For grids we have m64 and m128: we respond to presses
        by lighting the buttons.
        
        We have a single arc.
    ]]

    midi={
        keys=midi_config("keys", "Keyboard"),
        pads=midi_config("pads", "Drum Pads"),
        knobs=midi_config("knobs", "Controller Box")
    },
    grids={
        m64=grid_config("m64", "Grid 64"),
        m128=grid_config("m128", "Grid 128")
    },
    arcs={
        arc=arc_config("arc", "My Arc")
    }
}

function init()
    endpoints.midi = ports.setup_midi("Endpoints", config.midi)
    endpoints.grids = ports.setup_grids("Endpoints", config.grids)
    endpoints.arcs = ports.setup_arcs("Endpoints", config.arcs)

    params:default()        --  Recall default setup.
end

local function sorted_keys(t)
    local result = { }
    for k, _ in pairs(t) do
        table.insert(result, k)
    end
    table.sort(result)
    return result
end

--[[
    We only do encoder 1, and only for page selection.
]]

function enc(n, d)
    if n == 1 then
        pages:set_index_delta(d, false)
        redraw()
    end
end

function redraw()
    screen.clear()
    pages:redraw()
    local title = pageNames[pages.index]
    screen.move(128, 5)
    screen.level(15)
    screen.text_right(title)
    
    local groupName = devGroupNames[pages.index]

    local y = 15

    --[[
        Let's sort the keys, mainly for consistency. We're showing
        the long names, which themselves might not be in order.
    ]]

    for i, k in ipairs(sorted_keys(endpoints[groupName])) do
        local v = endpoints[groupName][k]
        if not k:find("_", 1, true) then    -- Ignore "_ids" etc.
            screen.level(led_level(k))
            screen.rect(3, y - 5, 4, 13)
            screen.fill()

            local id =  endpoints[groupName]._ids[k]
            screen.level(3)
            screen.move(10, y)
            screen.text(config[groupName][k].name)
            -- print(">>> " .. config.midi[k].name .. ": " .. v.name .. " [" .. id .. "]")
            y = y + 8

            screen.move(10, y)
            screen.level(5)
            screen.text("[" .. id .. "]")
            screen.move(25, y)
            screen.level(15)
            screen.text(v.name)
            y = y + 12
        end
    end

    screen.update()
end
