-- basics for single-inheritance classes.
dbg = require("debugger")

local BaseClass = {}
BaseClass.__index = BaseClass

-- add a metatable with a __call method
setmetatable( BaseClass, {
    __call = function ( cls, ... )
      local self = setmetatable( {}, cls )

      -- call the special init method
      self:_init( ... )
      return self
    end,
  })

function BaseClass:_init()
end

-- a simple function that returns an inheritable class.
local function Class( base_class )
  local DerivedClass = {}
  DerivedClass.__index = DerivedClass

  if not base_class then
    base_class = BaseClass
  end

  setmetatable( DerivedClass, {
    __index = base_class, -- make the inheritance work
    __call = function ( cls, ... )
      local self = setmetatable( {}, cls )
      self:_init( ... )
      return self
    end,
  })

  return DerivedClass
end

return Class
