-- ## endpoints
-- Utility for presenting MIDI,
-- grid and arc endpoints as params.
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

local midi_ports = require "endpoints.lib.midi-ports"

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

    midi_ports.setup("Endpoints", callbacks)
end

function redraw()
end
