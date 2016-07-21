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
    complex = {
        nested = {
            tables = {
                are = {
                    difficult = { 
                        values = { 3, 1, 4, 1, 5, 9 },
                    },
                },
            },
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
        complex = {},
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
    describe( "should properly instance templates, avoid aliasing", function()
        local EM = EntityManager:new( entity_templates, component_templates )
        local e1 = EM:createEntity( 'person' )
        local e2 = EM:createEntity( 'person' )
        it( "creates different top level entities", function()
            assert.is_not_equal( e1, e2 )
        end)
        it( "allows for changing simple component values", function()
            e2.identity.first_name = 'Alice'
            assert.is_equal( 'Bob', e1.identity.first_name )
            assert.is_equal( 'Alice', e2.identity.first_name )
        end)
        it( "allows for changing nested component values", function()
            e2.animation.frames.idle[ 1 ] = 'OTHER1'
            assert.is_equal( 'f01', e1.animation.frames.idle[ 1 ] )
            assert.is_equal( 'OTHER1', e2.animation.frames.idle[ 1 ] )
        end)
        it( "allows for changing deep nested component table values", function()
            table.remove( e2.complex.nested.tables.are.difficult.values, 2 )
            assert.is_equal( 4, e1.complex.nested.tables.are.difficult.values[ 3 ] )
            assert.is_equal( 5, e2.complex.nested.tables.are.difficult.values[ 4 ] )
        end)
    end)
end)
