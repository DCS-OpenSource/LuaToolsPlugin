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

local Timer = {}
Timer.__index = Timer

function Timer:new(duration, updateRate, callback)
    local self = setmetatable({}, Timer)
    self.duration = duration or 1
    self.updateRate = updateRate or 0.05
    self.callback = callback or nil
    self.running = false
    self.elapsed = 0
    self.completed = false
    return self
end

function Timer:startTimer()
    self.running = true
    self.elapsed = 0
    self.completed = false
end

function Timer:stopTimer()
    self.running = false
end

function Timer:updateTimer()
    if not self.running or self.completed then return end

    self.elapsed = self.elapsed + self.updateRate
    if self.elapsed >= self.duration then
        self.running = false
        self.completed = true
        if self.callback then
            self.callback()
        end
    end
end

function Timer:isDone()
    return self.completed
end

function Timer:setCallback(fn)
    self.callback = fn
end

return Timer
