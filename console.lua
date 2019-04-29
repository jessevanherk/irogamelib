-- console module.
-- author: Jesse van Herk <jesse@imaginaryrobots.net>

local Console = Class()

function Console:_init()
end

function Console:eval( expression )
  local output_lines

  wrapped_expression = self:wrap( expression )

  -- try to parse/compile it into lua code
  local func, err_str = loadstring( wrapped_expression )

  -- It compiled. Try evaluating it.
  if func then
    -- call with the global environment without filtering.
    local result = { pcall( func ) }
    local success, values = self:splitResults( result )

    if success then
      output_lines = self:prettifyValues( values )
    else
      err_str = values[ 1 ]
      output = '! Evaluation error: ' .. ( err_str or "Unknown" )
      output_lines = { output }
    end
  else
    local output = '! Compilation error: ' .. ( err_str or "Unknown" )
    output_lines = { output }
  end

  return output_lines or {}
end

function Console:prettifyValues( values )
  local output_lines = {}

  for _, value in ipairs( values ) do
    local value_lines = self:prettify( value )
    for _, line in ipairs( value_lines ) do
      table.insert( output_lines, line )
    end
  end

  return output_lines
end

function Console:splitResults( results )
  local success = results[ 1 ]

  local values = {}
  for i = 2, #results do
    local value = results[ i ]
    table.insert( values, value )
  end

  return success, values
end

function Console:wrap( expression )
  local wrapped
  if expression == nil then
    wrapped = "return nil"
  elseif expression:find( "==" ) then
    wrapped = "return " .. expression
  elseif expression:find( "=" ) then
    local var_name = expression:match("(%w*) *=")
    wrapped = expression .. ";return " .. var_name
  else
    wrapped = "return " .. expression
  end

  return wrapped
end

function Console:prettify( object )
  local prettified_lines = {}

  if object == nil then
    table.insert( prettified_lines, "nil" )
  elseif type( object ) == "table" then
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
