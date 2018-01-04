-- implementation of behaviour trees for AI,
-- using coroutines. 
-- a behaviour tree object is initialized with an
-- anonymous function representing the tree.
-- tasks are the leaf nodes, and are referenced
-- by name.

BehaviourTree = Class{}

-- use the entity itself as the blackboard
function BehaviourTree:init( tree_function, available_tasks, space, entity )
  self.tasks = available_tasks
  self.space = space
  self.entity = entity

  -- create the coroutine for the behaviour
  self.co = coroutine.create( tree_function )
end

-- advance the behaviour tree coroutine
function BehaviourTree:tick( dt )
  local result = coroutine.resume( self.co, dt )

  -- check if it finished
  if coroutine.status( co ) == "dead" then
    plog("behaviour is dead, removing it")
    -- it returned - see if it was successful
    local status = "success"
    -- only explicit false is considered failure
    if result == false then
      status = "failure"
    end

    return status
  else
    return "running"
  end
end

-- run a single task (leaf node)
-- this should return "success", "failure",
-- or yield to indicate "running"
function BehaviourTree:task( task_name )
  -- look up the task by name
  task_fn = self.tasks[ task_name ]
  assert( task_fn, "unknown task '" .. task_name .. "'" )

  return task_fn( self.entity, self.space )
end

-- sequence methods

function BehaviourTree:sequence( ... )
  -- 
  

end

function BehaviourTree:repeatSequence( ... )

end

function BehaviourTree:any( ... )

end

-- decorators

function BehaviourTree:succeed( child )

end

function BehaviourTree:fail( child )

end

function BehaviourTree:invert( child )

end

return BehaviourTree
