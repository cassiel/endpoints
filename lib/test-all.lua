-- -*- lua-indent-level: 4; -*-
-- Unit testing.

local lu = require "luaunit"
local inspect = require "inspect"

local midi_ports = require "endpoints.lib.midi-ports"

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

    midi = { }
    midi.vports = { "FOO" }

    function midi.connect(i)
        return {name="MyName_" .. i}
    end

    util = { }

    function util.trim_string_to_width(str, w)
        lu.assertNotNil(str)
        return str
    end

    params = { }

    -- TODO: in the docs this is id * label.
    function params:add_separator(header)
        table.insert(log, "SEP " .. header)
    end

    function params:add_option(id, name, options, default)
        table.insert(log, "OPT " .. id .. " " .. name .. " " .. inspect.inspect(options) .. " " .. default)
    end

    function params:set_action(id, callback)
        table.insert(log, "ACTION " .. id)
    end
end

function test_Endpoint:tearDown()
end

function test_Endpoint:testGo()
    local result = midi_ports.setup("TestApp", {
        port_a = {
            name="Port A",
            event=function(x)
                table.insert(self.log, "EV_A")
            end
        },
        port_b = {
            name="Port B",
            event=function(x)
                table.insert(self.log, "EV_B")
            end
        }
    })

    lu.assertEquals(self.log, {"BLAH"})
    lu.assertEquals(result, {port_a=1, port_b=2})
end

runner = lu.LuaUnit.new()
runner:runSuite("--pattern", ".*" .. "%." .. ".*", "--verbose", "--failure")
