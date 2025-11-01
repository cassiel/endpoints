--[[
    Support for MIDI ports from script's parameter setup
    (rather than using indices and the global port list).
    The script will provide device "role" keys x names
    (such as "Grid input", "To DAW").
    
    Argument: table of:
        key: name * (msg callback)
    
    Result returned: table of:
        key: (MIDI endpoint, for transmission)
        
    And: parameters registered in PARAMETERS page.
]]

local G = require "printer-jam-norns.lib.global"
local spectra = require "printer-jam-norns.lib.spectra"
local visuals = require "printer-jam-norns.lib.visuals"

local function setup_midi(callback_tab)
    --[[
        Set up MIDI endpoints via virtual ports (so the devices
        here might not actually be connected, and/or a script
        reload might be needed).
    ]]

    -- Arrays indexed by vport:
    local devices = { }
    local names = { }

    for i = 1, #midi.vports do
        devices[i] = midi.connect(i)
        -- The trim is mainly for the parameter page. (Perhaps we should
        -- have a second table with longer names for the script page.)
        table.insert(
            names,
            "port "..i..": "..util.trim_string_to_width(devices[i].name, 40)
        )

        devices[i].event =
            -- Event is in: work out which of our app-level
            -- handlers it goes to:
            function (x)
                print("PORT [" .. i .. "]")
                if i == G.midi.mf_target then
                    local msg = midi.to_msg(x)
                    -- callbacks.process_note(msg.note, (msg.type == "note_on"))
                    callbacks.process_note(msg.note, ((msg.type == "note_on") and 127 or 0), msg.ch)
                end

                tab.print(midi.to_msg(x))
            end
    end

    params:add_option("mf", "MIDI Fighter", names, 1)
    params:set_action("mf", function(x) G.midi.mf_target = x end)

    params:add_option("daw", "DAW", names, 2)
    params:set_action("daw", function(x) G.midi.daw_target = x end)

    G.midi = {
        devices = devices,
        names = names,
        mf_target = 1,          -- Hope that fires before the param callback?
        daw_target = 2
    }
end

local function setup(header, callbacks)
    tab.print(callbacks)
    params:add_separator(header)
    setup_midi(callbacks)
end

return {
    setup = setup
}
