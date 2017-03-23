--[[
Based on code from:
http://www.redblobgames.com/pathfinding/a-star/introduction.html
http://www.redblobgames.com/pathfinding/a-star/implementation.html

Depends on a Graph class, providing the following methods:
   getNeighbours( node ): return a list of neighbouring points
   getCost( from_node, to_node ): return the actual cost of moving from first node to second
   getHeuristic( from_node, goal ): return an estimate of cost to goal.

]]

local PathFinder = {}

-- get the folder that we're in.
local IRO_PATH = (...):match("(.+)%.[^%.]+$") or (...)

local PriorityQueue = require( IRO_PATH .. '.priorityqueue' )

function PathFinder:new( ... )
    local instance = {}
    setmetatable( instance, self )
    self.__index = self
    self._init( instance, ... )
    return instance
end

function PathFinder:_init( graph )
    self.graph = graph
end

function PathFinder:getKey( point )
    return point[ 1 ] .. ":" .. point[ 2 ]
end

function PathFinder:astarSearch( start, goal )
    local frontier = PriorityQueue:new( function( a, b ) return a > b end )

    local came_from = {}
    local cost_so_far = {}

    local start_key = self:getKey( start )

    frontier:push( start, 0 )

    cost_so_far[ start_key ] = 0 -- cost for going from start to start is 0

    while not frontier:isEmpty() do
        local current = frontier:pop() -- get node with lowest score

        local current_key = self:getKey( current )
        local current_cost = cost_so_far[ current_key ]

        -- got there. quit trying
        if current[ 1 ] == goal[ 1 ] and current[ 2 ] == goal[ 2 ] then
            break
        end

        local neighbours = self.graph:getNeighbours( current )
        for _, neighbour in ipairs( neighbours ) do
            local neighbour_key = self:getKey( neighbour )
            local new_cost = current_cost + self.graph:getCost( current, neighbour )
            -- no cost yet, or cost is cheaper than previous best
            if not cost_so_far[ neighbour_key ] or new_cost < cost_so_far[ neighbour_key ] then
                cost_so_far[ neighbour_key ] = new_cost
                local h = self.graph:getHeuristic( neighbour, goal )
                local priority = new_cost + h
                frontier:push( neighbour, priority )
                came_from[ neighbour_key ] = current
            end
        end
    end

    return came_from, cost_so_far
end

-- return the path
function PathFinder:reconstructPath( came_from, goal )
    local current = goal
    local back_path = { current }

    while current do
        -- advance a step
        local current_key = self:getKey( current )
        current = came_from[ current_key ]
        table.insert( back_path, current )
    end

    -- reverse that path so it goes from start to end.
    local path = {}
    for i, node in ipairs( back_path ) do
        path[ #back_path - i + 1 ] = node
    end

    return path
end

-- the meat and potatoes function! Call this one.
function PathFinder:getPath( start, goal )
    local came_from, costs = self:astarSearch( start, goal )
    local path = self:reconstructPath( came_from, goal )

    local start_key = self:getKey( start )
    local total_cost = costs[ start_key ]

    return path, total_cost
end



return PathFinder
