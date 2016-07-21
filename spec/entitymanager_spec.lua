-- spec script. should NOT be bundled with final game.
-- for lib/map.lua

-- load third party libraries. these can't all be mocked
EntityManager = require( "entitymanager" )

local component_templates = {
    identity = {
        first_name = 'Bob',
        last_name  = 'Smith',
    },
    position = {
        x = 10,
        y = 12,
        angle = 0,
    },
    hitbox = {
        offset = { x = 23, y = 43 },
        shape = 'rectangle',
    },
    animation = {
        sequence = 'idle',
        frame_id = 1,
        frames = {
            idle = { 'f01', 'f02' },
        },
    },
}
local entity_templates = { 
    rock = {
        position = {},
        hitbox = { shape = 'triangle' },
    },
    person = {
        identity = {},
        position = {},
        hitbox = { shape = 'circle' },
        animation = {},
    },

}

require( "utils" )

describe( "EntityManager library", function()
    describe( "can be instantiated", function()
        it( "can be instantiated with no args", function() 
            local EM = EntityManager:new( entity_templates, component_templates )
            assert.is.equal( 'table', type( EM ) )
            assert.is.same( {}, EM.entities )
            assert.is.equal( entity_templates, EM.entity_templates )
        end)
    end)
    describe( "should properly create an entity", function()
        local EM = EntityManager:new( entity_templates, component_templates )
        it( "creates a new entity", function()
            local tags = { 'foo', 'bar' }
            local components = { identity = { first_name = 'Fred' }, position = { x = -4 } }
            local entity = EM:createEntity( 'person', components, tags )

            assert.is_true( entity.id > 0 )
            assert.is_not.equal( nil, entity.tags )
            assert.is_true( EM:entityHasTag( entity, 'foo' ) )
            assert.is.same( { first_name = 'Fred', last_name = 'Smith' }, entity.identity )
            assert.is.same( { x = -4, y = 12, angle = 0 }, entity.position )
        end)
    end)
    describe( "should find entities by tag", function()
        local EM = EntityManager:new( entity_templates, component_templates )
        local tags = { 'foo', 'bar' }
        local expected1 = EM:createEntity( 'rock', nil, tags )
        it( "finds a single entity by tag", function()
            local result = EM:getEntityWithTag( 'foo' )
            assert.is_equal( expected1.id, result.id )
        end)
        local expected2 = EM:createEntity( person, nil, tags )
        it( "finds multiple entities by tag", function()
            local results = EM:getEntitiesWithTag( 'foo' )
            local result = results[ 2 ]
            assert.is_equal( expected2.id, result.id )
            assert.is_equal( 2, #results )
        end)
    end)
end)
