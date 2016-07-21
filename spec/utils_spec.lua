-- spec script. should NOT be bundled with final game.
-- for lib/utils.lua
--
require( 'utils' )

describe( "Utility library", function()
    describe( "rgb colour shortcut", function()
        it( "errors on too large of input", function()
            local input = 0x1000000
            assert.has_error( function() rgb( input ) end, "colour too big for rgb() - use rgba() instead?")
        end)

        it("should output a valid list for a 0 value", function()
            local input = 0
            local r, g, b = rgb( input )
            local expected = { 0, 0, 0 }
            assert.are.same( expected, { r, g, b } )
        end)

        it("should output a valid list for an arbitrary value", function()
            local input = 0xaabbcc
            local r, g, b = rgb( input )
            local expected = { 0xaa, 0xbb, 0xcc }
            assert.are.same( expected, { r, g, b } )
        end)
    end)

    describe( "rgba colour shortcut", function()
        it("should output a valid list for a 0 value", function()
            local input = 0
            local r, g, b, a = rgba( input )
            local expected = { 0, 0, 0, 0 }
            assert.are.same( expected, { r, g, b, a } )
        end)

        it("should output a valid list for a value with full opacity", function()
            local input = 0xaabbccff
            local r, g, b, a = rgba( input )
            local expected = { 0xaa, 0xbb, 0xcc, 0xff }
            assert.are.same( expected, { r, g, b, a } )
        end)
        it("should output a valid list for items with no red", function()
            local input = 0x00aabbcc
            local r, g, b, a = rgba( input )
            local expected = { 0x00, 0xaa, 0xbb, 0xcc }
            assert.are.same( expected, { r, g, b, a } )
        end)
    end)

    describe( "should have deepcopy function", function()
        it("should copy a nil value", function()
            local input = nil
            local result = deepcopy( input )
            local expected = nil
            assert.are.same( expected, result )
        end)
        it("should copy a scalar string value", function()
            local input = "hello world"
            local result = deepcopy( input )
            local expected = "hello world"
            assert.are.same( expected, result ) -- same value
        end)
        it("should copy a simple table", function()
            local input = { 1, 2, 3 }
            local result = deepcopy( input )
            local expected = { 1, 2, 3 }
            assert.are.same( expected, result ) -- same value
            assert.are_not.equal( input, result ) -- different memory location
        end)
    end)

    describe( "has a deepmerge function for table merges", function()
        it("returns original target if not merging a table", function()
            local input = 'notatable'
            local target = { a = 'foo' }
            local result = deepmerge( target, input )
            local expected = { a = 'foo' }
            assert.are.same( expected, result )
        end)
        it("returns merged target with single-level merged values", function()
            local input = { b = 'bar', c = 'baz' }
            local target = { a = 'foo' }
            local result = deepmerge( target, input )
            local expected = { a = 'foo', b = 'bar', c = 'baz' }
            assert.are.same( expected, result )
        end)
        it("returns merged target with multiple-level merged values", function()
            local input = { b = 'bar', c = { d = 'baz' } }
            local target = { a = 'foo', c = { e = 'qux' } }
            local result = deepmerge( target, input )
            local expected = { a = 'foo', b = 'bar', c = { d = 'baz', e = 'qux' } }
            assert.are.same( expected, result )
        end)
        it("returns merged target with multiple-level overridden values", function()
            local input = { b = 'bar', c = { d = 'baz', e = 'new' } }
            local target = { a = 'foo', c = { e = 'qux' } }
            local result = deepmerge( target, input )
            local expected = { a = 'foo', b = 'bar', c = { d = 'baz', e = 'new' } }
            assert.are.same( expected, result )
        end)
    end)
end)
