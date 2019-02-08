-- general utilities

-- convert a single int number into an RGB triplet
-- for sanity, pass in as a hex number, eg. rgb( 0xc1c1c1 )
-- return as a TABLE now.
function rgb( colour )
  local r, g, b
  if ( colour > 0xffffff ) then
    error( "colour too big for rgb() - use rgba() instead?" )
  end
  r = math.floor(   colour / 65536 )
  g = math.floor( ( colour % 65536 ) / 256 )
  b = colour % 256
  return { r, g, b }
end

-- same as rgb(), but 2 extra bytes at the end for alpha.
-- for sanity, pass in as a hex number, eg. rgba( 0xc1c1c1ff )
function rgba( colour )
  local r, g, b, a, top_bytes
  -- can't be clever with alpha, MUST assume last 2 bytes are alpha.
  a = colour % 256
  top_bytes = math.floor( colour / 256 )
  r, g, b = unpack( rgb( top_bytes ) )
  return { r, g, b, a }
end

-- perform a full deep copy on the given table
local deepcopy_visited = {} -- static
function deepcopy( t, depth )
  if not depth then
    deepcopy_visited = {}  -- reset our visited list.
    depth = 1 -- set starting depth
  end

  local result = t -- default works if it's a scalar

  if type( t ) == 'table' then
    -- have we already visited it? If so, return a reference.
    local key = tostring( t )
    if deepcopy_visited[ key ] then
      -- it's already been copied - return it.
      return deepcopy_visited[ key ]
    end

    -- create a new table for it.
    result = {}

    -- record the reference right away to avoid cycles
    deepcopy_visited[ key ] = result

    -- make a copy of the table, key by key.
    for k,v in pairs( t ) do
      if type( v ) == 'table' then
        v = deepcopy( v, depth + 1 ) -- copy recursively
      end
      result[ k ] = v
    end

    local mt = getmetatable( t )
    setmetatable( result, mt )

    -- stash this table, record as visited to avoid cycles.
    deepcopy_visited[ tostring( t ) ] = result
  end

  return result
end

-- deepmerge is like deepcopy, but takes 2 tables as input.
-- copies the second one over the first one. does NOT overwrite original.
function deepmerge( base, overrides )
  local target = {}
  if type( overrides ) ~= 'table' then
    return deepcopy( base )
  end

  local keys = {}
  --get all of the keys from both base and overrides.
  for key, _ in pairs( base ) do
    keys[ key ] = true
  end
  for key, _ in pairs( overrides ) do
    keys[ key ] = true
  end

  -- go through each key. copy base if any, then override if any.
  for key, _ in pairs( keys ) do
    -- if there is no override
    if base[ key ] ~= nil and overrides[ key ] ~= nil then -- merge them.
      if type( overrides[ key ] ) == 'table' then
        target[ key ] = deepmerge( base[ key ], overrides[ key ] )
      else
        target[ key ] = overrides[ key ]
      end
    elseif base[ key ] ~= nil then -- just the base.
      target[ key ] = deepcopy( base[ key ] )
    else -- just the override
      target[ key ] = deepcopy( overrides[ key ] )
    end
  end
  return target
end

-- custom iterator to go through table based on its sorted keys
-- not super-efficient.
function kpairs( t, f )
  local a = {}
  -- flatten the keys
  for n in pairs( t ) do a[ #a + 1 ] = n end
  -- sort the keys
  table.sort( a, f )
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
    i = i + 1
    if a[ i ] == nil then return nil
    else return a[ i ], t[ a[ i ] ]
    end
  end
  return iter
end

-- custom iterator to sort a table by whatever.
-- basic example, just sort by the keys
-- for k,v in spairs(HighScore) do print(k,v) end
-- fancy example, custom sort by score descending
--for k,v in spairs(HighScore, function(t,a,b) return t[b] < t[a] end) do print(k,v) end
function spairs( t, order_cb )
  -- collect the keys
  local keys = {}
  for k in pairs( t ) do keys[ #keys + 1 ] = k end

  -- if order function given, sort by it by passing the table and keys a, b,
  -- otherwise just sort the keys
  if order_cb then
    table.sort( keys, function( a, b ) return order_cb( t, a, b ) end )
  else
    table.sort( keys )
  end

  -- return the iterator function
  local i = 0
  return function()
    i = i + 1
    if keys[ i ] then
      return keys[ i ], t[ keys[ i ] ]
    end
  end
end

function table_keys( t )
  local keys = {}
  for key, _ in pairs( t ) do
    keys[ #keys + 1 ] = key
  end
  return keys
end

--[[
-- single variable linear interpolation.
function lerp( val0, val1, t )
return val0 + t * ( val1 - val0 )
end

-- bilinear interpolation
function blerp( tx, ty, val00, val10, val01, val11 )
local temp1 = lerp( val00, cal10, tx )
local temp2 = lerp( val01, cal11, tx )
return lerp( temp1, temp2, ty )
end
]]--

-- inline getopt_alt.lua
-- getopt, POSIX style command line argument parser
-- param arg contains the command line arguments in a standard table.
-- param options is a string with the letters that expect string values.
-- returns a table where associated keys are true, nil, or a string value.
-- example usage:  options = getopt( "hjkl" )
function getopt( arg, options )
  local tab = {}
  for k, v in ipairs(arg) do
    if string.sub( v, 1, 2) == "--" then
      local x = string.find( v, "=", 1, true )
      if x then tab[ string.sub( v, 3, x-1 ) ] = string.sub( v, x+1 )
      else      tab[ string.sub( v, 3 ) ] = true
      end
    elseif string.sub( v, 1, 1 ) == "-" then
      local y = 2
      local l = string.len(v)
      local jopt
      while ( y <= l ) do
        jopt = string.sub( v, y, y )
        if string.find( options, jopt, 1, true ) then
          if y < l then
            tab[ jopt ] = string.sub( v, y+1 )
            y = l
          else
            tab[ jopt ] = arg[ k + 1 ]
          end
        else
          tab[ jopt ] = true
        end
        y = y + 1
      end
    end
  end
  return tab
end

