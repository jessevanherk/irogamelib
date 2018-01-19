-- spec script. should NOT be bundled with final game.
--
BehaviourTree = require( "behaviourtree" )

describe( "BehaviourTree", function()
  local test_tasks = {
    return_nil    = function() return nil end,
    return_true   = function() return true end,
    return_false  = function() return false end,
    return_string = function() return "something" end,
    return_zero   = function() return 0 end,
  }
  local tree = BehaviourTree:new( {}, test_tasks, {}, {} )

  describe( "new()", function()
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
        assert.is.equal( new_tree.tasks, available_tasks )
      end)

      it( "has a context", function()
        assert.is.equal( new_tree.context, context )
      end)

      it( "has a blackboard", function()
        assert.are.equal( new_tree.blackboard, blackboard )
      end)

      it( "has a valid coroutine", function()
        assert.is.truthy( new_tree.co ~= nil )
        assert.is.equal( coroutine.status( new_tree.co ), "suspended" )
      end)
    end)
  end)

  describe( "tick()", function()
    context( "FIXME", function()
      it( "FIXME", function()
        assert.is.equal( false, true )
      end)
    end)
  end)

  describe( "runNode()", function()
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
      local nodes = { { "node1" }, { "node2" } }
      it( "throws an error", function()
        local expected = "invalid node format - must be {string, argument}"
        assert.has_error( function() tree:runNode( nodes ) end, expected )
      end)
    end)
  end)

  describe( "task()", function()
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
            assert.is.equal( result, true )
          end)
        end)

        context( "when the task returns false", function()
          local task_name = "return_false"

          it( "returns false", function()
            local result = tree:task( task_name )
            assert.is.equal( result, false )
          end)
        end)

        context( "when the task returns nil", function()
          local task_name = "return_nil"

          it( "returns true", function()
            local result = tree:task( task_name )
            assert.is.equal( result, true )
          end)
        end)

        context( "when the task returns zero", function()
          local task_name = "return_zero"

          -- in lua, all values other than nil and false are truthy.
          it( "returns true", function()
            local result = tree:task( task_name )
            assert.is.equal( result, true )
          end)
        end)

        context( "when the task returns a misc truthy value", function()
          local task_name = "return_string"

          it( "returns true", function()
            local result = tree:task( task_name )
            assert.is.equal( result, true )
          end)
        end)
      end)
    end)
  end)

  describe( "sequence()", function()
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
        assert.is.equal( result, true )
      end)
    end)

    context( "when a node fails", function()
      it( "runs all of the preceding nodes", function()
        assert.is.equal( false, true )
      end)

      it( "doesn't run any of the following nodes", function()
        assert.is.equal( false, true )
      end)

      it( "returns false", function()
        assert.is.equal( false, true )
      end)
    end)

    context( "when all nodes fail", function()
      it( "runs all of the nodes", function()
        assert.is.equal( false, true )
      end)

      it( "returns false", function()
        assert.is.equal( false, true )
      end)
    end)
  end)

  describe( "repeatSequence()", function()
    context( "FIXME", function()
      it( "FIXME", function()
        assert.is.equal( false, true )
      end)
    end)
  end)

  describe( "any()", function()
    context( "FIXME", function()
      it( "FIXME", function()
        assert.is.equal( false, true )
      end)
    end)
  end)

  describe( "succeed()", function()
    local child = { "task", "return_nil" }

    it( "runs the child", function()
      stub( tree, "runNode" )

      tree:succeed( child )
      assert.stub( tree.runNode ).was.called_with( tree, child )

      tree.runNode:revert()
    end)

    context( "When the child returns true", function()
      local child = { "task", "return_true" }

      it( "returns true", function()
        local result = tree:succeed( child )
        assert.is.truthy( result )
      end)
    end)

    context( "When the child returns false", function()
      local child = { "task", "return_false" }

      it( "returns true", function()
        local result = tree:succeed( child )
        assert.is.truthy( result )
      end)
    end)
  end)

  describe( "fail()", function()
    local child = { "task", "return_false" }

    it( "runs the child", function()
      stub( tree, "runNode" )

      tree:succeed( child )
      assert.stub( tree.runNode ).was.called_with( tree, child )

      tree.runNode:revert()
    end)

    context( "When the child returns true", function()
      it( "returns false", function()
        local result = tree:succeed( child )
      end)
    end)

    context( "When the child returns false", function()
      it( "returns false", function()
      end)
    end)
  end)

  describe( "invert()", function()
    local child = { "fake_node", {} }

    it( "runs the child", function()
      stub( tree, "runNode" )

      tree:succeed( child )
      assert.stub( tree.runNode ).was.called_with( tree, child )

      tree.runNode:revert()
    end)

    context( "When the child returns true", function()
      local child = { "task", "return_true" }

      it( "returns false", function()
        local result = tree:invert( child )
        assert.is.falsy( result )
      end)
    end)

    context( "When the child returns false", function()
      local child = { "task", "return_false" }

      it( "returns true", function()
        local result = tree:invert( child )
        assert.is.truthy( result )
      end)
    end)
  end)
end)
