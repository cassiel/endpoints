-- -*- lua-indent-level: 4; -*-

--[[
    Support for MIDI, grid and arc ports from script's parameter setup
    (rather than using indices and the global port list).
    The script is expected to provide device "role" keys x names
    (such as "grid" x "Grid input", "daw" x "To DAW" -
    or device keys like "wavestate", "modwave" which
    make sense to the script).

    Argument: table of:
        key -> name * (msg callback)

    Result returned: table of:
        key -> (MIDI endpoint index, for transmission)
        NB: this returned table is mutable, if params change!

    Side-effect: parameters registered in PARAMETERS page.
]]

--[[
    We support MIDI devices, grids and arcs as three configurations,
    but functionally these differ only in the name of the built-in
    table of virtual devices, and the names of the callbacks.

    dev_table: "midi", "grid", "arc".
    callback_fns: ["event"], ["key"], ["key, "delta"].
]]

local function setup_devices(dev_table, callback_fns, callbacks)
    --[[
        Set up MIDI endpoints via virtual ports. We're building a map
        from application keys to virtual port indices; it's possible
        to swap other devices into these ports after the fact.
    ]]

    --[[
        Result: map from keys to vport indices (mutable!):
    ]]
    local keys_to_ids = { }

    --[[
        Similar: map keys directly to devices (we return this). There's
        no intermediate processing here, like there needs to be with
        event handers which would be much harder to dynamically patch.
    ]]
    local keys_to_devices = { }

    -- Arrays indexed by vport:
    local devices = { }
    local vnames = { }

    for i = 1, #dev_table.vports do
        --[[
            The result of [midi/grid/arc].connect() still seems to be related to
            virtual slot: swap in a different "device" in system settings
            and that new device kicks in.
        ]]
        devices[i] = dev_table.connect(i)

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
            keys (especially when manually configuring the script) so we
            can't just maintain a reverse table. We do it by iterating
            through the original.

            Depending on the type of device we're configuring (midi/grid/arc)
            the callback field is different. Arcs have two callbacks.
        ]]
        for _, cb_name in ipairs(callback_fns) do
            devices[i][cb_name] =
                --[[
                    Is there a better way of doing varargs? Grid/arc callbacks
                    take two arguments.
                ]]
                function (a, b, c) -- !!!!!!! varargs!
                    -- print("PORT [" .. i .. "]")
                    --[[
                        This is a filter: we see input from all active ports,
                        but have to select according to our param. We may
                        get multiple matches.
                    ]]
                    for key, id in pairs(keys_to_ids) do
                        if i == id then
                            local f = callbacks[key][cb_name]
                            -- Ignore if we've not provided a callback:
                            if f then f(a, b, c) end
                        end
                    end
                end
        end
    end

    --[[
        When establishing the params we force alphabetical order.
        We can't rely on the key order in callbacks anyway,
        and we need consistency for our unit tests(!).
    ]]
    local keys = { }
    for k, _ in pairs(callbacks) do
        table.insert(keys, k)
    end
    table.sort(keys)

    for i, k in ipairs(keys) do
        keys_to_ids[k] = i
        keys_to_devices[k] = devices[i]
        params:add_option(k, callbacks[k].name, vnames, i)
        params:set_action(
            k,
            function(n)
                keys_to_ids[k] = n
                keys_to_devices[k] = devices[n]
            end
        )
    end

    -- This one helps with unit tests(!):
    keys_to_devices._ids = keys_to_ids
    return keys_to_devices
end

local function setup(header, dev_table, callback_fns, callbacks)
    params:add_separator(header)
    -- return setup_midi(callbacks)
    return setup_devices(dev_table, callback_fns, callbacks)
end

return {
    setup_midi =
        function (header, callbacks)
            return setup(header .. " [MIDI]", midi, {"event"}, callbacks)
        end,
    setup_grids =
        function (header, callbacks)
            return setup(header .. " [grids]", grid, {"key"}, callbacks)
        end,
    setup_arcs =
        function (header, callbacks)
            return setup(header .. " [arcs]", arc, {"key", "delta"}, callbacks)
        end
}
