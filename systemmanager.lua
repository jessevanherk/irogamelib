--------------------------------
-- System Manager , takes care of all creation/update of systems
-- entities and components are JUST DATA - think of this like a DB Model,
-- returning resultsets, NOT objects. Performance matters, so don't split
-- things into sub classes.
-- should NOT know about rendering engine or systems.

local SystemManager = {}

function SystemManager:new( ... )
    local instance = {}
    setmetatable( instance, self )
    self.__index = self
    self._init( instance, ... )
    return instance
end

function SystemManager:_init( systems, system_prefix )
    self.system_prefix = system_prefix or "lib.systems."

    -- these are automatically populated based on whether the system has update() or draw() functions.
    self.update_systems = {}
    self.draw_systems = {}

    for _, system_name in ipairs( systems ) do
        self:addSystem( system_name )
    end
end

function SystemManager:addSystem( system_name )
    assert( system_name, "must specify system name" )
    local system_file = self.system_prefix .. system_name:lower()

    system_lib = require( system_file )

    local system = system_lib:new()

    if system.update then
        table.insert( self.update_systems, system )
    end

    if system.draw then
        table.insert( self.draw_systems, system )
    end

end

-- update all systems. call from your main loop.
function SystemManager:update( dt )
    for _, system in ipairs( self.update_systems ) do
        system:update( dt )
    end
end

-- call any systems that do drawing. Won't call the rest.
-- call from your main loop.
function SystemManager:draw()
    for _, system in ipairs( self.draw_systems ) do
        system:draw()
    end
end

return SystemManager
