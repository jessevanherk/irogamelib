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

function Console.eval( expression )
  local output

  wrapped_expression = Console.wrap( expression )

  -- try to parse/compile it into lua code
  local func, err_str = loadstring( wrapped_expression )

  -- It compiled. Try evaluating it.
  if func then
    -- we're in the CONSOLE, so we want to access the global environment.
    local results = { pcall( func ) }

    local success = results[ 1 ]  -- grab the first item, which is the success code
    if success then
      local escaped = {}
      -- copy everything else into a new list, escaping as we go
      for i = 2, #results do
        table.insert( escaped, tostring( results[ i ] ) )
      end
      output = table.concat( escaped, ", " )
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

function Console.wrap( expression )
  local wrapped
  if expression:find( "=" ) then
    local var_name = expression:match("(%w*) =")
    wrapped = expression .. ";return " .. var_name
  else
    wrapped = "return " .. expression
  end

  print("WRAPPED: ", wrapped)

  return wrapped
end

return Console
