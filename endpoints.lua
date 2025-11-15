-- ## endpoints
-- Utility for presenting MIDI,
-- grid and arc endpoints as
-- params.
-- (MIDI only at present.)
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
local endpoints = nil

--[[
    A table which specifies which activity "LEDs"
    are on because of MIDI input. No entry == off.
]]
local leds_on = { }

local function led_level(key)
    -- print("leds_on[" .. key .. "] = " .. (leds_on[key] and "T" or "F"))
    return (leds_on[key] and 15 or 1)
end

local coroutine_ids = { }

--[[
    "Fire" an LED: turn it on for a fraction of a second.
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

local config = {
    keys={
        name="Keys in",
        event=function(x) print("keys:"); tab.print(x); fire_led("keys") end
    },
    pads={
        name="Pads in",
        event=function(x) print("pads:"); tab.print(x); fire_led("pads") end
    },
    knobs={
        name="Knobs in",
        event=function(x) print("knobs:"); tab.print(x); fire_led("knobs") end
    }
}

function init()
    --[[
        We have three app-level endpoints for MIDI which
        we're calling "keys", "pads" and "knobs". We
        indicate MIDI activity from them (we aren't
        yet sending anything in this demo).
    ]]

    endpoints = ports.setup_midi("Endpoints", config)
end

local function sorted_keys(t)
    local result = { }
    for k, _ in pairs(t) do
        table.insert(result, k)
    end
    table.sort(result)
    return result
end

function redraw()
    screen.clear()

    local y = 10

    --[[
        Let's sort the keys, mainly for consistency. We're showing
        the long names, which themselves might not be in order.
    ]]
    for i, k in ipairs(sorted_keys(endpoints)) do
        local v = endpoints[k]
        if not k:find("_", 1, true) then
            screen.level(led_level(k))
            screen.rect(3, y - 5, 4, 13)
            screen.fill()

            local id =  endpoints._ids[k]
            screen.level(3)
            screen.move(10, y)
            screen.text(config[k].name)
            -- print(">>> " .. config[k].name .. ": " .. v.name .. " [" .. id .. "]")
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
