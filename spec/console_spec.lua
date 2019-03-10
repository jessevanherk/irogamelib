local Console = require( 'console' )

describe( "console", function()
  console = Console:new()

  describe( "#wrap", function()
    context( "when given a nil", function()
      local input = nil

      it( "returns nil", function()
        local expected = "return nil"

        local result = console:wrap( input )
        assert.is.same( expected, result )
      end)
    end)

    context( "when given an assignment", function()
      local input = "foo = 999"

      it( "adds a return statement at the end", function()
        local expected = "foo = 999;return foo"

        local result = console:wrap( input )
        assert.is.same( expected, result )
      end)
    end)

    context( "when given a bare equality check", function()
      local input = "foo == 999"

      it( "returns it directly", function()
        local expected = "return foo == 999"

        local result = console:wrap( input )
        assert.is.same( expected, result )
      end)
    end)

    context( "when given a statement", function()
      local input = "doStuff( 'with', 'data' )"

      it( "adds a return for the whole line", function()
        local expected = "return doStuff( 'with', 'data' )"

        local result = console:wrap( input )
        assert.is.same( expected, result )
      end)
    end)

    context( "when given multiple expressions", function()
      local input = "1, 2, 3"

      it( "adds a return for the whole line", function()
        local expected = "return 1, 2, 3"

        local result = console:wrap( input )
        assert.is.same( expected, result )
      end)
    end)
  end)

  describe( "prettify", function()
    context( "when given nil", function()
      local input = nil

      it( "returns 'nil'", function()
        local expected = { "nil" }

        local result = console:prettify( input )
        assert.is.same( expected, result )
      end)
    end)

    context( "when given a table", function()
      local input = { first = { inner = { 3, 1, 4 } }, second = 42 }

      it( "only includes the top level keys", function()
        local found_keys = {}
        local result = console:prettify( input )
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

      it( "returns the string as-is", function()
        local expected = { "hello world" }

        local result = console:prettify( input )
        assert.is.same( expected, result )
      end)
    end)

    context( "when given a number", function()
      local input = 412.3

      it( "returns the number as a string", function()
        local expected = { "412.3" }

        local result = console:prettify( input )
        assert.is.same( expected, result )
      end)
    end)
  end)

  describe "#eval" do
    context( "when input can't be compiled", function()
      local input = "("

      it( "returns a compilation error", function()
        local expected = {
          "! Compilation error: [string \"return (\"]:1: unexpected symbol near '<eof>'",
        }

        local result = console:eval( input )
        assert.is.same( expected, result )
      end)
    end)

    context( "when input can be compiled but not evaluated", function()
      local input = "doStuff()"

      it( "returns an evaluation error", function()
        local expected = {
          '! Evaluation error: [string "return doStuff()"]:1: attempt to call global \'doStuff\' (a nil value)',
        }

        local result = console:eval( input )
        assert.is.same( expected, result )
      end)
    end)
  end
end)
