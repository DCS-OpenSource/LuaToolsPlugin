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
--- @param device number The index of the device to which the command belongs
--- @param toEFM boolean Whether to send the command to the EFM
--- @return nil
function KeybindToDevice:registerKeybind(keyCommand, deviceCommand, device, toEFM)
    self.device:listen_command(keyCommand) -- Listen for the keybind command
    if not self.keybinds[keyCommand] then
        self.keybinds[keyCommand] = {deviceCommand, GetDevice(device), toEFM}
    end
end


--- Function to send a command when a keybind is pressed
--- @param keyCommand number The keybind command that was pressed
--- @param value any The value to send with the command
--- @return boolean success Whether the command was successfully sent
function KeybindToDevice:sendCommand(keyCommand, value)
    if self.keybinds[keyCommand] then
        -- print_message_to_user("Sending command: " .. keyCommand .. " with value: ".. value)
        self.keybinds[keyCommand][2]:performClickableAction(self.keybinds[keyCommand][1], value, false)
        if self.keybinds[keyCommand][3] then -- send to EFM since performClickableAction doesnt send to EFM
            dispatch_action(nil, self.keybinds[keyCommand][1], 0)
        end
        return true
    end
    return false
end


return KeybindToDevice
