-- File: Cockpit/Scripts/LuaToolsPlugin/KeybindBuilder.lua
-- MIT License (c) 2025 OpenFlight Community

------------------------------------------------------------
-- KeybindBlockBuilder
--  - Create once with the destination table (e.g. res.keyCommands)
--  - Per-call categories are REQUIRED
--  - No dependency on global `join` (falls back if present)
------------------------------------------------------------

local KeybindBlockBuilder = {}
KeybindBlockBuilder.__index = KeybindBlockBuilder

-- Allow localization fallback if `_` is not defined in this scope
local L = _ or function(s) return s end

-- Normalize categories: accept string or {strings}; wrap each with L()
local function norm_categories(cats)
    assert(cats ~= nil, "categories are required per keybind (string or {strings})")
    if type(cats) == "string" then return { L(cats) } end
    local out = {}
    for i = 1, #cats do out[i] = L(cats[i]) end
    return out
end

-- Append all rows to target; prefer global `join` if available
local function append_all(target, rows)
    if type(join) == "function" then
        -- Use engine-provided join if present
        join(target, rows)
        return
    end
    -- Manual append (works everywhere)
    for i = 1, #rows do
        target[#target + 1] = rows[i]
    end
end

--- Constructor
--- @param targetTable table The table to append rows into (e.g., res.keyCommands)
--- @return KeybindBlockBuilder
function KeybindBlockBuilder:new(targetTable)
    local self = setmetatable({}, KeybindBlockBuilder)
    assert(type(targetTable) == "table", "KeybindBlockBuilder:new requires a target table")
    self.target = targetTable
    return self
end

-- Internal: build the 2-pos rows, optionally including a toggle row
local function build_2pos_rows(swCmd, baseName, categories, toggleCmd)
    local cat  = norm_categories(categories)
    local base = baseName or "Unnamed"

    local rows = {
        {
            down = swCmd, up = swCmd,
            value_down = 1, value_up = 0,
            name = L(string.format("%s - ON <> OFF", base)),
            category = cat,
        },
        {
            down = swCmd,
            value_down = 1, value_up = 0,
            name = L(string.format("%s - ON", base)),
            category = cat,
        },
        {
            down = swCmd,
            value_down = 0, value_up = 1,
            name = L(string.format("%s - OFF", base)),
            category = cat,
        },
    }

    if toggleCmd then
        table.insert(rows, 2, {
            down = toggleCmd,
            name = L(string.format("%s - TOGGLE", base)),
            category = cat,
        })
    end

    return rows
end

--- Add a 2-position switch block (with optional toggle)
--- Yields: ON<>OFF, (optional) TOGGLE, ON, OFF
--- @param swCmd number               Keys.<...> switch command
--- @param baseName string            Display base, e.g. "Beacon Lights"
--- @param categories string|string[] Per-keybind categories (required)
--- @param toggleCmd number|nil       Keys.<...> toggle command (nil/omit = no toggle row)
function KeybindBlockBuilder:add2Pos(swCmd, baseName, categories, toggleCmd)
    local rows = build_2pos_rows(swCmd, baseName, categories, toggleCmd)
    append_all(self.target, rows)
end

--- Add arbitrary rows (escape hatch)
--- @param rows table[] Array of keybind rows
function KeybindBlockBuilder:add(rows)
    append_all(self.target, rows)
end

return KeybindBlockBuilder
