-- spec script. should NOT be bundled with final game.
-- for lib/list.lua
--
List = require( 'list' )

describe( "List", function()
    describe( "new()", function()
        context( "when no initial values specified", function()
            local q = List:new()
            it( "sets first to 0", function()
                assert.is.equal( 0, q.first )
            end)
            it( "sets last to -1", function()
                assert.is.equal( -1, q.last )
            end)
        end)
        context( "when initial items specified", function()
            local items = { 'foo', 'bar', 3, 'qux' }
            local q = List:new( unpack( items ) )
            it( "sets first to 0", function()
                assert.is.equal( 0, q.first )
            end)
            it( "sets last to length minus 1", function()
                assert.is.equal( #items - 1, q.last )
            end)
            it( "is initialized with those items", function()
                local r1 = q[ q.first ]
                local r2 = q[ q.last ]
                assert.is.same( 'foo', r1 )
                assert.is.same( 'qux', r2 )
            end)
        end)
    end)
    describe( "push()", function()
        context( "when pushing a nil", function()
            local q = List:new( 'foo', 'bar' )
            local old_first = q.first
            local old_last = q.last
            q:push( nil )

            it( "doesn't change .first", function()
                assert.is_equal( old_first, q.first )
            end)
            it( "doesn't change .last", function()
                assert.is_equal( old_last, q.last )
            end)
        end)
        context( "when pushing an integer", function()
            local q = List:new()
            local item = 12
            q:push( item )
            it( "increments last", function()
                assert.is.equal( 0, q.last )
            end)
            it( "adds it to the end of the list", function()
                local expected = item
                local result = q[ q.last ]
                assert.is.same( expected, result )
            end)
        end)
        context( "when pushing a table", function()
            local q = List:new()
            local item = { foo = 'bar', [9] = 'ok' }
            q:push( item )
            it( "increments last", function()
                assert.is.equal( 0, q.last )
            end)
            it( "adds it to the end of the list", function()
                local expected = item
                local result = q[ q.last ]
                assert.is.same( expected, result )
            end)
        end)
    end)
    describe( "pop()", function()
        context( "when list is empty", function()
            local q = List:new( 'a' )
            q:pop() -- discard the item, empty the list
            local old_first = q.first
            local old_last = q.last

            local result = q:pop()
            it( "returns nil", function()
                assert.is_nil( result )
            end)
            it( "doesn't change .first", function()
                assert.is_equal( old_first, q.first )
            end)
            it( "doesn't change .last", function()
                assert.is_equal( old_last, q.last )
            end)
        end)
        context( "when list has multiple items", function()
            local q = List:new( 12, 'asd', 43, 7 )
            it( "pops entries correctly", function()
                q:pop()
                q:push( 'foo' )
                q:pop()
                local result = q:pop()
                local expected = 43
                assert.is.same( expected, result )
            end)
            it( "updates .first", function()
                assert.is_equal( 0, q.first )
            end)
            it( "updates .last", function()
                assert.is_equal( 1, q.last )
            end)
        end)
    end)
    describe( "shift()", function()
        context( "when list is empty", function()
            local q = List:new( 'asd' )
            q:pop() -- discard item to get empty list
            local old_first = q.first
            local old_last = q.last
            local result = q:shift()
            it( "returns nil", function()
                assert.is_nil( result )
            end)
            it( "doesn't change .first", function()
                assert.is_equal( old_first, q.first )
            end)
            it( "doesn't change .last", function()
                assert.is_equal( old_last, q.last )
            end)
        end)
        context( "when list has multiple items", function()
            local q = List:new( 12, 'asd', 43, 7 )
            local old_first = q.first
            local old_last = q.last
            local result = q:shift()
            it( "returns the first value", function()
                local expected = 12
                assert.is.same( expected, result )
            end)
            it( "updates .first", function()
                assert.is_equal( old_first + 1, q.first )
            end)
            it( "doesn't change .last", function()
                assert.is_equal( old_last, q.last )
            end)
        end)
    end)
    describe( "unshift()", function()
        context( "when list is empty", function()
            local q = List:new()
            q:unshift( 'asd' )
            it( "places the item at the start of the list", function()
                local expected = 'asd'
                local result = q[ q.first ]
                assert.is.same( expected, result )
            end)
        end)
        context( "when list has items", function()
            local q = List:new( 12, 'foo' )
            q:unshift( 'asd' )
            it( "places the item at the start of the list", function()
                local expected = 'asd'
                local result = q[ q.first ]
                assert.is.same( expected, result )
            end)
            it( "doesn't change last", function()
                local expected = 'foo'
                local result = q[ q.last ]
                assert.is.same( expected, result )
            end)
        end)
    end)
    describe( "length()", function()
        context( "when list is empty", function()
            local q = List:new()
            local result = q:length()
            it( "returns 0", function()
                assert.is.equal( 0, result )
            end)
        end)
        context( "when list is short", function()
            local q = List:new( 'foo', 'bar', 'baz' )
            local result = q:length()
            it( "counts a short list correctly", function()
                assert.is.same( 3, result )
            end)
        end)
        context( "when list has been modified", function()
            local q = List:new()
            for i = 1, 20 do
                q:push( 'foo' )
            end
            for i = 1,3 do
                q:shift()
                q:pop()
            end
            q:push( 'bar' )
            local result = q:length()
            it( "returns the expected length", function()
                local expected = 15
                assert.is.same( expected, result )
            end)
        end)
    end)
    describe( "isEmpty()", function()
        context( "when list is empty", function()
            local q = List:new()
            local result = q:isEmpty()
            it( "returns true", function()
                assert.is_true( result )
            end)
        end)
        context( "when list is non-empty", function()
            local q = List:new( 4, 2, 7 )
            local result = q:isEmpty()
            it( "returns false", function()
                assert.is_false( result )
            end)
        end)
        context( "when list has been emptied", function()
            local q = List:new()
            q:push( 'foo' )
            q:push( 'bar' )
            q:pop()
            q:pop()
            local result = q:isEmpty()
            it( "returns true", function()
                assert.is_true( result )
            end)
        end)
    end)
    describe( "get(n)", function()
        context( "when list is empty", function()
            local q = List:new()
            local result = q:get()
            it( "returns nil", function()
                assert.is_nil( result )
            end)
        end)
        context( "when list is not empty", function()
            local q = List:new( 'foo', 'bar', 'baz' )
            local zeroth = q:get( 0 )
            local first  = q:get( 1 )
            local middle = q:get( 2 )
            local last   = q:get( 3 )
            local result = q:get( 4 )
            it( "returns nil for too-low index", function()
                assert.is_nil( zeroth )
            end)
            it( "returns nil for too-high index", function()
                assert.is_nil( result )
            end)
            it( "gets the first item", function()
                assert.is_equal( 'foo', first )
            end)
            it( "gets a middle item", function()
                assert.is_equal( 'bar', middle )
            end)
            it( "gets the last item", function()
                assert.is_equal( 'baz', last )
            end)
        end)
    end)
end)
