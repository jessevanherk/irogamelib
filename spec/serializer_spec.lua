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
        x = { y = 3 },
      }

      it( "returns the table", function()
        local expected = "{\n  x = {\n    y = 3,\n  },\n}"

        assert.is.same( expected, serializer.getstring( input ) )
      end)
    end)
  end)
end)
