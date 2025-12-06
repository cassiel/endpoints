-- -*- lua-indent-level: 4; -*-
-- Unit testing.

local lu = require "luaunit"
local inspect = require "inspect"

local ports = require "endpoints.lib.endpoints"

test_Start = { }

function test_Start.testStart()
    lu.assertEquals(1, 1)
    lu.assertEquals({1, 2}, {1, 2})
    lu.assertEquals({A=1, B=2}, {B=2, A=1})
end

test_Endpoint = { }

function test_Endpoint:setUp()
    self.log = { }
    local log = self.log

    --[[
        Mock out the MIDI library:
    ]]
    midi = { }

    --[[
        All remembered devices. It's not clear that these
        values are ever examined in user code - we just
        do a `midi.connect()` based on index.
    ]]
    midi.vports = { "...", "...", "..." }
    midi.devices = { }

    function midi.connect(i)
        midi.devices[i] =
            midi.devices[i] or {
                name="midi.connected(" .. i .. ")",
                send=function (x)
                    table.insert(log, "midi.send {" .. table.concat(x, ", ") .. "}")
                end
            }
        return midi.devices[i]
    end

    util = { }

    function util.trim_string_to_width(str, w)
        lu.assertNotNil(str)
        return str
    end

    params = { }

    -- TODO: in the docs this is id * label.
    function params:add_separator(header)
        table.insert(log, "add_separator " .. header)
    end

    function params:add_option(id, name, options, default)
        table.insert(log, "add_option " .. id .. " " .. name .. " " .. inspect.inspect(options) .. " " .. default)
    end

    function params:set_action(id, callback)
        table.insert(log, "set_action " .. id)

        self.actions = self.actions or { }
        self.actions[id] = callback
    end
end

function test_Endpoint:tearDown()
end

function test_Endpoint:testSetup()
    local result = ports.setup_midi("TestApp", {
        port_a = {
            name="Port A",
            event=function(x)
                table.insert(self.log, "event.A")
            end
        },
        port_z = {
            name="Port Z",
            event=function(x)
                table.insert(self.log, "event.Z")
            end
        },
        port_b = {
            name="Port B",
            event=function(x)
                table.insert(self.log, "event.B")
            end
        }
    })

    --[[
        Here we're expecting user ports in order - we enforce
        that when we scan.
    ]]
    lu.assertEquals(
        self.log,
        {
            "add_separator TestApp [MIDI]",
            'add_option port_a Port A { "port 1: midi.connected(1)", "port 2: midi.connected(2)", "port 3: midi.connected(3)" } 1',
            "set_action port_a",
            'add_option port_b Port B { "port 1: midi.connected(1)", "port 2: midi.connected(2)", "port 3: midi.connected(3)" } 2',
            "set_action port_b",
            'add_option port_z Port Z { "port 1: midi.connected(1)", "port 2: midi.connected(2)", "port 3: midi.connected(3)" } 3',
            "set_action port_z"
        }
    )
    lu.assertEquals(result._ids, {port_a=1, port_b=2, port_z=3})
end

function test_Endpoint:testParamChange()
    local result = ports.setup_midi("TestApp", {
                                        port_a = {
                                            name="Port A",
                                            event=function(x)
                                                table.insert(self.log, "event.A")
                                            end
                                        }
    })

    local callback = params.actions.port_a
    callback(99)

    lu.assertEquals(result._ids, {port_a=99})
end

function test_Endpoint:testEvent()
    ports.setup_midi("TestApp", {
                         port_a = {
                             name="Port A",
                             event=function(x)
                                 table.insert(self.log, "event.A: " .. x)
                             end
                         }
    })

    -- Flip port_a to virtual slot 3:
    params.actions.port_a(3)

    dev = midi.connect(3)
    dev.event("MIDI-IN")

    lu.assertEquals(
        self.log,
        {
            "add_separator TestApp [MIDI]",
            'add_option port_a Port A { "port 1: midi.connected(1)", "port 2: midi.connected(2)", "port 3: midi.connected(3)" } 1',
            "set_action port_a",
            "event.A: MIDI-IN"
        }
    )
end

function test_Endpoint:testTransmitNoParamChange()
    m = ports.setup_midi(
        "TestApp",
        {
            port_a = {
                name="Port A",
                event=function(x)
                    table.insert(self.log, "UNEXPECTED")
                end
            }
        }
    )

    dev = midi.connect(1)
    m.port_a.send{7, 8, 9}

    lu.assertEquals(
        self.log,
        {
            "add_separator TestApp [MIDI]",
            'add_option port_a Port A { "port 1: midi.connected(1)", "port 2: midi.connected(2)", "port 3: midi.connected(3)" } 1',
            "set_action port_a",
            "midi.send {7, 8, 9}"
        }
    )

end

function test_Endpoint:testTransmitWithParamChange()
    m = ports.setup_midi(
        "TestApp",
        {
            port_a = {
                name="Port A",
                event=function(x)
                    table.insert(self.log, "UNEXPECTED")
                end
            }
        }
    )

    -- Flip port_a to virtual slot 3:
    params.actions.port_a(3)

    dev = midi.connect(3)
    m.port_a.send{7, 8, 9}

    lu.assertEquals(
        self.log,
        {
            "add_separator TestApp [MIDI]",
            'add_option port_a Port A { "port 1: midi.connected(1)", "port 2: midi.connected(2)", "port 3: midi.connected(3)" } 1',
            "set_action port_a",
            "midi.send {7, 8, 9}"
        }
    )
end

test_ArcGroup = { }

function test_ArcGroup:setUp()

end

function test_ArcGroup:tearDown()
end

function test_ArcGroup:testSetup()
    local result = ports.setup_arcs(
        "ArcApp",
        {
            arc_port = {
                name="Arc 4",
                key=function (n, z)
                    table.insert(self.log, "key n=" .. n .. " z=" .. z)
                end,
                delta=function (n, d)
                    table.insert(self.log, "key n=" .. n .. " d=" .. d)
                end
            }
    })

    lu.assertEquals(
        self.log,
        {
            "add_separator ArcApp [arcs]",
            'add_option arc_port Arc 4 { "port 1: arc.connected(1)" } 1',
            "set_action arc_port"
        }
    )
    lu.assertEquals(result._ids, {arc_port=1})

end

runner = lu.LuaUnit.new()
runner:runSuite("--pattern", ".*" .. "%." .. ".*", "--verbose", "--failure")
