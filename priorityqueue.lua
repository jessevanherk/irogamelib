--[[
Usage:
  new( comparator ):
      comparator (optional): Use this function to compare values.
            Default sorts numerically, putting HIGHEST numbers at the start of the queue.
            Comparator takes two values and returns true if the first should be further up, false otherwise
  new( comparator, values, priorities ):
      comparator: same as above. nil to use default comparator.
      values: Table to use as the values
      priorities: Table to use as the priorities
  clone(): Create and return a copy of the PriorityQueue
  push( value, priority ): push a new item onto the PriorityQueue
  pop():   Get and remove the highest priority value from the queue
  peek():  Get the highest priority value from the queue but don't remove it. returns nil if queue is empty
  clear(): clear the PriorityQueue
  print( show_priorities ): prints out all the elements in the PriorityQueue
      show_priorities: If true, also print the priorities
  size(): Get the number of elements in the PriorityQueue
  isEmpty(): return true if the queue is empty, false otherwise.
]]--

PriorityQueue = {}
PriorityQueue.__index = PriorityQueue

local floor = math.floor

function PriorityQueue:new( ... )
    local instance = {}
    setmetatable( instance, self )
    self.__index = self
    self._init( instance, ... )

    return instance
end

function PriorityQueue.defaultCompare( a, b )
    return a < b
end

function PriorityQueue:_init( comparator, values, priorities )
    self.compare = self.defaultCompare
    if comparator then
        assert( type( comparator ) == 'function', "comparator must be a function" )
        self.compare = comparator
    end
    
    self.values = {}
    self.priorities = {}

    -- if values/priorities passed in, add them as start values.
    if values then
        for i = 1, #values do
            if priorities[ i ] then
                self:push( values[ i ], priorities[ i ] )
            end
        end
    end
end

function PriorityQueue:clone()
    local new_queue = PriorityQueue:new( self.compare )
    for i = 1, #self.values do
        table.insert( new_queue.values, self.values[ i ] )
        table.insert( new_queue.priorities, self.priorities[ i ] )
    end
    return new_queue
end


function PriorityQueue:siftUp( index )
    local parent_index
    if index ~= 1 then
        parent_index = floor( index / 2 )
        if self.compare( self.priorities[ parent_index ], self.priorities[ index ] ) then
            -- swap the items. done as list assignment to avoid temp variables.
            self.values[ parent_index ], self.values[ index ] = self.values[ index ], self.values[ parent_index ]
            self.priorities[ parent_index ], self.priorities[ index ] = self.priorities[ index ], self.priorities[ parent_index ]

            -- continue sifting from the new location.
            self:siftUp( parent_index )
        end
    end
end

function PriorityQueue:siftDown( index )
    local left_index, right_index, min_index
    left_index = index * 2
    right_index = index * 2 + 1
    if right_index > #self.values then
        if left_index > #self.values then
            return
        else
            min_index = left_index
        end
    else
        if not self.compare( self.priorities[ left_index ], self.priorities[ right_index ] ) then
            min_index = left_index
        else
            min_index = right_index
        end
    end
    
    if self.compare( self.priorities[ index ], self.priorities[ min_index ] ) then
        -- swap the items. done as list assignment to avoid temp variables.
        self.values[ min_index ], self.values[ index ] = self.values[ index ], self.values[ min_index ]
        self.priorities[ min_index ], self.priorities[ index ] = self.priorities[ index ], self.priorities[ min_index ]

        -- continue sifting from new position.
        self:siftDown( min_index )
    end
end

function PriorityQueue:push( value, priority )
    if not value then
        return
    end

    table.insert( self.values, value )
    table.insert( self.priorities, priority )
    
    if #self.values <= 1 then
        -- don't need to sift if only one item
        return
    end
    
    self:siftUp( #self.values )
end

function PriorityQueue:pop()
    if #self.values <= 0 then
        return nil, nil
    end
    
    -- highest priority item is always kept at the start of the arrays.
    local return_val = self.values[ 1 ]
    local return_priority = self.priorities[ 1 ]

    self.values[ 1 ]     = self.values[ #self.values ]
    self.priorities[ 1 ] = self.priorities[ #self.priorities ]

    table.remove(self.values, #self.values)
    table.remove(self.priorities, #self.priorities)
    if #self.values > 0 then
        self:siftDown( 1 )
    end
    
    return return_val, return_priority
end

function PriorityQueue:peek()
    if #self.values > 0 then
        return self.values[ 1 ], self.priorities[ 1 ]
    else
        return nil, nil
    end
end

-- return all values in sorted order. empties the list!!!
function PriorityQueue:popAll()
    local sorted = {}
    while not self:isEmpty() do
        local item = self:pop()
        table.insert( sorted, #sorted + 1, item )
    end

    return sorted
end

function PriorityQueue:clear()
    for k in pairs( self.values ) do
        self.values[ k ] = nil
    end
    for k in pairs( self.priorities ) do
        self.priorities[ k ] = nil
    end
end

-- NOTE that this does not do sorting - this prints them in memory order!!
function PriorityQueue:print( show_priorities )
    if show_priorities then
        local output = ""
        for i = 1, #self.values do
            output = output .. tostring(self.values[i]) .. "(" .. tostring(self.priorities[i]) .. ")\n"
        end
        print(output)
    else
        local output = ""
        for i = 1, #self.values do
            output = output .. tostring(self.values[i]) .. "\n"
        end
        print(output)
    end
end

function PriorityQueue:size()
    return #self.values
end

function PriorityQueue:isEmpty()
    local is_empty = false
    if ( #self.values == 0 ) then
        is_empty = true
    end

    return is_empty
end

return PriorityQueue
