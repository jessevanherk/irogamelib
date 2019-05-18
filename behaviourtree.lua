-- implementation of behaviour trees for AI, using coroutines.
-- a behaviour tree object is initialized with a nested list
-- of nodes.
-- Each node is a pair:
--    node_type: a string representing the node type
--    node_args: a single node, for decorators
--               a list of node, for sequences/etc
-- tasks are the leaf nodes, and take the task name as a string

local BehaviourTree = Class()

-- create a new behaviour tree, but doesn't tick it.
-- tree_root: nested table representing the tree to build
-- context:
--     a table/object containing whatever other data & methods
--     are needed by your tasks. Could be your space/world.
-- blackboard:
--     a table/object used to store data specific to this tree.
--     Could be the associated entity object.
function BehaviourTree:_init( tree_root, available_tasks, context, blackboard )
  self.tasks = available_tasks
  self.context = context
  self.blackboard = blackboard

  assert( tree_root, "tree cannot be nil" )
  assert( available_tasks, "tasks cannot be nil" )

  self.co = self:createCoroutine( tree_root )
end

-- create the coroutine for the behaviour
function BehaviourTree:createCoroutine( tree_root )
  local co = coroutine.create(
    function()
      return self:runNode( tree_root )
    end )

  return co
end

-- advance the behaviour tree coroutine until something yields.
function BehaviourTree:tick( dt )
  local success, result = coroutine.resume( self.co, dt )
  if not success then
    error( result )
  end

  local is_tree_done = false
  if coroutine.status( self.co ) == "dead" then
    is_tree_done = true
  end

  return is_tree_done
end

function BehaviourTree:runNode( node )
  -- make sure we only have one child node
  assert( type( node ) == "table", "node must be a table" )
  assert( type( node[ 1 ] ) == "string", "invalid node format - must be {node_type, children}" )

  -- get the current node type and args
  local node_type, children = unpack( node )

  -- call the appropriate handler method
  local handler = self[ node_type ]
  assert( handler, "unknown node type '" .. node_type .. "'" )

  -- return that method's result, either success or failure
  local result = handler( self, children )

  -- mark the node as done (after running the children)
  node.is_done = true

  return result
end

function BehaviourTree:resetNode( node )
  node.is_done = nil

  local child_nodes = node[ 1 ]
  if type( child_nodes ) == "table" then
    for _, child_node in ipairs( child_nodes ) do
      self:resetNode( child_node )
    end
  end
end

function BehaviourTree:resetNodes( nodes )
  for _, node in ipairs( nodes ) do
    self:resetNode( node )
  end
end

-- run a single task (leaf node)
-- the task function should return true, false, or yield to indicate "running"
function BehaviourTree:task( task_name )
  -- look up the task by name
  task_fn = self.tasks[ task_name ]
  assert( task_fn, "unknown task name '" .. tostring(task_name) .. "'" )

  -- actually run the task.
  local result = task_fn( self.blackboard, self.context )

  -- nil result is treated as success, for when task doesn't explicitly return.
  if result == nil then
    return true
  end

  if result == false then
    return false
  end

  return true
end

function BehaviourTree:getPendingNodes( nodes )
  local pending_nodes = {}

  for _, node in ipairs( nodes ) do
    if not node.is_done then
      pending_nodes[ #pending_nodes + 1 ] = node
    end
  end

  return pending_nodes
end

-- run each node in order, until a failure
function BehaviourTree:sequence( child_nodes )
  local pending_nodes = self:getPendingNodes( child_nodes )

  for _, node in ipairs( pending_nodes ) do
    local child_result = self:runNode( node )
    if child_result == false then
      -- stop processing. and return failure
      return false
    end
  end

  return true
end

-- this should only ever be the root node
function BehaviourTree:repeatSequence( child_nodes )
  while true do
    self:sequence( child_nodes )

    self:resetNodes( child_nodes )

    -- only want to run the sequence once per tick.
    -- avoid spinloop by yielding out
    coroutine.yield()
  end
end

-- run child nodes until one succeeded
function BehaviourTree:any( child_nodes )
  local pending_nodes = self:getPendingNodes( child_nodes )

  for _, node in ipairs( pending_nodes ) do
    local child_result = self:runNode( node )
    if child_result == true then
      -- stop processing. and return success
      return true
    end
  end

  return false
end

-- decorators

function BehaviourTree:succeed( children )
  self:runNode( children[ 1 ] )
  return true
end

function BehaviourTree:fail( children )
  self:runNode( children[ 1 ] )
  return false
end

function BehaviourTree:invert( children )
  local result = self:runNode( children[ 1 ] )
  return not result
end

-- this mainly exists for testing, and for succeed/fail with no actual child.
function BehaviourTree:noop()
  return nil
end

-- this mainly exists for testing
function BehaviourTree:yield()
  coroutine.yield()
end

return BehaviourTree
