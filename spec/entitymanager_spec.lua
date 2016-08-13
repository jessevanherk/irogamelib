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
                        values = { 'o', 'm', 'g', 'becky', 'look', 'at', 'her' },
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
    },
}

require( "utils" )

describe( "EntityManager", function()
    describe( "new()", function()
        it( "can be instantiated with no args", function() 
            local EM = EntityManager:new( entity_templates, component_templates )
            assert.is.equal( 'table', type( EM ) )
            assert.is.same( {}, EM.entities )
            assert.is.equal( entity_templates, EM.entity_templates )
        end)
    end)
    describe( "createEntity()", function()
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
    describe( "createEntity() [from template]", function()
        local EM = EntityManager:new( entity_templates, component_templates )
        local e1 = EM:createEntity( 'person' )
        local e2 = EM:createEntity( 'person', nil, { 'tag1', 'tag2' } )
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
        it( "is auto-tagged with the template name", function()
            assert.is_true( EM:entityHasTag( e1, 'person' ) )
            assert.is_true( EM:entityHasTag( e2, 'person' ) )
        end)
    end)
    describe( "getEntityWithTag()", function()
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
    describe( "addTagsToEntity()", function()
        local EM = EntityManager:new( entity_templates, component_templates )
        local e1 = EM:createEntity( 'person' )
        EM:addTagsToEntity( e1, { 'blueberry', 'muffin' } )
        it( "adds the appropriate tags", function()
            assert.is_true( EM:entityHasTag( e1, 'muffin' ) )
        end)
    end)
    describe( "removeTagsFromEntity()", function()
        local EM = EntityManager:new( entity_templates, component_templates )
        local e1 = EM:createEntity( 'person', nil, { 'tag1', 'tag2', 'tag3' } )
        EM:removeTagsFromEntity( e1, { 'tag2', 'nosuchtag' } )
        it( "no longer has the removed tags", function()
            assert.is_false( EM:entityHasTag( e1, 'tag2' ) )
            assert.is_false( EM:entityHasTag( e1, 'nosuchtag' ) )
        end)
        it( "still has the other tag", function()
            assert.is_true( EM:entityHasTag( e1, 'tag1' ) )
            assert.is_true( EM:entityHasTag( e1, 'tag3' ) )
        end)
        it( "is not returned by a search for the removed tag", function()
            local results = EM:getEntitiesWithTag( 'tag2' )
            local num_expected = 0
            assert.is_equal( num_expected, #results )
        end)
    end)
    describe( "deleteEntity()", function()
        local EM = EntityManager:new( entity_templates, component_templates )
        local e1 = EM:createEntity( 'person' )
        local id = e1.id
        EM:deleteEntity( e1 )
        it( "still exists as a table", function()
            assert.is_not_nil( e1 )
        end)
        it( "is in the list of deleted entities to be reaped", function()
            assert.is_not_nil( EM.deleted_entities[ id ] )
        end)
    end)
    describe( "reapEntities()", function()
        local EM = EntityManager:new( entity_templates, component_templates )
        local e1 = EM:createEntity( 'person', nil, { 'tag1', 'tag2' } )
        local e2 = EM:createEntity( 'person', nil, { 'tag1' } )
        local id1 = e1.id
        local id2 = e2.id
        EM:deleteEntity( e1 )
        EM:reapEntities()
        it( "returns other entity with specific component", function()
            local results = EM:getEntitiesWithComponent( 'identity' )
            assert.is_equal( 1, #results )
        end)
        it( "returns other entity with specific tag", function()
            local results = EM:getEntitiesWithTag( 'tag1' )
            assert.is_equal( 1, #results )
        end)
        it( "doesn't have anything in the list of entities to be reaped", function()
            assert.is_nil( EM.deleted_entities[ id1 ] )
            assert.is_nil( EM.deleted_entities[ id2 ] )
        end)
    end)
    describe( "deleteAllEntities()", function()
        local EM = EntityManager:new( entity_templates, component_templates )
        local e1 = EM:createEntity( 'person', nil, { 'tag1', 'tag2' } )
        local e2 = EM:createEntity( 'person', nil, { 'tag1' } )
        local id1 = e1.id
        local id2 = e2.id
        EM:deleteAllEntities()
        it( "returns zero entities with specific component", function()
            local results = EM:getEntitiesWithComponent( 'identity' )
            assert.is_equal( 0, #results )
        end)
        it( "returns zero entities with specific tag", function()
            local results = EM:getEntitiesWithTag( 'tag1' )
            assert.is_equal( 0, #results )
        end)
        it( "doesn't have anything in the list of entities to be reaped", function()
            assert.is_nil( EM.deleted_entities[ id1 ] )
            assert.is_nil( EM.deleted_entities[ id2 ] )
        end)
        it( "doesn't have anything in the list of entities by tag", function()
            local result1 = EM.tagged_entities[ 'tag1' ]
            assert.is_nil( result1 )
            local result2 = EM.tagged_entities[ 'tag2' ]
            assert.is_nil( result2 )
        end)
        it( "doesn't have anything in the list of entities by component", function()
            local result1 = EM.componented_entities[ 'identity' ]
            assert.is_nil( result2 )
            local result2 = EM.componented_entities[ 'complex' ]
            assert.is_nil( result2 )
        end)
    end)
end)
