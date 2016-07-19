local DiagonalGraph = {}

local abs = math.abs
local min = math.min

function DiagonalGraph:new( ... )
    local instance = {}
    setmetatable( instance, self )
    self.__index = self
    self._init( instance, ... )
    return instance
end

function DiagonalGraph:_init( width, height, values )
    self.width  = width
    self.height = height
    self.values = {}

    print( width, height )
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
-- octile distance is better: D2 = 1.41
function DiagonalGraph:getHeuristic( node, goal )
    local dx = abs( node[ 1 ] - goal[ 1 ] )
    local dy = abs( node[ 2 ] - goal[ 2 ] )
    local h = ( dx + dy ) - 0.58579 * min( dx, dy )
    -- scale h by 1.001 to break ties, make nicer lines, and reduce search space.
    h = h * 1.001
    return h
end

-- get cost to move from current node to target node
function DiagonalGraph:getCost( current, target )
    -- for now, all movement costs are 1.
    local cost = 1

    local x = current[ 1 ]
    local y = current[ 2 ]
    if self.values[ y ] and self.values[ y ][ x ] and self.values[ y ][ x ].terrain == '~' then
        cost = 10
    end

    return cost
end

-- return a list of neighbour positions in no particular order
function DiagonalGraph:getNeighbours( point )
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
    if y < self.width then
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

function DiagonalGraph:getNeighbourValues( point )
    local x = point[ 1 ]
    local y = point[ 2 ]

    local neighbours = self:getNeighbours( point )

    local values = {}
    for _, neighbour in pairs( neighbours ) do
        table.insert( values, self:get( neighbour ) )
    end

    return values
end

return DiagonalGraph
