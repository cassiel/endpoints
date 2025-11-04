-- -*- lua-indent-level: 4; -*-

--[[
    Support for MIDI ports from script's parameter setup
    (rather than using indices and the global port list).
    The script is expected to provide device "role" keys x names
    (such as "grid" x "Grid input", "daw" x "To DAW" -
    or device identifiers like "wavestate", "modwave" which
    make sense to the script).

    Argument: table of:
        key -> name * (msg callback)

    Result returned: table of:
        key -> (MIDI endpoint index, for transmission)
        NB: this returned table is mutable, if params change!

    Side-effect: parameters registered in PARAMETERS page.
]]

local function setup_midi(callbacks)
    --[[
        Set up MIDI endpoints via virtual ports. We're building a map
        from application keys to virtual port indices; it's possible
        to swap other devices into this ports after the fact.
    ]]

    -- Result: map from keys to vport indices (mutable!):
    local keys_to_ids = { }

    -- Arrays indexed by vport:
    local devices = { }
    local vnames = { }

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
            vnames,
            "port "..i..": "..util.trim_string_to_width(devices[i].name, 40)
        )

        --[[
            Event handling: given an id, callback if a key maps to that id.
            Fiddly because we might have the same id as a target for multiple
            ids (especially when manually configuring the script) so we
            can't just maintain a reverse table. We do it the icky way and
            iterate through the original.
        ]]
        devices[i].event =
            function (x)
                print("PORT [" .. i .. "]")
                -- This is a filter: we see input from all active ports,
                -- but have to select according to our param. We're doing
                -- it by index, not actual device:
                for key, id in pairs(keys_to_ids) do
                    if i == id then
                        callbacks[key].event(x)
                    end
                end
            end
    end

    local count = 1
    for k, v in pairs(callbacks) do
        keys_to_ids[k] = count
        ids_to_keys[count] = k
        params:add_option(k, v.name, vnames, count)
        params:set_action(
            k,
            function(n)
                keys_to_ids[k] = n
            end
        )
        count = count + 1
    end

    return keys_to_ids
end

local function setup(header, callbacks)
    params:add_separator(header)
    setup_midi(callbacks)
end

return {
    setup = setup
}
