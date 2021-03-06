-- spec script. should NOT be bundled with final game.
-- for lib/utils.lua
--
require( 'utils' )

describe( "Utils", function()
  describe( "#rgb", function()
    context( "when input is too large", function()
      local input = 0x1000000

      it( "throws an error", function()
        local expected = "colour too big for rgb() - use rgba() instead?"
        assert.has_error( function() rgb( input ) end, expected )
      end)
    end)

    context( "when value is 0", function()
      local input = 0

      it("returns a zero list", function()
        local expected = { 0, 0, 0 }
        local result = rgb( input )
        assert.are.same( expected, result )
      end)
    end)

    context( "when value is in-range", function()
      local input = 0xaabbcc

      it("returns the expected values", function()
        local expected = { 0xaa / 255.0, 0xbb / 255.0, 0xcc / 255.0 }
        local result = rgb( input )
        assert.are.same( expected, result )
      end)
    end)

    context( "for well-known colors", function()
      context( "when given red", function()
        local input = 0xff0000

        it( "returns 1,0,0", function()
          local expected = { 1.0, 0, 0 }
          local result = rgb( input )
          assert.are.same( expected, result )
        end)
      end)

      context( "when given green", function()
        local input = 0x00ff00

        it( "returns 0,1,0", function()
          local expected = { 0, 1.0, 0 }
          local result = rgb( input )
          assert.are.same( expected, result )
        end)
      end)

      context( "when given blue", function()
        local input = 0x0000ff

        it( "returns 0,1,0", function()
          local expected = { 0, 0, 1.0 }
          local result = rgb( input )
          assert.are.same( expected, result )
        end)
      end)
    end)
  end)

  describe( "#rgba", function()
    context( "when value is 0", function()
      local input = 0

      it("returns a zero list", function()
        local expected = { 0, 0, 0, 0 }
        local result = rgba( input )
        assert.are.same( expected, result )
      end)
    end)

    context( "when opacity is zero", function()
      local input = 0xaabbcc00

      it("returns the expected colours and opacity", function()
        local expected = { 0xaa / 255.0, 0xbb / 255.0, 0xcc / 255.0, 0 }
        local result = rgba( input )
        assert.are.same( expected, result )
      end)
    end)

    context( "when opacity is full", function()
      local input = 0xaabbccff

      it("returns the expected colours and opacity", function()
        local expected = { 0xaa / 255.0, 0xbb / 255.0, 0xcc / 255.0, 1.0 }
        local result = rgba( input )
        assert.are.same( expected, result )
      end)
    end)

    context( "When high bits are zero", function()
      local input = 0x00aabbcc

      it("returns the expected colours and opacity", function()
        local expected = { 0, 0xaa / 255.0, 0xbb / 255.0, 0xcc / 255.0 }
        local result = rgba( input )
        assert.are.same( expected, result )
      end)
    end)
  end)

  describe( "#deepcopy", function()
    context( "when value is nil", function()
      local input = nil
      local result = deepcopy( input )

      it("returns a nil value", function()
        local expected = nil
        assert.are.same( expected, result )
      end)
    end)

    context( "when value is a scalar string", function()
      local input = "hello world"
      local result = deepcopy( input )

      it("returns the string", function()
        local expected = "hello world"
        assert.are.same( expected, result ) -- same value
      end)
    end)

    context( "when value is a simple table", function()
      local input = { 1, 2, 3 }
      local result = deepcopy( input )

      it("returns the same values", function()
        local expected = { 1, 2, 3 }
        assert.are.same( expected, result ) -- same values
      end)

      it("returns a different table", function()
        assert.are_not_equal( input, result ) -- different memory location
      end)
    end)

    context( "when value is a complex table", function()
      local input = { a = 3, b = "something", c = { c1 = 'foo', c2 = 'bar' } }
      input[ 2 ] = 42  -- add a numeric index too
      local result = deepcopy( input )

      it("returns the same top-level values", function()
        assert.are.same( 'something', result[ 'b' ] )
        assert.are.same( 42, result[ 2 ] )
      end)

      it("returns the same nested values", function()
        local expected = { c1 = 'foo', c2 = 'bar' }
        assert.are.same( expected, result.c ) -- same values
      end)

      it("returns a different top-level table", function()
        assert.are_not_equal( input, result ) -- different memory location
      end)

      it("returns a different nested table", function()
        assert.are_not_equal( input.c, result.c ) -- different memory location
      end)
    end)

    context( "when table has a circular reference", function()
      local parent = { a = 2, b = 3 }
      local child = { c = 5, d = 7, dad = parent }
      parent.kid = child

      local expected = { a = 2, b = 3 }
      local expected_child = { c = 5, d = 7, dad = expected }
      expected.kid = expected_child

      local result = deepcopy( parent )

      it("doesn't throw an error", function()
        assert.has_no_errors( function() deepcopy( parent ) end )
      end)

      it("returns the expected values", function()
        assert.are.same( expected, result ) -- same values
      end)

      it("returns a different table", function()
        assert.are_not_equal( parent, result ) -- different memory location
      end)

      it("returns a different nested table", function()
        assert.are_not_equal( parent.kid, result.kid ) -- different memory location
      end)
    end)
  end)

  describe( "#deepmerge", function()
    context( "when overrides is nil", function()
      local overrides = nil
      local target = { a = 'foo' }
      local result = deepmerge( target, overrides )

      it("returns a different table", function()
        assert.are.not_equal( target, result ) -- different memory location
      end)

      it("returns the unmodified values", function()
        assert.are.equal( target.a, result.a )
      end)
    end)

    context( "when overrides is a non-nil scalar", function()
      local overrides = 'notatable'
      local target = { a = 'foo' }
      local result = deepmerge( target, overrides )

      it("returns a different table", function()
        assert.are.not_equal( target, result ) -- different memory location
      end)

      it("returns the unmodified values", function()
        assert.are.equal( target.a, result.a )
      end)
    end)

    context( "when overrides is an empty table", function()
      local overrides = {}
      local target = { a = 'foo' }
      local result = deepmerge( target, overrides )

      it("returns a different table", function()
        assert.are.not_equal( target, result ) -- different memory location
      end)

      it("returns the unmodified values", function()
        assert.are.equal( target.a, result.a )
      end)
    end)

    context( "when overrides is a simple table", function()
      local overrides = { b = 'bar', c = 'baz' }
      local target = { a = 'foo' }
      local result = deepmerge( target, overrides )

      it("returns a different table", function()
        assert.are.not_equal( target, result ) -- different memory location
      end)

      it("returns merged values", function()
        local expected = { a = 'foo', b = 'bar', c = 'baz' }
        assert.are.same( expected, result )
      end)
    end)

    context( "when overrides has non-conflicting children", function()
      local overrides = { b = 'bar', c = { d = 'baz' } }
      local target = { a = 'foo', c = { e = 'qux' } }
      local result = deepmerge( target, overrides )

      it("returns all merged values", function()
        local expected = { a = 'foo', b = 'bar', c = { d = 'baz', e = 'qux' } }
        assert.are.same( expected, result )
      end)
    end)

    context( "when overrides has conflicting children", function()
      local overrides = { b = 'bar', c = { d = 'baz', e = 'new' }, is_f = false }
      local target = { a = 'foo', c = { e = 'qux' }, is_f = true }
      local result = deepmerge( target, overrides )

      it("gives overrides precedence", function()
        local expected = { a = 'foo', b = 'bar', c = { d = 'baz', e = 'new' }, is_f = false }
        assert.are.same( expected, result )
      end)
    end)
  end)

  describe( "#spairs", function()
    local input = { b = 31, a = 35, d = 42 }

    context( "when sort function not given", function()
      it( "sorts by table key", function()
        local result = {}
        for key, _ in spairs( input ) do
          table.insert( result, key )
        end
        assert.is_same( { "a", "b", "d" }, result )
      end)
    end)

    context( "when sort function is provided", function()
      it( "sorts using that function", function()
        local reverse_sort_cb = function( _, a, b ) return b < a end

        local result = {}
        for key, _ in spairs( input, reverse_sort_cb ) do
          table.insert( result, key )
        end
        assert.is_same( { "d", "b", "a" }, result )
      end)
    end)
  end)

  describe( "#table_keys", function()
    context( "when input is empty", function()
      local input = {}
      local result = table_keys( input )

      it( "returns an empty list", function()
        local expected = {}
        assert.are.same( expected, result )
      end)
    end)

    context( "when input is a basic list", function()
      local input = { 'foo', 'bar', 'baz'}
      local result = table_keys( input )

      it( "returns integer keys", function()
        local expected = { 1, 2, 3 }
        assert.are.same( expected, result )
      end)
    end)
    context( "when input is a pure hash", function()
      local input = { a = 'foo', c = 'bar', b = 'baz'}
      local result = table_keys( input )

      it( "returns hash keys", function()
        local expected = { 'a', 'c', 'b' }
        assert.are.same( expected, result )
      end)
    end)
    context( "when input is a mixed list/hash", function()
      local input = { a = 'foo', d = 'bar', b = 'baz'}
      input[ 2 ] = 'qux'
      input[ 4 ] = 'quux'
      local result = table_keys( input )

      it( "returns the expected number of keys", function()
        assert.is.equal( 5, #result )
      end)

      it( "returns the expected keys", function()
        -- sort to make the comparison easier.
        table.sort( result, function( a, b ) return tostring( a ) < tostring( b ) end )
        local expected = { 2, 4, 'a', 'b', 'd' }
        assert.is_same( expected, result )
      end)
    end)
  end)

  describe( "#dig", function()
    context( "when entity is nil", function()
      local entity = nil

      it( "returns nil", function()
        local result = dig( entity, "foo", "bar", "baz" )
        assert.is_nil( result )
      end)
    end)

    context( "when entity is present", function()
      local entity = { foo = { bar = { baz = "diggy diggy hole" } } }

      context( "when the keys exist", function()
        it( "returns the expected value", function()
          local expected = "diggy diggy hole"
          local result = dig( entity, "foo", "bar", "baz" )
          assert.is_equal( expected, result )
        end)
      end)

      context( "when the last key is nil", function()
        it( "returns nil", function()
          local result = dig( entity, "foo", "bar", "nada" )
          assert.is_nil( result )
        end)

        it( "doesn't raise an error", function()
          assert.has_no_error( function() dig( entity, "foo", "bar", "nada" ) end )
        end)
      end)

      context( "when one of the parent keys is nil", function()
        it( "returns nil", function()
          local result = dig( entity, "foo", "also_nada", "nada" )
          assert.is_nil( result )
        end)

        it( "doesn't raise an error", function()
          assert.has_no_error( function() dig( entity, "foo", "also_nada", "nada" ) end )
        end)
      end)
    end)
  end)
end)
