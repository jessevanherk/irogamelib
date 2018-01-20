-- spec script. should NOT be bundled with final game.
-- for lib/priorityqueue.lua
--
PriorityQueue = require( 'priorityqueue' )

describe( "PriorityQueue", function()
  describe( "#new", function()
    context( "when no arguments provided", function()
      local q = PriorityQueue:new()

      it( "has no values", function()
        assert.is.same( {}, q.values )
      end)

      it( "has no priorities", function()
        assert.is.same( {}, q.priorities )
      end)

      it( "uses default comparator", function()
        assert.is.same( q.defaultCompare, q.compare )
      end)
    end)

    context( "when valid comparator provided", function()
      local comparator = function( a, b ) end
      local q = PriorityQueue:new( comparator )

      it( "has no values", function()
        assert.is.same( {}, q.values )
      end)

      it( "has no priorities", function()
        assert.is.same( {}, q.priorities )
      end)

      it( "uses the specified comparator", function()
        assert.is.same( comparator, q.compare )
      end)
    end)

    context( "when invalid comparator provided", function()
      it( "throws an error", function()
        local expected = "comparator must be a function"
        local comparator = "notafunction"
        assert.has_error( function() PriorityQueue:new( comparator ) end, expected )
      end)
    end)

    context( "when values and priorities are provided", function()
      local values = { 'mouse', 'cat', 'elephant', 'dog' }
      local priorities = { 3, 5, 1, 10 }
      local q = PriorityQueue:new( nil, values, priorities )
      local result = q:popAll()

      it( "uses the default comparator", function()
        assert.is.same( q.defaultCompare, q.compare )
      end)

      it( "sorted values correctly", function()
        assert.is.same( { 'dog', 'cat', 'mouse', 'elephant' }, result )
      end)
    end)
  end)

  describe( "#push", function()
    context( "when queue is empty", function()
      local q = PriorityQueue:new()
      q:push( 'foof', 4 )
      local result = q:popAll()

      it( "has the value", function()
        local expected = { 'foof' }
        assert.is.same( expected, result )
      end)
    end)

    context( "when inserting a nil", function()
      local q = PriorityQueue:new( nil, { 'bar', 'foo' }, { 2, 10 } )
      local old_size = q:size()
      q:push( nil, 10 )

      it( "doesn't change size", function()
        assert.is_equal( old_size, q:size() )
      end)

      it( "pops the previous best", function()
        local result = q:pop()
        assert.is_equal( 'foo', result )
      end)
    end)

    context( "when inserting into the middle", function()
      local q = PriorityQueue:new( nil, { 'bar', 'foo' }, { 2, 12 } )
      q:push( 'baz', 5 ) -- try getting it in the middle
      local results = q:popAll()

      it( "has the items in the right order", function()
        local expected = { 'foo', 'baz', 'bar' }
        assert.is.same( expected, results )
      end)
    end)

    context( "when there is a tie", function()
      local q = PriorityQueue:new( nil, { 'bar', 'foo' }, { 2, 12 } )
      q:push( 'baz', 12 ) -- try getting it in the middle
      local results = q:popAll()

      it( "gives the original item higher priority", function()
        local expected = { 'foo', 'baz', 'bar' }
        assert.is.same( expected, results )
      end)
    end)

    context( "when min comparator is specified", function()
      -- lower numbers get higher priority
      local comparator = function( a, b ) return a > b end
      local q = PriorityQueue:new( comparator, { 'bar', 'foo' }, { 2, 12 } )
      q:push( 'baz', 22 )
      local results = q:popAll()

      it( "sorts lower numbers first", function()
        local expected = { 'bar', 'foo', 'baz' }
        assert.is.same( expected, results )
      end)
    end)
  end)

  describe( "#pop", function()
    context( "when queue is empty", function()
      local q = PriorityQueue:new()

      it( "returns nil", function()
        local result = q:pop()
        assert.is_nil( result )
      end)
    end)

    context( "when queue has one item", function()
      local q = PriorityQueue:new( nil, { 'foof' }, { 4 })
      local result = q:pop()

      it( "returns that item", function()
        local expected = 'foof'
        assert.is.same( expected, result )
      end)
    end)

    context( "when queue has multiple items", function()
      local values = { 'foo', 'bar', 'baz', 'qux', 'quz' }
      local priorities = { 3, 6, 4, 9, 2 }
      local q = PriorityQueue:new( nil, values, priorities )
      local result = q:pop()
      local result2 = q:pop()

      it( "returns first item", function()
        local expected = 'qux'
        assert.is.same( expected, result )
      end)

      it( "returns second item", function()
        expected = 'bar'
        assert.is.same( expected, result2 )
      end)
    end)
  end)

  describe( "#clone", function()
    context( "when queue is empty", function()
      local q = PriorityQueue:new()
      local c = q:clone()

      it( "returns an empty queue", function()
        assert.is.same( {}, c.values )
        assert.is.same( {}, c.priorities )
      end)

      it( "uses the default compare", function()
        assert.is.same( c.defaultCompare, c.compare )
      end)

      it( "is a different table", function()
        assert.is_not_equal( c, q )
        assert.is_not_equal( c.values, q.values )
        assert.is_not_equal( c.priorities, q.priorities )
      end)
    end)

    context( "when original has custom comparator", function()
      local comparator = function( a, b ) end
      local q = PriorityQueue:new( comparator )
      local c = q:clone()

      it( "returns an empty queue", function()
        assert.is.same( {}, c.values )
        assert.is.same( {}, c.priorities )
      end)

      it( "uses the custom compare", function()
        -- expect the function addresses to be the same, not a copy
        assert.is.equal( q.compare, c.compare )
      end)

      it( "is a different table", function()
        assert.is_not_equal( c, q )
        assert.is_not_equal( c.values, q.values )
        assert.is_not_equal( c.priorities, q.priorities )
      end)
    end)
  end)

  describe( "#size", function()
    context( "when queue is empty", function()
      local q = PriorityQueue:new()
      local result = q:size()

      it( "returns zero", function()
        assert.is.same( 0, result )
      end)
    end)

    context( "when queue is not empty", function()
      local q = PriorityQueue:new( nil, { 'foo', 'bar', 'baz' }, { 1, 3, 2 } )
      local result = q:size()

      it( "returns the correct size", function()
        local expected = 3
        assert.is.same( expected, result )
      end)
    end)

    context( "when items have been added and removed", function()
      local q = PriorityQueue:new()
      q:push( 'foo', 2 )
      q:push( 'bar', 3 )
      q:push( 'baz', 9 )
      q:pop()
      q:push( 'qux', 1 )
      q:pop()
      local result = q:size()

      it( "returns the correct size", function()
        local expected = 2
        assert.is.same( expected, result )
      end)
    end)
  end)

  describe( "#isEmpty", function()
    context( "when queue is empty", function()
      local q = PriorityQueue:new()
      local result = q:isEmpty()

      it( "returns true", function()
        local expected = true
        assert.is.same( expected, result )
      end)
    end)

    context( "when queue is not empty", function()
      local q = PriorityQueue:new( nil, { 'foo', 'bar' }, { 1, 2 } )

      it( "returns false", function()
        local result = q:isEmpty()
        local expected = false
        assert.is.same( expected, result )
      end)
    end)

    context( "when queue has been emptied", function()
      local q = PriorityQueue:new( nil, { 'foo' }, { 4 } )
      q:pop()
      local result = q:isEmpty()

      it( "returns true", function()
        local expected = true
        assert.is.same( expected, result )
      end)
    end)
  end)

  describe( "#peek", function()
    context( "when queue is empty", function()
      local q = PriorityQueue:new()
      local result = q:peek()

      it( "returns nil", function()
        local expected = nil
        assert.is.same( expected, result )
      end)

      it( "doesn't change queue size", function()
        assert.is.same( 0, q:size() )
      end)
    end)

    context( "when queue is not empty", function()
      local q = PriorityQueue:new()
      q:push( 'foof', 4 )
      local result = q:peek()

      it( "returns the next item", function()
        local expected = 'foof'
        assert.is.same( expected, result )
      end)

      it( "doesn't change queue size", function()
        assert.is.same( q:size(), 1 )
      end)
    end)
  end)

  describe( "#clear", function()
    context( "when queue is empty", function()
      local q = PriorityQueue:new()
      local orig_size = q:size()
      q:clear()
      local result = q:size()

      it( "doesn't change the queue size", function()
        assert.is.same( orig_size, result )
      end)
    end)

    context( "when queue is not empty", function()
      local q = PriorityQueue:new()
      q:push( 'foo', 3 )
      q:push( 'bar', 6 )
      q:push( 'baz', 4 )
      q:clear()
      local result = q:size()

      it( "sets the size to 0", function()
        local expected = 0
        assert.is.same( expected, result )
      end)

      it( "clears the values", function()
        assert.is_same( {}, q.values )
      end)

      it( "clears the priorities", function()
        assert.is_same( {}, q.priorities )
      end)
    end)
  end)
end)
