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
function Space:_init( entity_templates, component_templates, systems, system_prefix )
    -- create signal handler and timer instances.
    self.signal = Signal.new()
    self.timer  = Timer.new()

    self.entity_manager = EntityManager:new( entity_templates, component_templates, self.onCreatedEntity )
    self.system_manager = SystemManager:new( systems, system_prefix, self )
end

-- should be called once in the update callback.
function Space:update( dt )
    -- update timers.
    self.timer:update( dt )
    
    self.entity_manager:update( dt )
    self.system_manager:update( dt )
end

function Space:draw()
    self.system_manager:draw()
end

-- register signal handlers. called from various systems
-- return a set of handles that can be used to unregister them later
function Space:registerSignalHandlers( signal_actions )
    local signal_handles = {}
    if signal_actions then
        for signal, signal_action in pairs( signal_actions ) do
            local handle = self.signal:register( signal, signal_action )
            signal_handles[ signal ] = handle
        end
    end
    return signal_handles
end

-- unregister signal handlers. called from various systems
function Space:unregisterSignalHandlers( signal_handles )
    for signal, handle in pairs( signal_handles ) do
        self.signal:remove( signal, handle )
    end
end

-- simple callback to tell systems/etc they need to do something.
-- OVERRIDE this as needed.
function Space:onCreatedEntity( entity )
    --self.signal:emit( "created_entity", entity )
end

return Space
