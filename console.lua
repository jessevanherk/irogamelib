-- console module.
-- author: Jesse van Herk <jesse@imaginaryrobots.net>

local Console = {}

function Console:new( ... )
  local instance = {}
  setmetatable( instance, self )
  self.__index = self
  self._init( instance, ... )
  return instance
end

function Console:_init()
end

function Console:eval( expression )
  local output_lines = {}

  wrapped_expression = self:wrap( expression )

  -- try to parse/compile it into lua code
  local func, err_str = loadstring( wrapped_expression )

  -- It compiled. Try evaluating it.
  if func then
    -- we're in the CONSOLE, so we want to access the global environment.
    local results = { pcall( func ) }

    local success = results[ 1 ]
    if success then
      for i = 2, #results do
        result_lines = self:prettify( results[ i ] )
        for _, line in ipairs( result_lines ) do
          table.insert( output_lines, line )
        end
      end
    else
      err_str = results[ 2 ]
      output = '! Evaluation error: ' .. ( err_str or "Unknown" )
      output_lines = { output }
    end
  else
    local output = '! Compilation error: ' .. ( err_str or "Unknown" )
    output_lines = { output }
  end

  return output_lines
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
  local prettified_lines = {}

  if type( object ) == "table" then
    local name_line = tostring( object ) .. " = {"
    table.insert( prettified_lines, name_line )

    for k, v in pairs( object ) do
      local prettified = "\t" .. k .. " = " .. tostring( v )
      table.insert( prettified_lines, prettified )
    end

    table.insert( prettified_lines, "}" )
  else
    prettified = tostring( object )
    table.insert( prettified_lines, prettified )
  end

  return prettified_lines
end

return Console
