-- spec script. should NOT be bundled with final game.
--

require( "spec.spec_helper" )

BehaviourTree = require( "behaviourtree" )

describe( "BehaviourTree", function()
  local test_tasks = {
    return_nil    = function() return nil end,
    return_true   = function() return true end,
    return_false  = function() return false end,
    return_string = function() return "something" end,
    return_zero   = function() return 0 end,
    set_value     = function( blackboard ) blackboard.value = "I got set" end,
    update_value  = function( blackboard ) blackboard.value = "This is better" end,
    clear_value   = function( blackboard ) blackboard.value = nil end,
    do_yield      = function() coroutine.yield() end,
  }
  local tree = BehaviourTree:new( {}, test_tasks, {}, {} )

  describe( "#new", function()
    context( "when no tree data is provided", function()
      it( "throws an error", function()
        local expected = "tree cannot be nil"
        assert.has_error( function() BehaviourTree:new() end, expected )
      end)
    end)

    context( "when tree is present", function()
      local tree_root = {}

      context( "when tasks is nil", function()
        it( "throws an error", function()
          local expected = "tasks cannot be nil"
          assert.has_error( function() BehaviourTree:new( tree_root ) end, expected )
        end)
      end)
    end)

    context( "when parameters are all valid", function()
      local tree_root = {}
      local available_tasks = {}
      local context = { foo = 42 }
      local blackboard = { something = "okay" }

      local new_tree = BehaviourTree:new( tree_root, available_tasks, context, blackboard )

      it( "has the expected tasks", function()
        assert.is.equal( available_tasks, new_tree.tasks )
      end)

      it( "has a context", function()
        assert.is.equal( context, new_tree.context )
      end)

      it( "has a blackboard", function()
        assert.is.equal( blackboard, new_tree.blackboard )
      end)

      it( "has a valid coroutine", function()
        assert.is.not_nil( new_tree.co )
        assert.is.equal( "suspended", coroutine.status( new_tree.co ) )
      end)
    end)

    context( "when behaviour tree was in progress", function()
      local tree_data = {
        "sequence", {
            { "sequence", {
                { "task", "set_value", is_done = true },
                { "task", "do_yield" },
                { "task", "update_value" },
                { "task", "clear_value" },
              }
            },
            { "sequence", {
                { "task", "return_true" },
                { "task", "do_yield" },
                { "task", "return_true" },
              }
            },
          },
      }
      local context = {}
      local blackboard = { value = "From reloaded data" }

      it( "should not run nodes that are marked as done", function()
        local resumed_tree = BehaviourTree:new( tree_data, test_tasks, context, blackboard )
        resumed_tree:tick( 0 )

        assert.is_equal( "From reloaded data", blackboard.value )
      end)
      it( "should start at the node marked as running", function()
      end)
    end)
  end)

  describe( "#tick", function()
    context( "when coroutine is already dead", function()
      local nodes = {
        { "noop", {} },
      }
      local dead_tree = BehaviourTree:new( nodes, test_tasks, {}, {} )
      coroutine.resume( dead_tree.co ) -- run it manually, get it to dead.

      it( "throws an error", function()
        local expected = "cannot resume dead coroutine"
        assert.has_error( function() dead_tree:tick( 0 ) end, expected )
      end)
    end)

    context( "when coroutine is not dead", function()
      context( "when tree completes", function()
        local nodes = { "noop", {} }
        local done_tree = BehaviourTree:new( nodes, test_tasks, {}, {} )

        it( "returns true", function()
          local result = done_tree:tick( 0 )
          assert.is.equal( true, result )
        end)
      end)

      context( "when task yielded", function()
        local nodes = { "yield", {} }

        local sleepy_tree = BehaviourTree:new( nodes, test_tasks, {}, {} )

        it( "returns false", function()
          local result = sleepy_tree:tick( 0 )
          assert.is.equal("suspended", coroutine.status( sleepy_tree.co ) )
          assert.is.equal( false, result )
        end)
      end)
    end)
  end)

  describe( "#runNode", function()
    context( "when node is valid", function()
      local node = { "task", "return_false" }

      it( "does not throw an error", function()
        assert.has_no_error( function() tree:runNode( node ) end )
      end)
    end)

    context( "when node is nil", function()
      local node = nil

      it( "throws an error", function()
        local expected = "node must be a table"
        assert.has_error( function() tree:runNode( node ) end, expected )
      end)
    end)

    context( "when node is not a table", function()
      local node = "not_a_table"

      it( "throws an error", function()
        local expected = "node must be a table"
        assert.has_error( function() tree:runNode( node ) end, expected )
      end)
    end)

    context( "when passed multiple nodes", function()
      local nodes = { nil, "not_a_node" }
      it( "throws an error", function()
        local expected = "invalid node format - must be {node_type, children}"
        assert.has_error( function() tree:runNode( nodes ) end, expected )
      end)
    end)
  end)

  describe( "#task", function()
    context( "when task name is nil", function()
      local task_name = nil

      it( "throws an error", function()
        local expected = "unknown task name 'nil'"
        assert.has_error( function() tree:task( task_name ) end, expected )
      end)
    end)

    context( "when task name is a string", function()
      context( "when the task name is not found", function()
        local task_name = "no_such_task"

        it( "throws an error", function()
          local expected = "unknown task name 'no_such_task'"
          assert.has_error( function() tree:task( task_name ) end, expected )
        end)
      end)

      context( "when the task name exists", function()
        it( "runs the task", function()
          local task_name = "return_true"
          spy.on( test_tasks, task_name )

          tree:task( task_name )
          assert.spy( test_tasks[ task_name ] ).was.called_with( tree.blackboard, tree.context )

          test_tasks[ task_name ]:revert()
        end)

        context( "when the task returns true", function()
          local task_name = "return_true"

          it( "returns true", function()
            local result = tree:task( task_name )
            assert.is.equal( true, result )
          end)
        end)

        context( "when the task returns false", function()
          local task_name = "return_false"

          it( "returns false", function()
            local result = tree:task( task_name )
            assert.is.equal( false, result )
          end)
        end)

        context( "when the task returns nil", function()
          local task_name = "return_nil"

          it( "returns true", function()
            local result = tree:task( task_name )
            assert.is.equal( true, result )
          end)
        end)

        context( "when the task returns zero", function()
          local task_name = "return_zero"

          -- in lua, all values other than nil and false are truthy.
          it( "returns true", function()
            local result = tree:task( task_name )
            assert.is.equal( true, result )
          end)
        end)

        context( "when the task returns a misc truthy value", function()
          local task_name = "return_string"

          it( "returns true", function()
            local result = tree:task( task_name )
            assert.is.equal( true, result )
          end)
        end)
      end)
    end)
  end)

  describe( "#sequence", function()
    context( "when all nodes succeed", function()
      local nodes = {
        { "task", "return_true" },
        { "task", "return_true" },
        { "task", "return_true" },
      }

      it( "runs all nodes", function()
        spy.on( tree, "runNode" )

        tree:sequence( nodes )
        assert.spy( tree.runNode ).was.called( 3 )

        tree.runNode:revert()
      end)

      it( "returns true", function()
        local result = tree:sequence( nodes )
        assert.is.equal( true, result )
      end)
    end)

    context( "when a node fails", function()
      local nodes = {
        { "succeed", {{ "noop", {} }} },
        { "task", "return_false" },
        { "invert", {{ "noop", {} }} },
      }

      it( "runs all of the preceding nodes", function()
        spy.on( tree, "task" )
        spy.on( tree, "succeed" )

        tree:sequence( nodes )
        assert.spy( tree.succeed ).was.called( 1 )
        assert.spy( tree.task ).was.called( 1 )

        tree.task:revert()
        tree.succeed:revert()
      end)

      it( "doesn't run any of the following nodes", function()
        spy.on( tree, "invert" )

        tree:sequence( nodes )
        assert.spy( tree.invert ).was.called( 0 )

        tree.invert:revert()
      end)

      it( "returns false", function()
        local result = tree:sequence( nodes )
        assert.is_false( result )
      end)
    end)
  end)

  describe( "#repeatSequence", function()
    context( "when sequence yields", function()
      local nodes = {
        { "task", "return_true" },
        { "yield", {} },
        { "noop", {} },
      }

      it( "runs the preceding tasks", function()
        spy.on( tree, "task" )

        local co = coroutine.create( function() tree:repeatSequence( nodes ) end)
        coroutine.resume( co )

        assert.spy( tree.task ).was.called( 1 )

        tree.task:revert()
      end)

      it( "does not run the following tasks", function()
        spy.on( tree, "noop" )

        local co = coroutine.create( function() tree:repeatSequence( nodes ) end)
        coroutine.resume( co )

        assert.spy( tree.noop ).was.called( 0 )

        tree.noop:revert()
      end)
    end)

    context( "when sequence doesn't yield", function()
      local nodes = {
        { "task", "return_true" },
      }

      it( "runs the sequence once", function()
        spy.on( tree, "runNode" )

        local co = coroutine.create( function() tree:repeatSequence( nodes ) end)
        coroutine.resume( co )

        assert.spy( tree.runNode ).was.called( 1 )

        tree.runNode:revert()
      end)

      it( "yields", function()
        stub( tree, "sequence" )

        local co = coroutine.create( function() tree:repeatSequence( nodes ) end)
        coroutine.resume( co )

        assert.is.equal( "suspended", coroutine.status( co ) )

        tree.sequence:revert()
      end)
    end)
  end)

  describe( "#any", function()
    context( "when a child returns true", function()
      local nodes = {
        { "fail", {{ "noop", {} }} },
        { "task", "return_true" },
        { "invert", {{ "noop", {} }} },
      }

      it( "runs all of the preceding nodes", function()
        spy.on( tree, "task" )
        spy.on( tree, "fail" )

        tree:any( nodes )
        assert.spy( tree.fail ).was.called( 1 )
        assert.spy( tree.task ).was.called( 1 )

        tree.task:revert()
        tree.fail:revert()
      end)

      it( "doesn't run any of the following nodes", function()
        spy.on( tree, "invert" )

        tree:any( nodes )
        assert.spy( tree.invert ).was.called( 0 )

        tree.invert:revert()
      end)

      it( "returns true", function()
        local result = tree:any( nodes )
        assert.is.equal( true, result )
      end)
    end)
  end)

  describe( "#succeed", function()
    it( "runs the first child", function()
      local children = {{ "task", "return_nil" }}

      stub( tree, "runNode" )

      tree:succeed( children )
      assert.stub( tree.runNode ).was.called_with( tree, children[ 1 ] )

      tree.runNode:revert()
    end)

    context( "When the child returns true", function()
      local children = {{ "task", "return_true" }}

      it( "returns true", function()
        local result = tree:succeed( children )
        assert.is.truthy( result )
      end)
    end)

    context( "When the child returns false", function()
      local children = {{ "task", "return_false" }}

      it( "returns true", function()
        local result = tree:succeed( children )
        assert.is.truthy( result )
      end)
    end)
  end)

  describe( "#fail", function()
    it( "runs the first child", function()
      local children = {{ "task", "return_false" }}

      stub( tree, "runNode" )

      tree:fail( children )
      assert.stub( tree.runNode ).was.called_with( tree, children[ 1 ] )

      tree.runNode:revert()
    end)

    context( "When the child returns true", function()
      local children = {{ "task", "return_true" }}

      it( "returns false", function()
        local result = tree:fail( children )
        assert.is.equal( false, result )
      end)
    end)

    context( "When the child returns false", function()
      local children = {{ "task", "return_false" }}

      it( "returns false", function()
        local result = tree:fail( children )
        assert.is_equal( false, result )
      end)
    end)
  end)

  describe( "#invert", function()
    it( "runs the first child", function()
      local children = {{ "fake_node", {} }}

      stub( tree, "runNode" )

      tree:invert( children )
      assert.stub( tree.runNode ).was.called_with( tree, children[ 1 ] )

      tree.runNode:revert()
    end)

    context( "When the child returns true", function()
      local children = {{ "task", "return_true" }}

      it( "returns false", function()
        local result = tree:invert( children )
        assert.is.falsy( result )
      end)
    end)

    context( "When the child returns false", function()
      local children = {{ "task", "return_false" }}

      it( "returns true", function()
        local result = tree:invert( children )
        assert.is.truthy( result )
      end)
    end)
  end)
end)
