local SimpleGraph = {}

function SimpleGraph:new( ... )
    local instance = {}
    setmetatable( instance, self )
    self.__index = self
    self._init( instance, ... )
    return instance
end

-- can pas in a table to use as the edges when creating this graph.
function SimpleGraph:_init( edges )
    self.edges = edges or {}
end

function SimpleGraph:getNeighbours( node_id )
    return self.edges[ node_id ]
end

function SimpleGraph:setEdges( edges )
    self.edges = edges
end

return SimpleGraph
