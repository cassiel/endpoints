-- -*- lua-indent-level: 4; -*-
-- Unit testing.

local lu = require "luaunit"

local G = { }

local function mock_MIDI()
    G.midi_log = { }

    G.midi = {
        devices = {
            -- 1:
            {
                note_on = function (self, p, v, ch)
                    table.insert(G.midi_log, {dev=1, type="+", p=p, v=v, ch=ch})
                end,

                note_off = function (self, p, v, ch)
                    table.insert(G.midi_log, {dev=1, type="-", p=p, v=v, ch=ch})
                end
            }
        },

        mf_target = "mf"        -- In the live code this is a numeric index.
    }
end
