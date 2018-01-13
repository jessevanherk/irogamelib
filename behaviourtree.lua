-- implementation of behaviour trees for AI, using coroutines. 
-- a behaviour tree object is initialized with a nested list
-- of nodes.
-- Each node is a pair: a string represnting the node type, and:
-- a single node, for decorators
-- a list of node, for sequences/etc
-- tasks are the leaf nodes, and take the task name as a string

BehaviourTree = {}

-- magic constructor for the system. real init code goes in init().
function BehaviourTree:new( ... )
  local instance = {}
  setmetatable( instance, self )
  self.__index = self
  self._init( instance, ... )
  return instance
end

-- create a new behaviour tree.
-- this doesn't do any tick
-- context is a table/object contaiming whatever other data/methods
-- are needed by your tasks. Could be your space/world.
-- blackboard is a table/object used to store data specific to
-- this tree. Could be your entity object.
function BehaviourTree:_init( tree_root, available_tasks, context, blackboard )
  self.tasks = available_tasks
  self.context = context
  self.blackboard = blackboard

  assert( tree_root, "tree cannot be nil" )
  assert( available_tasks, "tasks cannot be nil" )

  -- create the coroutine for the behaviour
  self.co = coroutine.create( 
    function()
      return self:runNode( tree_root )
    end )
end

-- advance the behaviour tree coroutine
function BehaviourTree:tick( dt )
  local is_running = true
  local result = coroutine.resume( self.co, dt )

  -- check if it finished
  if coroutine.status( co ) == "dead" then
    plog("behaviour is dead, it should be removed")
    is_running = false
  end

  return is_running
end

function BehaviourTree:runNode( node )
  -- get the current node type and args
  local node_type, arguments = unpack( node )

  -- call the appropriate handler method
  local handler = self[ node_type ]
  assert( handler, "unknown node type '" .. node_type .. "'" )

  -- return that method's result, either success or failure
  return handler( self, arguments )
end

-- run a single task (leaf node)
-- this should return true or false
-- or yield to indicate "running"
function BehaviourTree:task( task_name )
  -- look up the task by name
  task_fn = self.tasks[ task_name ]
  assert( task_fn, "unknown task name '" .. task_name .. "'" )

  -- actually run the task.
  -- nil result is treated as success.
  local result = task_fn( self.blackboard, self.context )
  if result ~= nil and result == false then
    return false
  end

  return true
end

-- run each node in order, until a failure
function BehaviourTree:sequence( child_nodes )
  for _, node in ipairs( child_nodes ) do
    local child_result = self:runNode( node )
    if child_result == false then
      -- stop processing. and return failure
      return false
    end
  end
  
  return true
end

-- this should only ever be the root node
-- FIXME: detect spinloops and error out
function BehaviourTree:repeatSequence( child_nodes )
  while true do
    self:sequence( child_nodes )

    -- only want to run the sequence once per tick.
    -- avoid spinloop by yielding out
    coroutine.yield()
  end
  
  return true
end

-- run child nodes until one succeeded
function BehaviourTree:any( child_nodes )
  for _, node in ipairs( child_nodes ) do
    local child_result = self:runNode( node )
    if child_result == true then
      -- stop processing. and return success
      return true
    end
  end

  return false
end

-- decorators

function BehaviourTree:succeed( child )
  local result = self:runNode( child )
  return true
end

function BehaviourTree:fail( child )
  local result = self:runNode( child )
  return false
end

function BehaviourTree:invert( child )
  local result = self:runNode( child )
  return not result
end

return BehaviourTree
