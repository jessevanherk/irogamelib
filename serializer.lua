local Serializer = {}

-- magic constructor for the system. real init code goes in init().
function Serializer:new( ... )
  local instance = {}
  setmetatable( instance, self )
  self.__index = self
  self._init( instance, ... )
  return instance
end

function Serializer:_init()
  self:clearSeenKeys()
end

function Serializer:getAsFile( input, table_name )
  local serialized = self:getstring( input )

  local contents = "local " .. table_name .. " = " .. serialized .. "\n"
  contents = contents .. "return " .. table_name .. "\n"

  return contents
end

function Serializer:getstring( object, depth, name )
  self:clearSeenKeys()
  return self:serialize( object, depth, name )
end

function Serializer:serialize(object, depth, name)
  if depth and depth > 4 then
    return "-- object too deep"
  end

  depth = depth or 0

  local r = string.rep('  ', depth)
  if name then -- should start from name
    r = r .. self:serializeName( name )
  end

  if type(object) == 'table' then
    local key = self:getKey( object )
    if self:alreadySeen( key ) then
      r = r .. "nil -- already saw table " .. key
    else
      self:recordKey( key )

      r = r .. self:serializeTable( object, depth )
    end
  elseif type(object) == 'string' then
    r = r .. self:serializeString( object )
  elseif type(object) == 'number' or type(object) == 'boolean' then
    r = r .. self:serializeNumber( object )
  elseif object == nil then
    r = nil
  else
    error('Cannot serialize value "' .. tostring(object) .. '"')
  end
  return r
end

function Serializer:serializeName( name )
  r = (
  -- enclose in brackets if not string or not a valid identifier
  -- thanks to Boolsheet from #love@irc.oftc.net for string pattern
  (type(name) ~= 'string' or name:find('^([%a_][%w_]*)$') == nil or name == 'return')
  and ('[' .. (
  (type(name) == 'string')
  and string.format('%q', name)
  or tostring(name))
  .. ']')
  or tostring(name)) .. ' = '

  return r
end

function Serializer:serializeTable( object, depth )
  local padding = string.rep('  ', depth)

  r = '{' .. self:sep()
  local length = 0

  for i, v in ipairs(object) do
    r = r .. self:getstring(v, self:next_depth( depth ) ) .. ','
        .. self:sep()
    length = i
  end

  for i, v in pairs(object) do
    -- convert type into something easier to compare:
    itype = self:indextype( i )

    -- detect if item should be skipped
    local skip = self:is_skippable( itype, i, length )

    if not skip then
      r = r .. self:getstring(v, self:next_depth( depth ), i)
          .. ',' .. self:sep()
    end
  end
  r = r .. padding .. '}'

  return r
end

function Serializer:serializeString( object )
  return string.format('%q', object)
end

function Serializer:serializeNumber( object )
  return tostring( object )
end

function Serializer:next_depth( depth )
  local next_depth = depth + 1
  return next_depth
end

function Serializer:sep()
  return '\n'
end

function Serializer:is_skippable( itype, i, length )
  local is_skippable =
    ((itype == 1) and ((i % 1) == 0) and (i >= 1) and (i <= length)) -- ipairs part
    or ((itype == 2) and (string.sub(i, 1, 1) == '_')) -- prefixed string

  return is_skippable
end

function Serializer:indextype( i )
  itype = type( i )
  if itype == "number" then
    return 1
  elseif itype == "string" then
    return 2
  elseif itype == "boolean" then
    return 3
  else
    error('Serialize: Unsupported index type "' .. itype .. '"')
  end
end

function Serializer:getKey( object )
  return tostring( object )
end

function Serializer:alreadySeen( key )
  if self._seen_keys[ key ] then
    return true
  else
    return false
  end
end

function Serializer:recordKey( key )
  self._seen_keys[ key ] = true
end

function Serializer:clearSeenKeys()
  self._seen_keys = {}
end

return Serializer
