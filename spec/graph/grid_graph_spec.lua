local GridGraph = require( "graphs/gridgraph" )

describe( "GridGraph", function()
  local width = 2
  local height = 3
  local values = { { 'a', '%' }, { 0, 4 }, { 'b', '~' } }
  local cost_cb = function( a, b )
                    if b == '~' then
                      return 20
                    else
                      return 1
                    end
                  end

  describe( "#new", function()
    context( "when given all params", function()
      it( "sets the width and height", function()
        local graph = GridGraph:new( width, height, values, cost_cb )
        assert.is.same( 2, graph.width )
        assert.is.same( 3, graph.height )
      end)

      it( "sets the values", function()
        local graph = GridGraph:new( width, height, values, cost_cb )
        local expected = { { 'a', '%' }, { 0, 4 }, { 'b', '~' } }
        assert.is.same( expected, graph.values )
      end)

      it( "sets the cost callback", function()
        local graph = GridGraph:new( width, height, values, cost_cb )
        assert.is.same( cost_cb, graph.cost_cb )
      end)
    end)

    context( "when cost function is not given", function()
      it( "uses the default cost callback", function()
        local graph = GridGraph:new( width, height, values )
        local expected = graph.default_cost_cb
        assert.is.same( expected, graph.cost_cb )
      end)
    end)
  end)

  describe( "#getCost", function()
    context( "with the default cost function", function()
      local graph = GridGraph:new( width, height, values )

      context( "when the move is within the grid", function()
        it( "returns the expected value", function()
          local expected = 1
          assert.is.same( expected, graph:getCost( { 1, 1 }, { 2, 2 } ) )
        end)
      end)

      context( "when the start position is invalid", function()
        it( "throws an error", function()
          assert.has_error( function() graph:getCost( nil, { 2, 2 } ) end )
        end)
      end)

      context( "when the end position is invalid", function()
        it( "throws an error", function()
          assert.has_error( function() graph:getCost( { 2, 2 }, nil ) end )
        end)
      end)
    end)

    context( "with a custom cost function", function()
      local graph = GridGraph:new( width, height, values, cost_cb )

      context( "when the move is within the grid", function()
        it( "returns the expected value", function()
          local expected = 20
          assert.is.same( expected, graph:getCost( { 1, 1 }, { 2, 3 } ) )
        end)
      end)

      context( "when the start position is invalid", function()
        it( "throws an error", function()
          assert.has_error( function() graph:getCost( nil, { 2, 2 } ) end )
        end)
      end)

      context( "when the end position is invalid", function()
        it( "throws an error", function()
          assert.has_error( function() graph:getCost( { 2, 2 }, nil ) end )
        end)
      end)
    end)
  end)
end)
