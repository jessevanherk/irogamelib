-- load libraries. these can't all be mocked
require( "utils" )
Space = require( "space" )
_G['EntityManager'] = require( "entitymanager" )
_G['SystemManager'] = require( "systemmanager" )

_G['Signal'] = {}
_G['Timer'] = {}
stub( Signal, "new" )
stub( Timer, "new" )

-- set up templates to use
local component_templates = {
  identity = {
    first_name = 'Bob',
    last_name  = 'Smith',
  },
  position = {
    x = 10,
    y = 12,
  },
}

local entity_templates = {
  rock = {
    position = {},
  },
  person = {
    identity = {},
    position = { x = 42 },
  },
}

describe( "Space", function()
  describe( "find()", function()
    local space = Space:new( entity_templates, component_templates )
    local rock = space.entity_manager:createEntity( 'rock', nil, { "rocky", "heroic" } )
    local person = space.entity_manager:createEntity( 'person', nil, { "Rocky", "boxer", "heroic" } )

    context( "when searching by ID", function()
      it( "finds the expected results", function()
        local result = space:find(1)
        assert.is.equal( rock, result )
      end)
    end)

    context( "when searching by nonexistant ID", function()
      it( "finds the expected results", function()
        local result = space:find(1123)
        assert.is_nil( result )
      end)
    end)

    context( "when searching for a tag", function()
      it( "finds the expected results", function()
        local result = space:find("#heroic")
        assert.is.same( { rock, person }, result )
      end)
    end)

    context( "when searching for a nonexistant tag", function()
      it( "finds the expected results", function()
        local result = space:find("#asdasdsad")
        assert.is.same( {}, result )
      end)
    end)

    context( "when searching for a component", function()
      it( "finds the expected results", function()
        local result = space:find(".identity")
        assert.is.same( { person }, result )
      end)
    end)

    context( "when searching for a nonexistant component", function()
      it( "finds the expected results", function()
        local result = space:find(".asdasdsad")
        assert.is.same( {}, result )
      end)
    end)
  end)
end)
