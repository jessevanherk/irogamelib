-- console module.
-- author: Jesse van Herk <jesse@imaginaryrobots.net>

local module_dir = (...):match("(.-)[^%.]+$")
local Serializer = require( module_dir .. ".serializer" )

local Console = {}

function Console:new( ... )
  local instance = {}
  setmetatable( instance, self )
  self.__index = self
  self._init( instance, ... )
  return instance
end

function Console:_init()
  self.serializer = Serializer:new()
end

function Console:eval( expression )
  local output

  wrapped_expression = self:wrap( expression )

  -- try to parse/compile it into lua code
  local func, err_str = loadstring( wrapped_expression )

  -- It compiled. Try evaluating it.
  if func then
    -- we're in the CONSOLE, so we want to access the global environment.
    local results = { pcall( func ) }

    local success = results[ 1 ]  -- grab the first item, which is the success code
    if success then
      local pretty_parts = {}
      -- copy everything else into a new list, escaping as we go
      for i = 2, #results do
        local prettified = self:prettify( results[ i ] )

        table.insert( pretty_parts, prettified )
      end
      output = table.concat( pretty_parts, ", " )
    else
      err_str = results[ 2 ]
      output = '! Evaluation error: ' .. err_str
    end
  else -- compilation error.
    if err_str then
      output = '! Compilation error: ' .. err_str
    else
      output = '! Unknown compilation error'
    end
  end

  return output
end

function Console:wrap( expression )
  local wrapped
  if expression:find( "=" ) then
    local var_name = expression:match("(%w*) =")
    wrapped = expression .. ";return " .. var_name
  else
    wrapped = "return " .. expression
  end

  return wrapped
end

function Console:prettify( object )
  local prettified = self.serializer:getstring( object, 0, tostring( object ) )

  return prettified
end

return Console
