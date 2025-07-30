-- MIT License

-- Copyright (c) 2025 OpenFlight Community

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

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
    self.keybinds = {} -- Table to hold keybinds
    self.device = GetSelf()
    return self
end


--- Function to register a keybind to a device command
--- @param keyCommand number The keybind command to listen for
--- @param deviceCommand number The device command to perform when the keybind is pressed
--- @param device number|nil The index of the device to which the command belongs, defaults to current device
--- @param toEFM boolean|nil Whether to send the command to the EFM, defaults to false
--- @return nil
function KeybindToDevice:registerKeybind(keyCommand, deviceCommand, device, toEFM)
    self.device:listen_command(keyCommand) -- Listen for the keybind command
    if not self.keybinds[keyCommand] then
        self.keybinds[keyCommand] = {
            deviceCommand = deviceCommand,
            device = device and GetDevice(device) or self.device,
            toEFM = toEFM
        }
    end
end

function KeybindToDevice:registerToggleKeybind(KeyCommand, deviceCommand, initialState, toggleFunc, device, toEFM)
    self.device:listen_command(KeyCommand)
    if not self.keybinds[KeyCommand] then
        self.keybinds[KeyCommand] = {
            deviceCommand = deviceCommand,
            device = device and GetDevice(device) or self.device,
            toEFM = toEFM or false,
            toggleValue = initialState,
            toggleFunc = toggleFunc
        }
    end
end


--- Function to send a command when a keybind is pressed
--- @param keyCommand number The keybind command that was pressed
--- @param value any The value to send with the command
--- @return boolean success Whether the command was successfully sent
function KeybindToDevice:sendCommand(keyCommand, value)
    local bind = self.keybinds[keyCommand]
    if not bind then return false end

    if bind.toggleFunc == nil then
        -- Normal keybind
        -- print_message_to_user("Sending command: " .. keyCommand .. " with value: " .. tostring(value))
        bind.device:performClickableAction(bind.deviceCommand, value, false)
        if bind.toEFM then
            dispatch_action(nil, bind.deviceCommand, 0)
        end
        return true
    else
        -- Toggle keybind
        local toggledValue = bind.toggleFunc()
        if toggledValue == nil then
            print_message_to_user("You forgot to return a value in your toggleFunc command")
            return false
        end
        bind.toggleValue = toggledValue
        if bind.deviceCommand then
            local dev = GetSelf()
            bind.device:performClickableAction(bind.deviceCommand, toggledValue, true)
            if bind.toEFM then
                dispatch_action(nil, bind.deviceCommand, 0)
            end
        end
        return true
    end
end



return KeybindToDevice
