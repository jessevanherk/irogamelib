local serializer = require( 'serializer' )

describe( "Serializer", function()
  describe( "getAsFile", function()
    context( "when input is empty", function()
      local input = {}

      it( "returns an empty table", function()
        local expected = "local foo = {\n}\nreturn foo\n"

        assert.is.same( expected, serializer.getAsFile( input, "foo" ) )
      end)
    end)

    context( "when input is not empty", function()
      local input = {
        x = { y = 3 },
      }

      it( "returns the table", function()
        local expected = "local foo = {\n  x = {\n    y = 3,\n  },\n}\nreturn foo\n"

        assert.is.same( expected, serializer.getAsFile( input, "foo" ) )
      end)
    end)
  end)

  describe( "getstring", function()
    context( "when input is nil", function()
      local input = nil

      it( "returns an empty table", function()
        local expected = nil

        local result = serializer.getstring( input )
        assert.is.same( expected, result )
      end)
    end)

    context( "when input is empty", function()
      local input = {}

      it( "returns an empty table", function()
        local expected = "{\n}"

        local result = serializer.getstring( input )
        assert.is.same( expected, result )
      end)
    end)

    context( "when input is not empty", function()
      local input = {
        x = { y = 3, z = false },
        y = { 3, 1, 4, 1, syn = "ack" },
      }

      it( "returns the table", function()
        local expected = '{\n  y = {\n    3,\n    1,\n    4,\n    1,\n    syn = "ack",\n  },\
  x = {\n    y = 3,\n    z = false,\n  },\n}'

        assert.is.same( expected, serializer.getstring( input ) )
      end)
    end)

    context( "when name is specified", function()
      local input = {
        x = { y = 3, z = false },
        y = { 3, 1, 4, 1, syn = "ack" },
      }

      it( "returns the table", function()
        local expected = 'foo = {\n  y = {\n    3,\n    1,\n    4,\n    1,\n    syn = "ack",\n  },\
  x = {\n    y = 3,\n    z = false,\n  },\n}'

        assert.is.same( expected, serializer.getstring( input, true, 0, "foo" ) )
      end)
    end)

    context( "when input has a circular reference", function()
      local a = {
        ref_to_b = nil,
      }
      local b = {
        ref_to_a = a,
      }
      a.ref_to_b = b

      it( "returns the table without recursion", function()
        local expected = "{\n  ref_to_b = {\n    y = 3,\n  },\n}"

        assert.is.same( expected, serializer.getstring( a ) )
      end)
    end)
  end)
end)
