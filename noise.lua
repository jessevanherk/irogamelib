--[[---------------------------------------------
**********************************************************************************
2D Noise Module, Jesse van Herk.
Based on Jared "Nergal" Hewitt's modifications to Levybreak's translation.
Modified to be OOP, have better performance (for lua), and include a
2d white noise function as well.

Original Source: http://staffwww.itn.liu.se/~stegu/simplexnoise/simplexnoise.pdf
    The code there is in java, the original implementation by Ken Perlin
**********************************************************************************

-- example usage:
-- Noise = Noise:new( 14 )  -- 14 is the seed.
-- value = Noise:smoothNoise( 12, 15 ) -- x and y values

--]]---------------------------------------------

local Noise = {}

-- 2d skew factors.
local SKEW_FACTOR   = 0.5 * ( math.sqrt( 3.0 ) - 1.0 )
local UNSKEW_FACTOR = ( 3 - math.sqrt( 3.0 ) ) / 6.0

-- used by simplex noise.
local gradients_3d = {{1,1,0}, {-1,1,0}, {1,-1,0}, {-1,-1,0},
                       {1,0,1}, {-1,0,1}, {1,0,-1}, {-1,0,-1},
                       {0,1,1}, {0,-1,1}, {0,1,-1}, {0,-1,-1}}

-- local access to floor function, performance boost.
local floor = math.floor

function Noise:new( ... )
    local instance = {}
    setmetatable( instance, self )
    self.__index = self
    self._init( instance, ... )
    return instance
end

function Noise:_init( seed )
    self.seed = seed

    self:seedP( seed )

    self.cached_simplex = {}
    self.cached_derivative = {}
    self.cached_white = {}
end

function Noise:seedP( seed )
  seed = seed * 1234567 -- make sure seed value is bigger than i.

  -- reset all the things
  self.perm = {}
  self.cached_simplex = {}      -- caches output values.
  self.cached_white = {}      -- caches output values.

  -- perm isn't hard-coded, because we want to be able to seed the value.
  -- build this as a double-length array to avoid a pile of modulos later.
  for i = 1, 256 do
    local perm_value = (seed + floor( seed / i ) ) % 256
    self.perm[ i ] = perm_value
    self.perm[ i + 256 ] = perm_value
  end
end

-- dot product.
function Noise:dot3d( tbl, x, y )
    return tbl[ 1 ] * x + tbl[ 2 ] * y
end

