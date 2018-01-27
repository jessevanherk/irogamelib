local GridGraph = {}

local abs = math.abs

function GridGraph:new( ... )
  local instance = {}
  setmetatable( instance, self )
  self.__index = self
  self._init( instance, ... )
  return instance
end

function GridGraph:_init( width, height, values, cost_cb )
  self.width  = width
  self.height = height
  self.values = {}

  self.cost_cb = self.default_cost_cb
  if cost_cb then
    self.cost_cb = cost_cb
  end

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
  local current_value = self:get( current )
  local target_value  = self:get( target )

  local cost = self.cost_cb( current_value, target_value )

  return cost
end

-- return a list of neighbour positions in no particular order
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
  if y < self.height then
    table.insert( neighbours, south )
  end

  return neighbours
end

function GridGraph:getNeighbourValues( point )
  local neighbours = self:getNeighbours( point )

  local values = {}
  for _, neighbour in pairs( neighbours ) do
    table.insert( values, self:get( neighbour ) )
  end

  return values
end

-- by default, movement costs are all 1.
-- this can/should be overloaded.
function GridGraph.default_cost_cb( current_value, target_value )
  return 1
end

return GridGraph
