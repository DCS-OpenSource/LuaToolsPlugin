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

local KeybindToDevice = {}
KeybindToDevice.__index = KeybindToDevice

-- Small helper: snap a value to the nearest entry in a list
local function nearest_index(values, v)
    if not values or #values == 0 then return 1 end
    local best_i, best_d = 1, math.huge
    for i = 1, #values do
        local d = math.abs((values[i] or 0) - (v or 0))
        if d < best_d then best_d, best_i = d, i end
    end
    return best_i
end

--- Create a new KeybindToDevice instance
function KeybindToDevice:new()
    local self = setmetatable({}, KeybindToDevice)
    self.keybinds = {}   -- keyed by deviceCommand
    self.device   = GetSelf()
    return self
end

--- Register a keybind (simple or toggle)
--- @param deviceCommand number Device command to perform
--- @param keyCommand number Keybind that directly triggers the device command
--- @param toggleCommand number|nil Keybind that cycles through toggleValues (nil for non-toggle)
--- @param toggleValues number[]|nil Array of values for toggle states (e.g., {0, 0.5, 1})
--- @param toEFM boolean|nil Mirror to EFM by dispatching the keybind command with its value
function KeybindToDevice:registerKeybind(deviceCommand, keyCommand, toggleCommand, toggleValues, toEFM)
    -- Listen for keybinds (deviceCommand is delivered to SetCommand without listen_command)
    if keyCommand then self.device:listen_command(keyCommand) end
    if toggleCommand then self.device:listen_command(toggleCommand) end

    self.keybinds[deviceCommand] = {
        deviceCommand = deviceCommand,
        keyCommand    = keyCommand,
        toggleCommand = toggleCommand,
        toggleValues  = toggleValues,
        stateIndex    = 1,               -- internal toggle state (1-based)
        toEFM         = toEFM or false,
    }
end

--- Send a command into the system (call from SetCommand)
--- Supports:
---  - keyCommand         : performs device action; mirrors to EFM with keyCommand
---  - toggleCommand      : cycles state; performs device action; mirrors to EFM with toggleCommand
---  - deviceCommand      : mirrors to EFM (reverse direction). For toggles, snaps to nearest state.
function KeybindToDevice:sendCommand(command, value)
    for _, bind in pairs(self.keybinds) do
        -- 1) SIMPLE KEY PATH
        if bind.keyCommand and command == bind.keyCommand then
            self.device:performClickableAction(bind.deviceCommand, value, false)
            if bind.toEFM then
                dispatch_action(nil, bind.keyCommand, value)
            end
            return
        end

        -- 2) TOGGLE KEY PATH (cycle values)
        if bind.toggleCommand and command == bind.toggleCommand then
            local tv = bind.toggleValues
            if tv and #tv > 0 then
                bind.stateIndex = bind.stateIndex % #tv + 1
                local newValue = tv[bind.stateIndex]
                self.device:performClickableAction(bind.deviceCommand, newValue, true)
                if bind.toEFM then
                    dispatch_action(nil, bind.toggleCommand, newValue)
                end
            end
            return
        end

        -- 3) DEVICE PATH (cockpit click / other Lua calls)
        if command == bind.deviceCommand then
            local outValue = value
            if bind.toggleCommand and bind.toggleValues and #bind.toggleValues > 0 then
                local idx = nearest_index(bind.toggleValues, value or 0)
                bind.stateIndex = idx
                outValue = bind.toggleValues[idx]
            end

            if bind.toEFM then
                local mirrorKey = bind.toggleCommand or bind.keyCommand
                if mirrorKey then
                    dispatch_action(nil, mirrorKey, outValue)
                end
            end
            return
        end
    end
end


--- Get the current tracked value of a binding
--- @param deviceCommand number Device command registered with this system
--- @return number|nil The current value (nil if not registered)
function KeybindToDevice:getValue(deviceCommand)
    local bind = self.keybinds[deviceCommand]
    if not bind then return nil end
    if bind.toggleCommand and bind.toggleValues then
        return bind.toggleValues[bind.stateIndex]
    end
    return bind.currentValue
end

return KeybindToDevice