-- 2D simplex noise. Meat and potatoes of this module.
-- For the 2D case, the simplex shape is an equilateral triangle.
-- A step of (1,0) in (i,j) means a step of (1-c,-c) in (x,y), and
-- a step of (0,1) in (i,j) means a step of (-c,1-c) in (x,y), where c = (3-self.SQRT3)/6
function Noise:smoothNoise( x_in, y_in, calc_derivative )
    -- avoid recalculation for the same inputs.
    if self.cached_simplex[ x_in ] and self.cached_simplex[ x_in ][ y_in ] then
        local derivative = nil
        if self.cached_derivative[ x_in ] and self.cached_derivative[ x_in ][ y_in ] then
            derivative = self.cached_derivative[ x_in ][ y_in ]
        end
        -- also return the cached derivative.
        return self.cached_simplex[ x_in ][ y_in ], derivative
    end

    -- cache a few things local, gets a decent speedup.
    local perm = self.perm

    -- Skew the input space to determine which simplex cell we're in
    local skew_offset = ( x_in + y_in ) * SKEW_FACTOR -- Hairy factor for 2D

    -- convert input coordinate into skewed cell origin coordinate in ij.
    local i = floor( x_in + skew_offset )
    local j = floor( y_in + skew_offset )

    -- Work out the hashed gradient indices of the three simplex corners
    -- adding 1 so we can use our 1-indexed tables.
    local wrapped_i = i % 256 + 1
    local wrapped_j = j % 256 + 1

    -- doing simple "hashing" by adding together x and y values as a key, then wrapping it.
    local base_key1 = wrapped_i + perm[ wrapped_j ] -- this is used repeatedly.
    local base_key2 = wrapped_i + perm[ wrapped_j + 1 ] -- this is used repeatedly.

    -- convert the cell origin position back to xy space
    local unskew_offset = ( i + j ) * UNSKEW_FACTOR

    -- The x,y position relative to the cell origin
    local rel_x = x_in - ( i - unskew_offset )
    local rel_y = y_in - ( j - unskew_offset )

    -- calculate first and last corners because they're easy.
    -- offsets for first point are 0, so same as requested point.
    local x1 = rel_x
    local y1 = rel_y

    -- Offsets for last corner in xy (unskewed) coords
    local x3 = rel_x - 1 + ( 2 * UNSKEW_FACTOR )
    local y3 = rel_y - 1 + ( 2 * UNSKEW_FACTOR )

    -- get the gradient values for the corners
    -- increment by 1 so we can direct index our lua tables.
    local grad1_index = ( perm[ base_key1     ] % 12 ) + 1
    local grad3_index = ( perm[ base_key2 + 1 ] % 12 ) + 1

    -- calculate the middle corner, which is in a different spot depending
    -- on which half of the simplex we're in.

    -- Offsets for middle corner in (x,y) unskewed coords
    local x2, y2
    local grad2_index
    -- Determine which simplex we are in.
    if( rel_x > rel_y ) then
        -- lower triangle, use bottom right point.
        x2 = rel_x - 1 + UNSKEW_FACTOR
        y2 = rel_y     + UNSKEW_FACTOR
        grad2_index   = ( perm[ base_key1 + 1 ] % 12 ) + 1
    else
        -- upper triangle, use top left point.
        x2 = rel_x     + UNSKEW_FACTOR
        y2 = rel_y - 1 + UNSKEW_FACTOR
        grad2_index   = ( perm[ base_key2     ] % 12 ) + 1
    end

    -- Calculate the noise contribution from the three corners
    local noise1, noise2, noise3 = 0, 0, 0

    local distance1s, distance2s, distance3s, distance1q, distance2q, distance3q

    -- first corner
    local distance1 = 0.5 - x1 * x1 - y1 * y1
    distance1s = distance1 * distance1
    if distance1 > 0 then   -- point is close enough to contribute.
        distance1q = distance1s * distance1s
        noise1 = distance1q * self:dot3d( gradients_3d[ grad1_index ], x1, y1 )
    end

    -- middle corner
    local distance2 = 0.5 - x2 * x2 - y2 * y2
    distance2s = distance2 * distance2
    if distance2 > 0 then  -- point is close enough to contribute.
        distance2q = distance2s * distance2s
        noise2 = distance2q * self:dot3d( gradients_3d[ grad2_index ], x2, y2 )
    end

    -- last corner
    local distance3 = 0.5 - x3 * x3 - y3 * y3
    distance3s = distance3 * distance3
    if distance3 > 0 then  -- point is close enough to contribute.
        distance3q = distance3s * distance3s
        noise3 = distance3q * self:dot3d( gradients_3d[ grad3_index ], x3, y3 )
    end

    -- Add contributions from each corner to get the final noise value.
    -- The result is scaled to return values in the interval [-1,1].
    local total_noise = 70 * ( noise1 + noise2 + noise3 ) -- where did 70 come from??

    -- Calculate the analytics derivative.
    local derivative = nil
    if calc_derivative then
         local temp1 = distance1s * distance1 * self:dot3d( gradients_3d[ grad1_index ], x1, y1 )
         local temp2 = distance2s * distance2 * self:dot3d( gradients_3d[ grad2_index ], x2, y2 )
         local temp3 = distance3s * distance3 * self:dot3d( gradients_3d[ grad3_index ], x3, y3 )
         dx = temp1 * x1 + temp2 * x2 + temp3 * x3
         dy = temp1 * y1 + temp2 * y2 + temp3 * y3
         -- scale the derivatives to match the noise.
         dx = dx * -560  -- 70 * -8
         dy = dy * -560  -- 70 * -8
         derivative = { dx, dy }
    end

    -- cache the result.
    if not self.cached_simplex[ x_in ] then
        self.cached_simplex[ x_in ] = {} -- make sure row exists.
        self.cached_derivative[ x_in ] = {} -- make sure row exists.
    end
    self.cached_simplex[ x_in ][ y_in ] = total_noise
    self.cached_derivative[ x_in ][ y_in ] = derivative

    return total_noise, derivative
