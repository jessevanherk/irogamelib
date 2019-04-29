-- spec script. should NOT be bundled with final game.
-- for lib/list.lua
--
require( "spec.spec_helper" )

List = require( 'list' )

describe( "List", function()
  describe( "#new", function()
    context( "when no initial values specified", function()
      it( "sets first to 0", function()
        local q = List:new()
        assert.is.equal( 0, q.first )
      end)

      it( "sets last to -1", function()
        local q = List:new()
        assert.is.equal( -1, q.last )
      end)
    end)

    context( "when initial items specified", function()
      local items = { 'foo', 'bar', 3, 'qux' }

      it( "sets first to 0", function()
        local q = List:new( unpack( items ) )
        assert.is.equal( 0, q.first )
      end)

      it( "sets last to length minus 1", function()
        local q = List:new( unpack( items ) )
        assert.is.equal( #items - 1, q.last )
      end)

      it( "is initialized with those items", function()
        local q = List:new( unpack( items ) )
        local r1 = q[ q.first ]
        local r2 = q[ q.last ]
        assert.is.same( 'foo', r1 )
        assert.is.same( 'qux', r2 )
      end)
    end)
  end)

  describe( "#push", function()
    context( "when pushing a nil", function()
      local q = List:new( 'foo', 'bar' )
      local old_first = q.first
      local old_last = q.last

      it( "doesn't change .first", function()
        q:push( nil )
        assert.is_equal( old_first, q.first )
      end)

      it( "doesn't change .last", function()
        q:push( nil )
        assert.is_equal( old_last, q.last )
      end)
    end)

    context( "when pushing an integer", function()
      local q = List:new()
      local item = 12

      it( "increments last", function()
        q:push( item )
        assert.is.equal( 0, q.last )
      end)

      it( "adds it to the end of the list", function()
        local expected = item
        q:push( item )
        local result = q[ q.last ]
        assert.is.same( expected, result )
      end)
    end)

    context( "when pushing a table", function()
      local q = List:new()
      local item = { foo = 'bar', [9] = 'ok' }

      it( "increments last", function()
        q:push( item )
        assert.is.equal( 0, q.last )
      end)

      it( "adds it to the end of the list", function()
        local expected = item
        q:push( item )
        local result = q[ q.last ]
        assert.is.same( expected, result )
      end)
    end)
  end)

  describe( "#pop", function()
    context( "when list is empty", function()
      local q = List:new()
      local old_first = q.first
      local old_last = q.last

      it( "returns nil", function()
        local result = q:pop()
        assert.is_nil( result )
      end)

      it( "doesn't change .first", function()
        q:pop()
        assert.is_equal( old_first, q.first )
      end)

      it( "doesn't change .last", function()
        q:pop()
        assert.is_equal( old_last, q.last )
      end)
    end)

    context( "when list has multiple items", function()
      it( "pops entries correctly", function()
        local q = List:new( 12, 'asd', 43 )
        local expected = 43
        local result = q:pop()
        assert.is.same( expected, result )
      end)

      it( "updates .first", function()
        local q = List:new( 12, 'asd', 43 )
        q:pop()
        assert.is_equal( 0, q.first )
      end)

      it( "updates .last", function()
        local q = List:new( 12, 'asd', 43 )
        q:pop()
        assert.is_equal( 1, q.last )
      end)
    end)
  end)

  describe( "#shift", function()
    context( "when list is empty", function()
      local q = List:new()
      local old_first = q.first
      local old_last = q.last

      it( "returns nil", function()
        local result = q:shift()
        assert.is_nil( result )
      end)

      it( "doesn't change .first", function()
        q:shift()
        assert.is_equal( old_first, q.first )
      end)

      it( "doesn't change .last", function()
        q:shift()
        assert.is_equal( old_last, q.last )
      end)
    end)

    context( "when list has multiple items", function()
      it( "returns the first value", function()
        local q = List:new( 12, 'asd', 43, 7 )
        local expected = 12
        local result = q:shift()
        assert.is.same( expected, result )
      end)

      it( "updates .first", function()
        local q = List:new( 12, 'asd', 43, 7 )
        local old_first = q.first

        q:shift()
        assert.is_equal( old_first + 1, q.first )
      end)

      it( "doesn't change .last", function()
        local q = List:new( 12, 'asd', 43, 7 )
        local old_last = q.last

        q:shift()
        assert.is_equal( old_last, q.last )
      end)
    end)
  end)

  describe( "#unshift", function()
    context( "when list is empty", function()
      local q = List:new()

      it( "places the item at the start of the list", function()
        local expected = 'asd'
        q:unshift( 'asd' )
        local result = q[ q.first ]
        assert.is.same( expected, result )
      end)
    end)

    context( "when list has items", function()
      local q = List:new( 12, 'foo' )

      it( "places the item at the start of the list", function()
        local expected = 'asd'
        q:unshift( 'asd' )
        local result = q[ q.first ]
        assert.is.same( expected, result )
      end)

      it( "doesn't change last", function()
        local expected = 'foo'
        q:unshift( 'asd' )
        local result = q[ q.last ]
        assert.is.same( expected, result )
      end)
    end)
  end)

  describe( "#length", function()
    context( "when list is empty", function()
      local q = List:new()

      it( "returns 0", function()
        local result = q:length()
        assert.is.equal( 0, result )
      end)
    end)

    context( "when list is short", function()
      local q = List:new( 'foo', 'bar', 'baz' )

      it( "counts a short list correctly", function()
        local result = q:length()
        assert.is.same( 3, result )
      end)
    end)

    context( "when list has been modified", function()
      local q = List:new()
      for _ = 1, 20 do
        q:push( 'foo' )
      end
      for _ = 1, 3 do
        q:shift()
        q:pop()
      end
      q:push( 'bar' )

      it( "returns the expected length", function()
        local expected = 15
        local result = q:length()
        assert.is.same( expected, result )
      end)
    end)
  end)

  describe( "#isEmpty", function()
    context( "when list is empty", function()
      local q = List:new()

      it( "returns true", function()
        local result = q:isEmpty()
        assert.is_true( result )
      end)
    end)

    context( "when list is non-empty", function()
      local q = List:new( 4, 2, 7 )

      it( "returns false", function()
        local result = q:isEmpty()
        assert.is_false( result )
      end)
    end)

    context( "when list has been emptied", function()
      local q = List:new()
      q:push( 'foo' )
      q:push( 'bar' )
      q:pop()
      q:pop()

      it( "returns true", function()
        local result = q:isEmpty()
        assert.is_true( result )
      end)
    end)
  end)

  describe( "#get", function()
    context( "when list is empty", function()
      local q = List:new()

      it( "returns nil", function()
        local result = q:get()
        assert.is_nil( result )
      end)
    end)

    context( "when list is not empty", function()
      local q = List:new( 'foo', 'bar', 'baz' )

      context( "when index is 0", function()
        local index = 0

        it( "returns nil", function()
          assert.is_nil( q:get( index ) )
        end)
      end)

      context( "when index is beyond the end of the list", function()
        local index = 200

        it( "returns nil", function()
          assert.is_nil( q:get( index ) )
        end)
      end)

      context( "when index is within the list", function()
        local index = 2

        it( "returns the value from that list position", function()
          local expected = "bar"
          assert.is_equal( expected, q:get( index ) )
        end)
      end)
    end)
  end)

  describe( "#entries", function()
    context( "when list is empty", function()
      local q = List:new()

      it( "returns an empty array", function()
        assert.are_same( {}, q:entries() )
      end)
    end)

    context( "when list has content", function()
      context( "when list hasn't been modified", function()
        local q = List:new( "foo", "bar", "baz" )

        it( "returns an empty array", function()
          assert.are_same( { "foo", "bar", "baz" }, q:entries() )
        end)
      end)

      context( "when list has been modified", function()
        local q = List:new( "foo", "bar", "baz" )

        it( "still returns the full list", function()
          q:shift()
          q:push( "qux" )
          assert.are_same( { "bar", "baz", "qux" }, q:entries() )
        end)
      end)
    end)
  end)
end)
