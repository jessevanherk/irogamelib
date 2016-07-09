-- general utilities 

-- convert a single int number into an RGB triplet
-- for sanity, pass in as a hex number, eg. rgb( 0xc1c1c1 )
function rgb( colour )
    local r, g, b
    if ( colour > 0xffffff ) then
        error( "colour too big for rgb() - use rgba() instead?" )
    end
    r = math.floor(   colour / 65536 )
    g = math.floor( ( colour % 65536 ) / 256 )
    b = colour % 256
    return r, g, b
end

-- same as rgb(), but 2 extra bytes at the end for alpha.
-- for sanity, pass in as a hex number, eg. rgba( 0xc1c1c1ff )
function rgba( colour )
    local r, g, b, a, top_bytes
    -- can't be clever with alpha, MUST assume last 2 bytes are alpha.
    a = colour % 256
    top_bytes = math.floor( colour / 256 )
    r, g, b = rgb( top_bytes )
    return r, g, b, a
end

-- perform a full deep copy on the given table
function deepcopy( t )
    if type( t ) ~= 'table' then 
        return t 
    end
    local mt = getmetatable( t )
    local result = {}
    for k,v in pairs( t ) do
        if type( v ) == 'table' then
            v = deepcopy( v ) -- copy recursively
        end
        result[ k ] = v
    end
    setmetatable( result, mt )
    return result
end

-- deepmerge is like deepcopy, but takes 2 tables as input.
-- copies the second one over the first one. does NOT overwrite original.
function deepmerge( base, overrides )
    local target = {}
    if type( overrides ) ~= 'table' then
        return base
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
        if base[ key ] and overrides[ key ] then -- merge them.
            if type( overrides[ key ] ) == 'table' then
                target[ key ] = deepmerge( base[ key ], overrides[ key ] )
            else
                target[ key ] = overrides[ key ]
            end
        elseif base[ key ] then -- just the base.
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
    for n in pairs( t ) do table.insert( a, n ) end
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
