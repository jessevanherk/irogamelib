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
  position_rel = {
    x = -2,
    y = -3,
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
    local mountain = space.entity_manager:createEntity( nil, { position_rel = {} }, { "rocky_mountain" } )

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

    context( "when tag partially matches another tag", function()
      it( "only finds exact matches", function()
        local result = space:find("#rocky")
        assert.is.same( { rock }, result )
      end)
    end)

    context( "when tag contains special characters", function()
      it( "finds the expected matches", function()
        local result = space:find("#rocky_mountain")
        assert.is.same( { mountain }, result )
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

    context( "when component partially matches another tag", function()
      it( "only finds exact matches", function()
        local result = space:find(".position")
        assert.is.same( { rock, person }, result )
      end)
    end)

    context( "when component name contains special characters", function()
      it( "finds the expected matches", function()
        local result = space:find(".position_rel")
        assert.is.same( { mountain }, result )
      end)
    end)
  end)
end)
