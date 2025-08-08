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


---@class Timer The timer utility class. Should use DCS's built in update functionality. 

local Timer = {}
Timer.__index = Timer

---Create a new instance of the Timer table
---@param duration number Default 0.05 seconds. The duration set for the timer.
---@param updateRate number Default 1 second. The time step incremented every update
---@param callback function|nil The callback function to execute when the timer goes off.
---@param persistentRinging boolean|nil Default false. Whether or not the timer should execute the callback every update after it goes off. True means it should. 
---@param autoReset boolean|nil Default false. Should the timer automatically reset itself once it has finished?
---@return Timer self The timer table that has been created.
function Timer:new(duration, updateRate, callback, persistentRinging, autoReset)
    local self = setmetatable({}, Timer)
    self.duration = duration or 1
    self.updateRate = updateRate or 0.05
    self.callback = callback or nil
    self.running = false
    self.elapsed = 0
    self.completed = false
    self.persistentRinging = persistentRinging or false
    self.autoReset = autoReset or false
    assert(not (persistentRinging and autoReset), "The timer classes persistentRinging and autoReset should not both be true")
    return self
end

---Starts the timer. 
function Timer:startTimer()
    self.running = true
    self.elapsed = 0
    self.completed = false
end

---Will stop the timer prematuretly, or end the "ringing" if persistentRinging is true.
function Timer:stopTimer()
    self.running = false
end

---Resets the timer. Can be used to reset the timer before its finished, or to clear it after. 
function Timer:resetTimer()
    self.elapsed = 0
    self.completed = false
    self.running = false
end

---Update the timer for its time step. Should be called in the DCS device update function. 
function Timer:updateTimer()
    if not self.running or (self.completed and not self.persistentRinging) then return end

    if self.running then
        self.elapsed = self.elapsed + self.updateRate  
    end
    
    if self.elapsed >= self.duration then

        self.running = false
        self.completed = true

        if self.callback then
            self.callback()
        end

        if self.autoReset and not self.persistentRinging then 
            self.elapsed = 0
            self.completed = true
            self.running = true
        end
    end
end

---Check if the timer has finished. This is not the prefered method of use for the timer, and callbacks are encouraged to be used. However, this may be more helpful at times.
---@return boolean self.completed Whether or not the timer has elapsed and is done counting.
function Timer:isDone()
    return self.completed
end

---Explicitly set the timer end callback.
---@param fn function The callback to be executed when the timer elapses.
function Timer:setCallback(fn)
    self.callback = fn
end

return Timer
