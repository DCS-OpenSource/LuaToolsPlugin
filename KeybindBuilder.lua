-- MIT License
-- 
-- Copyright (c) 2025 OpenFlight Community
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

---@class KeybindBlockBuilder
---@field target table Destination table to append keybind rows into (e.g., res.keyCommands)
local KeybindBlockBuilder = {}
KeybindBlockBuilder.__index = KeybindBlockBuilder

local L = _ or function(s) return s end

-- Normalize categories: accept string or {strings}; wrap each with L()
local function norm_categories(cats)
    assert(cats ~= nil, "categories are required per keybind (string or {strings})")
    if type(cats) == "string" then return { L(cats) } end
    local out = {}
    for i = 1, #cats do out[i] = L(cats[i]) end
    return out
end

-- Append all rows to target
local function append_all(target, rows)
    for i = 1, #rows do
        target[#target + 1] = rows[i]
    end
end

--- Create a new KeybindBlockBuilder.
--- @param targetTable table Destination table to append rows into
--- @return KeybindBlockBuilder builder A builder bound to targetTable.
function KeybindBlockBuilder:new(targetTable)
    local self = setmetatable({}, KeybindBlockBuilder)
    assert(type(targetTable) == "table", "KeybindBlockBuilder:new requires a target table")
    self.target = targetTable
    return self
end


--- Add a push button block.
--- @param btnCmd number              Device/keybind command for the button
--- @param baseName string            Display base name shown in the UI
--- @param categories string|string[] Category breadcrumb(s) (string or array of strings)
--- @return nil
function KeybindBlockBuilder:addButton(btnCmd, baseName, categories)
    local cat  = norm_categories(categories)
    local base = baseName or "Unnamed"

    local row = {
        down       = btnCmd,
        up         = btnCmd,
        value_down = 1.0,
        value_up   = 0.0,
        name       = L(string.format("%s", base)),
        category   = cat,
    }
    append_all(self.target, { row })
end


--- Add a 2-position switch block.
--- @param swCmd number            Device/keybind command for the 2-pos switch
--- @param baseName string         Display base name shown in the UI
--- @param categories string|string[] Category breadcrumb(s) (string or array of strings)
--- @param toggleCmd number|nil    Optional toggle command; pass nil if not needed
--- @param labels table|nil        Labels table; uses 1-indexed keys [1] and [2]
--- @return nil
function KeybindBlockBuilder:add2Pos(swCmd, baseName, categories, toggleCmd, labels)
    local cat  = norm_categories(categories)
    local base = baseName or "Unnamed"

    -- 1-indexed labels: [1] -> first (value 0), [2] -> second (value 1)
    local first  = (labels and labels[1]) or "OFF"
    local second = (labels and labels[2]) or "ON"

    local rows = {
        { down = swCmd, up = swCmd, value_down = 1, value_up = 0,
          name = L(string.format("%s - %s <> %s", base, second, first)), category = cat },
    }

    if toggleCmd then
        rows[#rows+1] = {
            down = toggleCmd,
            name = L(string.format("%s - TOGGLE", base)),
            category = cat,
        }
    end

    rows[#rows+1] = { down = swCmd, value_down = 1, value_up = 0,
                      name = L(string.format("%s - %s", base, second)), category = cat }
    rows[#rows+1] = { down = swCmd, value_down = 0, value_up = 1,
                      name = L(string.format("%s - %s", base, first)),  category = cat }

    append_all(self.target, rows)
end


--- Add a 3-position switch block
--- @param swCmd number Device/keybind command for the 3-position switch
--- @param baseName string Display base name for the entries
--- @param categories string|string[] Category breadcrumb(s) for these entries
--- @param cycleCmd number|nil Optional cycle keybind command; if nil, no cycle row is added
--- @param labels table|nil Optional 1-indexed labels table as described above
--- @param cycleName string|nil Optional caption for the cycle row; defaults to "CYCLE"
--- @return nil
function KeybindBlockBuilder:add3Pos(swCmd, baseName, categories, cycleCmd, labels, cycleName, springLoaded)
    local cat  = norm_categories(categories)
    local base = baseName or "Unnamed"
    local l0 = (labels and labels[1]) or "LEFT"    -- -1
    local l1 = (labels and labels[2]) or "CENTER"  --  0
    local l2 = (labels and labels[3]) or "RIGHT"   -- +1

    local rows = { }
    rows[#rows+1] =         { down = swCmd, up = swCmd, value_down = -1, value_up = 0,
        name = L(string.format("%s - %s <> %s", base, l0, l1)), category = cat }
    rows[#rows+1] =        { down = swCmd, up = swCmd, value_down =  1, value_up = 0,
        name = L(string.format("%s - %s <> %s", base, l2, l1)), category = cat }
    
    if not springLoaded then
        -- Direct positions
        rows[#rows+1] = { down = swCmd, value_down = -1, value_up = 0, name = L(string.format("%s - %s", base, l0)), category = cat }
        rows[#rows+1] = { down = swCmd, value_down =  1, value_up = 0, name = L(string.format("%s - %s", base, l2)), category = cat }
        rows[#rows+1] = { down = swCmd, value_down =  0, value_up = 0, name = L(string.format("%s - %s", base, l1)), category = cat }
    end

    if cycleCmd then
        rows[#rows+1] = {
            down = cycleCmd,
            name = L(string.format("%s - %s", base, cycleName or "CYCLE")),
            category = cat,
        }
    end



    append_all(self.target, rows)
end


--- Add a multi-position switch block (N positions).
--- Expects a mapping table of numeric values to label strings
--- @param swCmd number            Base device/keybind command for direct positions
--- @param baseName string         Display base name
--- @param categories string|string[] Category breadcrumb(s)
--- @param incCmd number|nil       Optional increment key
--- @param decCmd number|nil       Optional decrement key
--- @param cycleCmd number|nil     Optional cycle key
--- @param labelsByValue table     Required mapping of numeric value -> label string
--- @return nil
function KeybindBlockBuilder:addMultiPos(swCmd, baseName, categories, incCmd, decCmd, cycleCmd, labelsByValue)
    assert(type(labelsByValue) == "table", "addMultiPos: labelsByValue table is required")
    local cat  = norm_categories(categories)
    local base = baseName or "Unnamed"

    -- Collect and sort all numeric values so output order is stable
    local values = {}
    for v, label in pairs(labelsByValue) do
        if type(v) == "number" and type(label) == "string" then
            values[#values+1] = v
        end
    end
    table.sort(values, function(a,b) return a < b end)
    assert(#values > 0, "addMultiPos: labelsByValue must contain at least one numeric key with a string label")

    local rows = {}

    if incCmd then
        rows[#rows+1] = { down = incCmd, name = L(string.format("%s - INC.", base)), category = cat }
    end
    if decCmd then
        rows[#rows+1] = { down = decCmd, name = L(string.format("%s - DEC.", base)), category = cat }
    end
    if cycleCmd then
        rows[#rows+1] = { down = cycleCmd, name = L(string.format("%s - CYCLE", base)), category = cat }
    end

    for i = 1, #values do
        local v = values[i]
        local label = labelsByValue[v]
        rows[#rows+1] = {
            down = swCmd,
            value_down = v,
            value_up   = 0,
            name = L(string.format("%s - %s", base, label)),
            category = cat,
        }
    end

    append_all(self.target, rows)
end


--- Append arbitrary keybind rows
--- Each row should follow DCS input table conventions
--- @param rows table[] Array of keybind rows to append verbatim.
--- @return nil
function KeybindBlockBuilder:add(rows)
    append_all(self.target, rows)
end

return KeybindBlockBuilder
