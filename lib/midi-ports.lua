--[[
    Support for MIDI ports from script's parameter setup
    (rather than using indices and the global port list).
    The script is expected to provide device "role" keys x names
    (such as "grid" x "Grid input", "daw" x "To DAW" -
    or device identifiers like "wavestate", "modwave" which
    make sense to the script).
    
    Argument: table of:
        key: name * (msg callback)
    
    Result returned: table of:
        key: (MIDI endpoint, for transmission)
        
    And: parameters registered in PARAMETERS page.
]]

local function setup_midi(callback_tab)
    --[[
        Set up MIDI endpoints via virtual ports. We're building a map
        from application keys to virtual port indices; it's possible
        to swap other devices into this ports after the fact.
    ]]

    -- Arrays indexed by vport:
    local devices = { }
    local names = { }

    for i = 1, #midi.vports do
        --[[
            The connection here is to the device endpoint, unrelated
            to the index i. The device can be reattached to another
            vport and will still work at its different index. Devices
            not connected at this time won't show up later.
        ]]
        devices[i] = midi.connect(i)
        --[[
            The trim is mainly for the parameter page. (Perhaps we should
            have a second table with longer names for the script page.)
            The names don't update if system device assignments change:
            the script will need to be reloaded.
        ]]
        table.insert(
            names,
            "port "..i..": "..util.trim_string_to_width(devices[i].name, 40)
        )

        devices[i].event =
            -- Event is in: work out which of our app-level
            -- handlers it goes to:
            function (x)
                print("PORT [" .. i .. "]")
                -- This is a filter: we see input from all active ports,
                -- but have to select according to our param. We're doing
                -- it by index, not actual device:
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
    params:add_separator(header)
    setup_midi(callbacks)
end

return {
    setup = setup
}
