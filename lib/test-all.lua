-- -*- lua-indent-level: 4; -*-
-- Unit testing.

local lu = require "luaunit"

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

    function params:add_separator(header)
        table.insert(log, "SEP " .. header)
    end
end

function test_Endpoint:tearDown()
end

function test_Endpoint:testGo()
    midi_ports.setup("TestApp", {
        port_a = {
            name="Port A",
            event=function(x)
                table.insert(self.log, "EV_A")
            end
        },
        port_b = {
            name="Port B",
            event=function(x)
                table.insert(self.log, "EV_A")
            end
        }
    })

    lu.assertEquals(self.log, {A=19})
end

runner = lu.LuaUnit.new()
runner:runSuite("--pattern", ".*" .. "%." .. ".*", "--verbose", "--failure")