end

-- single smooth noise is boring. Want to add multiple octaves together to get
-- much more interesting fractal brownian noise.
-- keep num_iterations small, or this gets expensive.
-- persistence is optional. should be < 1, determines how fast contributions drop off.
function Noise:fractalNoise( x, y, num_iterations, frequency, persistence )
    num_iterations = num_iterations or 2
    persistence = persistence or 0.5 -- 0.5 is a good default value for persistence.
    frequency = frequency or 1

    local total_amplitude = 0
    local amplitude = 1   -- relative importance of the octaves; lowest frequency counts most.

    local noise = 0

    -- add successively smaller, higher-frequency terms
    for i = 1, num_iterations do
        local contribution = self:smoothNoise( x * frequency, y * frequency ) * amplitude
        noise = noise + contribution

        total_amplitude = total_amplitude + amplitude
        amplitude = amplitude * persistence
        frequency = frequency * 2  -- double the frequency to get the next octave.
    end

    -- normalize the result to be between -1 and 1 (since each smooth noise was)
    noise = noise / total_amplitude

    return noise
end

-- Bitwise XOR (32-bit)
-- heavily optimized for lua5.1, Jesse van Herk 2015.
-- note that without bitwise operators, modulos are our fastest option.
-- testing indicates this runs about 94% faster than a version using floor().
function bxor( a, b )
    local r = 0
    local cur_power = 1
    local x = a + b
    local ar, br

    while ( cur_power < 4294967296 ) do
        if x % 2 == 1 then      -- there is still a low bit.
            r = r + cur_power   -- record the bit at this location.
        end
        -- shift down, by removing low bit manually and dividing by 2.
        ar = a % 2
        br = b % 2
        a = ( a - ar ) / 2
        b = ( b - br ) / 2
        x = a + b
        cur_power = cur_power * 2
    end
    return r
end

--[[
  Hash function described in Thomas Wang, "Integer Hash Function"
  http://www.concentric.net/~Ttwang/tech/inthash.htm (Jan. 2007)
  https://gist.github.com/badboy/6267743
  slight optimization for lua, Jesse van Herk 2015.
  only works on inputs less than 2^32.
]]--
function hash32shift( key )
    key = ( key * 32767 ) - 1           -- key = (key << 15 ) - key - 1
    key = bxor( key, ( key / 4096 ) )   -- key = key ^ (key >>> 12)
    key = key * 5                       -- key = key + (key << 2 )
    key = bxor( key, ( key / 16 ) )     -- key = key ^ (key >>> 4)
    key = key * 2057                    -- key = (key + ( key << 3)) + (key << 11)
    key = bxor( key, ( key / 65536 ) )  -- key = key ^ (key >>> 16)
    return key
end

-- good quality (visually, probably not overall) white noise.
-- output value is between 0 and 1, similar to math.random(). Multiply as needed.
function Noise:whiteNoise( x_in, y_in )
    if self.cached_white[ x_in ] and self.cached_white[ x_in ][ y_in ] then
        return self.cached_white[ x_in ][ y_in ]
    end

    local value =  hash32shift( self.seed + hash32shift( x_in + hash32shift( y_in ) ) )
    -- scale the noise to be between 0 and +1.
    value = value / 2^32

    -- cache the result.
    if not self.cached_white[ x_in ] then
        self.cached_white[ x_in ] = {} -- make sure row exists.
    end
    self.cached_white[ x_in ][ y_in ] = value

    return value
end

return Noise

