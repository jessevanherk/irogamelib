-- basic implementation of a list that can be used as a list or a stack.
-- Original version:
-- http://www.lua.org/pil/11.4.html
-- insert or remove an element at both ends in constant time
--[[

#QUEUE

local Q = List:new()
Q.push( foo )
Q.push( bar )
local next_item = Q.shift()  -- gets foo

#STACK

local Q = List:new()
Q.push( foo )
Q.push( bar )
local next_item = Q.pop() -- gets bar

]]

local List = Class()

function List:_init( ... )
  local arg = { ... }
  self.first = 0
  self.last = -1

  -- allow for constructor to push starting items in, vararg style.
  if ( #arg > 0 ) then
    for _, item in ipairs( arg ) do
      self:push( item )
    end
  end
end

-- get how many items are in our list.
function List:length()
  local length = self.last - self.first + 1
  return length
end

function List:isEmpty()
  local length = self.last - self.first + 1

  local is_empty = false
  if length == 0 then
    is_empty = true
  end

  return is_empty
end

function List:push( value )
  if value then
    local last = self.last + 1
    self.last = last
    self[ last ] = value
  end
end

function List:pop()
  local last = self.last
  if self.first > last then
    return nil
  end

  local value = self[ last ]
  self[ last ] = nil         -- allow garbage collection
  self.last = last - 1

  return value
end

function List:shift()
  local first = self.first
  if first > self.last then
    return nil
  end

  local value = self[ first ]
  self[ first ] = nil        -- allow garbage collection
  self.first = first + 1

  return value
end

-- get the value of the first item without modifying anything
function List:peekFirst()
  local first = self.first
  if first > self.last then
    return nil
  end

  return self[ first ]
end

-- get the value of the nth item without modifying anything
function List:get( n )
  local first = self.first
  if first > self.last then
    return nil
  end

  if n <= 0 or n > self:length() then
    return nil
  end

  return self[ first + n - 1 ]
end

-- get the value of the last item without modifying anything
function List:peekLast()
  local last = self.last
  if self.first > last then
    return nil
  end

  return self[ last ]
end

function List:unshift( value )
  local first = self.first - 1
  self.first = first
  self[ first ] = value
end

function List:entries()
  local entries = {}
  for i = self.first, self.last do
    table.insert( entries, #entries + 1, self[ i ] )
  end

  return entries
end

return List
