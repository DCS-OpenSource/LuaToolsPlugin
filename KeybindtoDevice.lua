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

--- Create a new instance of KeybindtoDevice
function KeybindToDevice:new()
    local self = setmetatable({}, KeybindToDevice)
    self.keybinds = {} -- Table to hold keybinds, keyed by command id
    self.device  = GetSelf()
    return self
end

--- Function to register a keybind to a device command
--- @param keyCommand number The keybind command to listen for
--- @param deviceCommand number The device command to perform when the keybind is pressed
--- @param device number|nil The index of the device to which the command belongs, defaults to current device
--- @param toEFM boolean|nil When true, only register an EFM-dispatch entry (no clickable entry)
--- @return nil
function KeybindToDevice:registerKeybind(keyCommand, deviceCommand, device, toEFM)
    local dev = device and GetDevice(device) or self.device

    if toEFM then
        -- EFM-only path: listen to the keyCommand and dispatch to EFM with deviceCommand
        self.device:listen_command(deviceCommand)
        self.keybinds[deviceCommand] = {
            kind          = "efm",       -- dispatch_action path
            deviceCommand = keyCommand,  -- what we will dispatch to EFM
            device        = dev,
        }
        return
    end

    -- Normal clickable path
    self.device:listen_command(keyCommand)
    if not self.keybinds[keyCommand] then
        self.keybinds[keyCommand] = {
            kind          = "click",           -- performClickableAction path
            deviceCommand = deviceCommand,
            device        = dev,
            toEFM         = false,
            doClickable   = doClickable or false,
        }
    end
end


--- Register a toggle keybind. When pressed, toggleFunc() must return the new value.
--- @param KeyCommand number
--- @param deviceCommand number|nil device clickable to drive (optional, but typical)
--- @param initialState any initial toggle state
--- @param toggleFunc function returns the new toggle value each press
--- @param device number|nil
--- @param toEFM boolean|nil when true, also add an EFM-dispatch entry keyed by deviceCommand
function KeybindToDevice:registerToggleKeybind(KeyCommand, deviceCommand, initialState, toggleFunc, device, toEFM)
    local dev = device and GetDevice(device) or self.device

    -- Clickable/toggle path (keyed by the keybind command)
    self.device:listen_command(KeyCommand)
    if not self.keybinds[KeyCommand] then
        self.keybinds[KeyCommand] = {
            kind          = "click",           -- toggle still only applies on the keybind path
            deviceCommand = deviceCommand,
            device        = dev,
            toggleValue   = initialState,
            toggleFunc    = toggleFunc,
            toEFM         = toEFM or false,
        }
    end
end

--- Route command events to the appropriate action based on registration
--- @param keyCommand number The command id received by SetCommand
--- @param value any The value to send with the command
--- @return boolean success
function KeybindToDevice:sendCommand(keyCommand, value)
    
    local bind = self.keybinds[keyCommand]
    if not bind then return false end
    
    if bind.kind == "efm" then
        -- EFM path: mirror device command to external FM
        -- value can be nil; default to 0 for safety
        dispatch_action(nil, bind.deviceCommand, value or 0)
        return true
    end

    -- Clickable path (default/legacy behavior)
    if bind.toggleFunc == nil then
        -- Normal keybind -> clickable action
        bind.device:performClickableAction(bind.deviceCommand, value, false)
        return true
    else
        -- Toggle keybind -> compute new value and send clickable
        local toggledValue = bind.toggleFunc()
        if toggledValue == nil then
            print_message_to_user("You forgot to return a value in your toggleFunc command")
            return false
        end
        bind.toggleValue = toggledValue
        if bind.deviceCommand then
            bind.device:performClickableAction(bind.deviceCommand, toggledValue, true)
        end
        return true
    end
end

return KeybindToDevice
