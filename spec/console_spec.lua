local Console = require( 'console' )

describe( "console", function()
  console = Console:new()

  describe( "#wrap", function()
    context( "when given a nil", function()
      local input = nil
      local result = console:wrap( input )

      it( "returns nil", function()
        local expected = "return nil"
        assert.is.same( expected, result )
      end)
    end)

    context( "when given an assignment", function()
      local input = "foo = 999"
      local result = console:wrap( input )

      it( "adds a return statement at the end", function()
        local expected = "foo = 999;return foo"
        assert.is.same( expected, result )
      end)
    end)

    context( "when given a bare equality check", function()
      local input = "foo == 999"
      local result = console:wrap( input )

      it( "returns it directly", function()
        local expected = "return foo == 999"
        assert.is.same( expected, result )
      end)
    end)

    context( "when given a statement", function()
      local input = "doStuff( 'with', 'data' )"
      local result = console:wrap( input )

      it( "adds a return for the whole line", function()
        local expected = "return doStuff( 'with', 'data' )"
        assert.is.same( expected, result )
      end)
    end)

    context( "when given multiple expressions", function()
      local input = "1, 2, 3"
      local result = console:wrap( input )

      it( "adds a return for the whole line", function()
        local expected = "return 1, 2, 3"
        assert.is.same( expected, result )
      end)
    end)
  end)

  describe( "prettify", function()
    context( "when given nil", function()
      local input = nil
      local result = console:prettify( input )

      it( "returns 'nil'", function()
        local expected = { "nil" }
        assert.is.same( expected, result )
      end)
    end)

    context( "when given a table", function()
      local input = { first = { inner = { 3, 1, 4 } }, second = 42 }
      local result = console:prettify( input )

      it( "only includes the top level keys", function()
        local found_keys = {}
        for i, line in ipairs( result ) do
          -- check lines for keys, ignoring the first/overall assignment
          if i ~= 1 and line:find( "=" ) then
            local key_name = line:match( "(%w*) =" )
            table.insert( found_keys, key_name )
          end
        end

        local expected = { "second", "first" }
        assert.is.same( expected, found_keys )
      end)
    end)

    context( "when given a string", function()
      local input = "hello world"
      local result = console:prettify( input )

      it( "returns the string as-is", function()
        local expected = { "hello world" }
        assert.is.same( expected, result )
      end)
    end)

    context( "when given a number", function()
      local input = 412.3
      local result = console:prettify( input )

      it( "returns the number as a string", function()
        local expected = { "412.3" }
        assert.is.same( expected, result )
      end)
    end)
  end)

  describe "#eval" do
    context( "when input can't be compiled", function()
      local input = "("
      local result = console:eval( input )

      it( "returns a compilation error", function()
        local expected = {
          "! Compilation error: [string \"return (\"]:1: unexpected symbol near '<eof>'",
        }
        assert.is.same( expected, result )
      end)
    end)

    context( "when input can be compiled but not evaluated", function()
      local input = "doStuff()"
      local result = console:eval( input )

      it( "returns an evaluation error", function()
        local expected = {
          '! Evaluation error: [string "return doStuff()"]:1: attempt to call global \'doStuff\' (a nil value)',
        }
        assert.is.same( expected, result )
      end)
    end)
  end
end)
