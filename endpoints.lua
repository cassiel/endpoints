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

function init()
    --[[
        We have three app-level endpoints for MIDI which
        we're calling "keys", "pads" and "knobs". We
        indicate MIDI activity from them (we aren't
        yet sending anything in this demo).
    ]]

    local callbacks = {
        keys={
            name="Keys in",
            event=function(x) print("keys:"); tab.print(x) end
        },
        pads={
            name="Pads in",
            event=function(x) print("pads:"); tab.print(x) end
        },
        knobs={
            name="Knobs in",
            event=function(x) print("knobs:"); tab.print(x) end
        },
    }

    endpoints = ports.setup_midi("Endpoints", callbacks)
end

function redraw()
    screen.clear()

    local y = 10

    for k, v in pairs(endpoints) do
        screen.move(10, y)
        screen.text(k .. ": " .. v.name)
    end

    screen.update()
end
