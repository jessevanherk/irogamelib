--------------------------------
-- Space: encapsulates a collection of entities, systems, and timers.
--        similar to what artemis framework uses.
--        This is useful for having multiple loaded levels/scenes and only having one active, 
--        e.g. gameplay versus menus

local Space = {}

-- magic constructor for the system. real init code goes in init().
function Space:new( ... )
    local instance = {}
    setmetatable( instance, self )
    self.__index = self
    self._init( instance, ... )
    return instance
end

-- create new space, pass in component data to use.
function Space:_init( entity_templates, component_templates, create_cb, systems, system_prefix )
    -- create an entity manager for this space
    self.entity_manager = EntityManager:new( entity_templates, component_templates, create_cb )

    -- create a timer instance, so timers only update when this space is active
    --self.timer  = Timer.new()

    -- create the systems that this space uses.
    self.system_manager = SystemManager:new( systems )

    -- FIXME: create signal handler
end

-- should be called once in the update callback.
function Space:update( dt )
    -- update timers.
    --self.timer:update( dt )
    
    self.entity_manager:update( dt )
    self.system_manager:update( dt )
end

function Space:draw()
    self.system_manager:draw()
end

return Space
