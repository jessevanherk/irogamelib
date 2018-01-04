
BehaviourTree = Class{}

-- use the entity itself as the blackboard
function BehaviourTree:init( entity, space, tree_function )
  self.space = space
  self.entity = entity

  -- create the coroutine for the behaviour
  self.co = coroutine.create( tree_function )
end

-- advance the behaviour tree coroutine
function BehaviourTree:tick( dt )
  coroutine.resume( self.co )

  -- check if it finished
  if coroutine.status( co ) == "dead" then
    plog("behaviour is dead, removing it")
    -- it returned - see if it was successful
    local status = "success"
    return status
  else
    return "running"
  end
end

-- run a single task (leaf node)
-- this doesn't run anything - it returns a function
-- this should return "success", "failure", or "running"
function BehaviourTree:task( task_name )
  -- look up the task by name
  -- return it, with entity and space as params
  task_fn = function( entity, space ) plog("doing task " .. task_name ) end

  return task_fn
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
