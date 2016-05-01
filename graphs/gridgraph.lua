local GridGraph = {}

local abs = math.abs

function GridGraph:new( ... )
    local instance = {}
    setmetatable( instance, self )
    self.__index = self
    self._init( instance, ... )
    return instance
end

function GridGraph:_init( width, height, values )
    self.width  = width
    self.height = height
    self.values = {}

    for j = 1, height do
        self.values[ j ] = {}
        for i = 1, width do
            if values[ j ][ i ] then
                self.values[ j ][ i ] = values[ j ][ i ]
            end
        end
    end
end

function GridGraph:get( point )
    local value = nil
    local x, y = point[ 1 ], point[ 2 ]
    if x >= 1 and x <= self.width and y >= 1 and y <= self.height then
        if self.values[ y ] then
            value = self.values[ y ][ x ]
        end
    end
    return value
end

function GridGraph:set( point, value )
    local x, y = point[ 1 ], point[ 2 ]
    if x >= 1 and x <= self.width and y >= 1 and y <= self.height then
        if not self.values[ y ] then
            self.values[ y ] = {}
        end
        self.values[ y ][ x ] = value
    end
end

-- manhattan distance(?)
function GridGraph:getHeuristic( node, goal )
    local dx = abs( node[ 1 ] - goal[ 1 ] )
    local dy = abs( node[ 2 ] - goal[ 2 ] )
    local h = dx + dy
    -- scale h by 1.001 to break ties, make nicer lines, and reduce search space.
    h = h * 1.001
    return h
end

-- get cost to move from current node to target node
function GridGraph:getCost( current, target )
    -- for now, all movement costs are 1.
    local cost = 1

    local x = current[ 1 ]
    local y = current[ 2 ]
    if self.values[ y ] and self.values[ y ][ x ] and self.values[ y ][ x ].terrain == '~' then
        cost = 20
    end

    return cost
end


function GridGraph:getNeighbours( point )
    local neighbours = {}

    local x = point[ 1 ]
    local y = point[ 2 ]

    local north = { x, y - 1 }
    local south = { x, y + 1 }
    local east  = { x + 1, y }
    local west  = { x - 1, y }

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

    return neighbours
end

return GridGraph
