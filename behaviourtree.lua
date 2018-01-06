-- implementation of behaviour trees for AI,
-- using coroutines. 
-- a behaviour tree object is initialized with an
-- anonymous function representing the tree.
-- tasks are the leaf nodes, and are referenced
-- by name.

BehaviourTree = Class{}

-- use the entity itself as the blackboard
function BehaviourTree:init( tree_root, available_tasks, space, entity )
  self.tasks = available_tasks
  self.space = space
  self.entity = entity

  -- create the coroutine for the behaviour
  self.co = coroutine.create( function() return self:runTree( tree_root ) end )
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

function BehaviourTree:runTree( tree )
  -- get the current node type
  local node = tree[ 1 ]
  local node_type = node[ 1 ]
  -- parse out the rest of the args
  local arguments = node[ 2 ]

  -- call the appropriate handler method
  local handler = self[ node_type ]
  assert( handler, "unknown node type '" .. node_type .. "'" )

  -- return that method's result, either success or failure
  return handler( arguments )
end

-- run a single task (leaf node)
-- this should return "success", "failure",
-- or yield to indicate "running"
function BehaviourTree:task( task_name )
  -- look up the task by name
  task_fn = self.tasks[ task_name ]
  assert( task_fn, "unknown task name '" .. task_name .. "'" )

  -- actually run the task.
  -- nil return result is treated as success.
  local result = task_fn( self.entity, self.space )
  if result ~= nil and result == false then
    return false
  end

  return true
end

-- sequence methods

-- run each node in order, until a failure
function BehaviourTree:sequence( child_nodes )
  for _, node in ipairs( child_nodes ) do
    local result = self:runTree( node )
    if result == false then
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
    for _, node in ipairs( child_nodes ) do
      local result = self:runTree( node )
      if result == false then
        -- stop processing. and return failure
        return false
      end
    end
  end
  
  return true
end

-- run child nodes until one succeeded
function BehaviourTree:any( child_nodes )
  for _, node in ipairs( child_nodes ) do
    local child_result = self:runTree( node )
    if child_result == true then
      -- stop processing. and return success
      return true
    end
  end

  return false
end

-- decorators

function BehaviourTree:succeed( child )
  local result = self:runTree( child )
  return true
end

function BehaviourTree:fail( child )
  local result = self:runTree( child )
  return false
end

function BehaviourTree:invert( child )
  local result = self:runTree( child )
  return not result
end

return BehaviourTree
