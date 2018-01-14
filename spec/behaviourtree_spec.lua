-- spec script. should NOT be bundled with final game.
--
BehaviourTree = require( "behaviourtree" )

describe( "BehaviourTree", function()
  local test_tasks = {
    return_nil   = function() return nil end,
    return_true  = function() return true end,
    return_false = function() return false end,
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
  end)

  describe( "runNode()", function()
    context( "when node is valid", function()
      it( "does not throw an error", function()
      end)
    end)

    context( "when node is nil", function()
      it( "throws an error", function()
        local expected = "node must be a table"
        assert.has_error( function() tree:runNode( nil ) end, expected )
      end)
    end)

    context( "when node is not a table", function()
      it( "throws an error", function()
        local expected = "node must be a table"
        assert.has_error( function() tree:runNode( "not_a_table" ) end, expected )
      end)
    end)

    context( "when passed multiple nodes", function()
      it( "throws an error", function()
        local expected = "invalid node format - must be {string, argument}"
        assert.has_error( function() tree:runNode( { { "node1" }, { "node2" } } ) end, expected )
      end)
    end)
  end)

  describe( "task()", function()
  end)

  describe( "sequence()", function()
  end)

  describe( "repeatSequence()", function()
  end)

  describe( "any()", function()
  end)

  describe( "succeed()", function()
    local child = { "task", "return_nil" }

    it( "runs the child", function()
      stub( tree, "runNode" )

      tree:succeed( child )
      assert.stub( tree.runNode ).was.called_with( tree, child )

      tree.runNode:revert()  -- revert the stub!
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

      tree.runNode:revert()  -- revert the stub!
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

      tree.runNode:revert()  -- revert the stub!
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
