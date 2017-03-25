--[[
Poisson Disk Sampling.
Based on code and algorithm from:
http://devmag.org.za/2009/05/03/poisson-disk-sampling/

num_tries = 1 : will probably only ever return then starting point.
num_tries <= 6: will likely stop and only return a small set of samples
num_tries = 10: will provide nice dispersed "organic" looking samples
num_tries = 20: fairly dense but with some empty pockets.
num_tries = 30: will provide nice dense cluster of points
num_tries > 30: doesn't really add much, other than slowing things down.
]]--

PoissonDisk = {}

local cos = math.cos
local sin = math.sin
local ceil = math.ceil
local tau = 2 * math.pi

-- just the distance formula. Ignore the square root, because we only want to
-- do a simple comparison, and it's easier to square our min distance than to take a square root.
-- OUTSIDE of our class for (very minor) performance reasons.
local function getDistanceSquared( p1, p2 )
  local dx = p2[ 1 ] - p1[ 1 ]
  local dy = p2[ 2 ] - p2[ 2 ]
  local distance = dx * dx + dy * dy

  return distance
end

function PoissonDisk:new( ... )
  local instance = {}
  setmetatable( instance, self )
  self.__index = self
  self._init( instance, ... )

  return instance
end

function PoissonDisk:_init( width, height, min_distance )
  self.width = width
  self.height = height
  self.min_distance = min_distance
  self.min_distance_squared = min_distance * min_distance

  local dimensions = 2
  -- set grid cell size so the diagonal is min_dinstance
  -- that way there can't ever be more than one sample in it.
  self.cell_size = self.min_distance / math.sqrt( dimensions )

  self.grid_width  = ceil( self.width / self.cell_size )
  self.grid_height = ceil( self.height / self.cell_size )

  self.grid = self:createGrid()
end

function PoissonDisk:createGrid()
  local grid = {}

  for j = 1, self.grid_height do
    grid[ j ] = {}
    for i = 1, self.grid_width do
      grid[ j ][ i ] = -1
    end
  end

  return grid
end

function PoissonDisk:getNearbyCells( grid_point )
  local cells = {}

  local radius = 2 -- two to the left plus center plus two to the right = 5
  local x = grid_point[ 1 ]
  local y = grid_point[ 2 ]

  local min_i = 1
  local min_j = 1
  local max_i = self.grid_width
  local max_j = self.grid_height

  if x > radius then
    min_i = x - radius
  end
  if y > radius then
    min_j = y - radius
  end
  if x <= self.grid_width - radius then
    max_i = x + radius
  end
  if y <= self.grid_height - radius then
    max_j = y + radius
  end

  local grid = self.grid

  for j = min_j, max_j do
    for i = min_i, max_i do
      local cell = grid[ j ][ i ]
      -- only insert nearby cells IF they already have a value.
      -- this can't be cached, careful!!
      if cell ~= -1 then
        cells[ #cells + 1 ] = cell
      end
    end
  end

  return cells
end

-- convert from real-space to grid-space coordinates
function PoissonDisk:getGridCoordinates( point )
  -- using ceil because lua grid is indexed from 1.
  local i = ceil( point[ 1 ] / self.cell_size )
  local j = ceil( point[ 2 ] / self.cell_size )
  return { i, j }
end

--[[
Two parameters determine the new point’s position:
the angle (randomly chosen between 0 and 360 degrees), and the distance from
the original point (randomly chosen between the minimum distance and twice
the minimum distance).
]]--

function PoissonDisk:generateNearbyPoint( point )
  --random angle
  local angle = tau * math.random()

  --random radius between min_distance and 2*min_distance
  local radius = self.min_distance * ( math.random() + 1 )

  --the new point is generated around the point (x, y)
  local new_x = point[ 1 ] + radius * cos( angle )
  local new_y = point[ 2 ] + radius * sin( angle )
  local new_point = { new_x, new_y }

  return new_point
end

function PoissonDisk:isInBounds( point )
  local is_in_bounds = false
  local x = point[ 1 ]
  local y = point[ 2 ]
  if x > 0 and x <= self.width and y > 0 and y <= self.height then
    is_in_bounds = true
  end

  return is_in_bounds
end

--[[
Before a newly generated point is admitted as a sample point, we have to
check that no previously generated points are too close.  Because of the
radius chosen, we need to check a 5x5 section of the grid, centered on our
point.
We don't actually need to check the 4 corner cells, but it simplifies
the algorithm to check all 25 cells. 
]]--
function PoissonDisk:hasNearbySample( point, grid_point )
  local has_nearby_sample = false

  --get the neighbourhood if the point in the grid
  local nearby_cells = self:getNearbyCells( grid_point )

  local cell = nil
  for i = 1, #nearby_cells do
    cell = nearby_cells[ i ]
    if getDistanceSquared( cell, point ) < self.min_distance_squared then
      has_nearby_sample = true
      break -- only need to detect one.
    end
  end

  return has_nearby_sample
end

-- getBalancedSamples attempts to improve generation of points when we're not filling
-- the entire space. Good for placing towns in a nation, buildings in a town, etc.
function PoissonDisk:getBalancedSamples( source )
  local min_points = source.min_points
  local num_tries = source.num_tries or 30

  local first_point = { source.x, source.y }
  local grid_point = self:getGridCoordinates( first_point )

  -- create lists, pre-seeded with first point.
  local sample_points = { first_point }
  local active_points = { first_point }

  local grid_i = grid_point[ 1 ]
  local grid_j = grid_point[ 2 ]
  self.grid[ grid_j ][ grid_i ] = first_point

  while ( #sample_points < min_points ) do -- go until we get at least that many points.
  local new_points = {}
  --generate other points from points in queue.
  while #active_points > 0 do
    -- pick random item from list.
    local chosen_i = math.random( #active_points )
    point = active_points[ chosen_i ]
    -- TRICKY BIT to avoid table.remove and avoid costly table rebuilds.
    -- move the LAST item to chosen_i, then nil out the LAST spot.
    -- this is ONLY okay because we're choosing values to read randomly anyway!
    active_points[ chosen_i ] = active_points[ #active_points ]
    active_points[ #active_points ] = nil

    for p = 1, num_tries do
      local new_point = self:generateNearbyPoint( point )
      --check that the point is in the overall region bounds
      local is_in_bounds = self:isInBounds( new_point )
      if is_in_bounds then -- check this FIRST to avoid expensive computation.
        -- check that no points exists in the point's neighbourhood
        local new_grid_point = self:getGridCoordinates( new_point )
        local has_nearby_sample = self:hasNearbySample( new_point, new_grid_point )

        if not has_nearby_sample then
          -- add it to our list of new points, which we don't pick from until later
          new_points[ #new_points + 1 ] = new_point
          -- add it to the output.
          sample_points[ #sample_points + 1 ] = new_point
          -- record it in the grid.
          self.grid[ new_grid_point[ 2 ] ][ new_grid_point[ 1 ] ] = new_point
        end
      end
    end
  end
  -- out of active points by now.
  if #new_points == 0 then
    break -- can't go any further. quit trying.
  end
  -- swap in our list of new points and run through everything again.
  active_points = new_points
end

return sample_points
end

-- getSampleSets gets multiple sets of sample points,
-- preventing them from overlapping each other.
-- they share a grid.
function PoissonDisk:getSampleSets( sources )
  local sample_sets = {}

  for _, source in ipairs( sources ) do
    local set_points = self:getBalancedSamples( source )

    table.insert( sample_sets, set_points )
  end

  return sample_sets
end

return PoissonDisk
