
require "TimedActions/ISBaseTimedAction"

ISContinue = ISBaseTimedAction:derive("ISContinue");

function ISContinue:isValid()
    if AutoCook.Verbose then print ("ISContinue:isValid") end
    return self.target ~= nil;
end

function ISContinue:update()
    if AutoCook.Verbose then print ("ISContinue:update") end
end

function ISContinue:start()
    if AutoCook.Verbose then print ("ISContinue:start") end
end

function ISContinue:stop()
    if AutoCook.Verbose then print ("ISContinue:stop") end
    ISBaseTimedAction.stop(self);
end

function ISContinue:perform()
    if AutoCook.Verbose then print ("ISContinue:perform") end
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self);
    self.target:continue();
end

function ISContinue:new(target, character, maxTime)
    if AutoCook.Verbose then print ("ISContinue:new") end
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character;
    o.target = target;
    o.stopOnWalk = false;
    o.stopOnRun = false;
    o.maxTime = maxTime;
    return o;
end
