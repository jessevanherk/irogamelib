local RoadGraph = {}

local abs = math.abs
local min = math.min
local max = math.max
local sqrt = math.sqrt

function RoadGraph:new( ... )
    local instance = {}
    setmetatable( instance, self )
    self.__index = self
    self._init( instance, ... )
    return instance
end

function RoadGraph:_init( width, height, values )
    self.width  = width
    self.height = height
    self.values = {}

    for j = 1, height do
        self.values[ j ] = {}
        for i = 1, width do
            if values and values[ j ] and values[ j ][ i ] then
                self.values[ j ][ i ] = values[ j ][ i ]
            end
            -- else leave it as nil, so we can have a sparse array.
        end
    end
end

-- general heuristic function is:
-- h = D * ( dx + dy ) + ( D2 - 2*D ) * min( dx, dy )
-- where D is the cost to move orthoganally, and D2 is the cost to move diagonally.
-- chebyshev distance - assumes diagonal distance cost is also 1.
-- octile distance is better.
function RoadGraph:getHeuristic( node, goal )
    local dx = abs( node[ 1 ] - goal[ 1 ] )
    local dy = abs( node[ 2 ] - goal[ 2 ] )
    local h = sqrt( dx*dx + dy*dy )

    -- scale h by 1.001 to break ties, make nicer lines, and reduce search space.
    h = h * 1.001
    return h
end

--[[
 get cost to move from current node to target node
 calculate the actual cost based on time taken to travel.
 t = d / v
 v depends on slope, or on dz.
 d = sqrt( dx^2 + dy^2 ) 
 m = dz / d
 v = 1 / dz

 t = sqrt( dx^2 + dy^2 ) * dz

]]--
function RoadGraph:getCost( current, target )
    local x1 = current[ 1 ]
    local y1 = current[ 2 ]
    local x2 = target[ 1 ]
    local y2 = target[ 2 ]

    local dx = x2 - x1
    local dy = y2 - y1

    -- early exit if start and end points are the same.
    if dx == 0 and dy == 0 then
        return 0
    end

    local height1 = self.values[ y1 ][ x1 ].elevation
    local height2 = self.values[ y2 ][ x2 ].elevation

    -- anything underwater is treated as a height of 0, since we travel on the surface.
    if height1 < 0 then height1 = 0 end
    if height2 < 0 then height2 = 0 end

    -- deal with absolute elevation change - assume we have to go slow down steep slopes too.
    local dz = abs( height2 - height1 )

    local speed = 1 / ( 1 + 32 * dz ) -- shift to be between [1-2] and scale so we slow down faster
    if height2 == 0 then -- move onto water costs more.
        speed = 0.125
    end

    local cost = sqrt( dx*dx + dy*dy ) / speed

    return cost
end


function RoadGraph:getNeighbours( point )
    local neighbours = {}

    local x = point[ 1 ]
    local y = point[ 2 ]

    local north = { x, y - 1 }
    local south = { x, y + 1 }
    local east  = { x + 1, y }
    local west  = { x - 1, y }
    local northeast = { x + 1, y - 1 }
    local northwest = { x - 1, y - 1 }
    local southeast = { x + 1, y + 1 }
    local southwest = { x - 1, y + 1 }

    -- orthogonals
    if x > 1 then
        table.insert( neighbours, west )
    end
    if x < self.width then
        table.insert( neighbours, east )
    end
    if y > 1 then
        table.insert( neighbours, north )
    end
    if y < self.height then
        table.insert( neighbours, south )
    end

    -- diagonals
    if y > 1 then
        if x > 1 then
            table.insert( neighbours, northwest )
        end
        if x < self.width then
            table.insert( neighbours, northeast )
        end
    end
    if y < self.height then
        if x > 1 then
            table.insert( neighbours, southwest )
        end
        if x < self.width then
            table.insert( neighbours, southeast )
        end
    end

    return neighbours
end

function RoadGraph:getNeighbourValues( point )
    local x = point[ 1 ]
    local y = point[ 2 ]

    local neighbours = self:getNeighbours( point )

    local values = {}
    for _, neighbour in pairs( neighbours ) do
        table.insert( values, self:get( neighbour ) )
    end

    return values
end

return RoadGraph
