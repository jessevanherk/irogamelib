-- spec script. should NOT be bundled with final game.
-- for entitymanager.lua

-- load libraries. these can't all be mocked
require( "utils" )
EntityManager = require( "entitymanager" )

-- set up templates to use
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
    is_loop = true,
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
    position = { x = 42 },
    hitbox = { shape = 'circle' },
    animation = {
      is_loop = false,
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
  },
}

describe( "EntityManager", function()
  describe( "#new", function()
    context( "When no templates provided", function()
      local EM = EntityManager:new()

      it( "is instantiated", function()
        assert.is.equal( 'table', type( EM ) )
      end)

      it( "has an empty entities list", function()
        assert.is.same( {}, EM.entities )
      end)

      it( "has nil templates", function()
        assert.is_nil( EM.entity_templates )
        assert.is_nil( EM.component_templates )
      end)
    end)

    context( "When templates provided", function()
      local EM = EntityManager:new( entity_templates, component_templates )

      it( "is instantiated", function()
        assert.is.equal( 'table', type( EM ) )
      end)

      it( "has an empty entities list", function()
        assert.is.same( {}, EM.entities )
      end)

      it( "has the templates referenced", function()
        assert.is.equal( entity_templates, EM.entity_templates )
        assert.is.equal( component_templates, EM.component_templates )
      end)
    end)
  end)

  describe( "#createEntity", function()
    local EM = EntityManager:new( entity_templates, component_templates )

    context( "when no arguments provided", function()
      local entity = EM:createEntity()

      it( "has an entity id", function()
        assert.is_true( entity.id > 0 )
      end)

      it( "is in the main entities list", function()
        assert.is_truthy( EM.entities[ entity.id ] )
      end)

      it( "has an empty component list", function()
        assert.is_same( {}, entity.components )
      end)

      it( "has an empty tag list", function()
        assert.is_same( {}, entity.tags )
      end)
    end)

    context( "when arguments are present", function()
      local tags = { 'awesome', 'heroic' }
      local generic_entity = EM:createEntity( 'person', {}, tags )

      it( "has an entity id", function()
        assert.is_true( generic_entity.id > 0 )
      end)

      it( "is in the main entities list", function()
        assert.is_truthy( EM.entities[ generic_entity.id ] )
      end)

      context( "when only entity template provided", function()
        context( "when template exists", function()
          local entity = EM:createEntity( 'person', nil, tags )

          it( "has the components from the template", function()
            local expected = { 'animation', 'complex', 'hitbox', 'identity', 'position' }
            local result = table_keys( entity.components )
            table.sort( result )
            assert.is_same( expected, result )
          end)

          it( "has its own copies of the components", function()
            assert.is_not_equal( EM.component_templates.position, entity.position )
            assert.is_not_equal( EM.entity_templates.person.position, entity.position )
            assert.is_not_equal( EM.component_templates.animation.frames, entity.animation.frames )
            assert.is_not_equal( EM.entity_templates.person.animation.frames, entity.animation.frames )
          end)

          it( "has the values from the entity template", function()
            local expected = { x = 42, y = 12, angle = 0 }
            assert.is_same( expected, entity.position )
            assert.is_equal( 4, entity.complex.nested.tables.are.difficult.values[ 3 ] )
          end)

          it( "is auto-tagged with the template name", function()
            assert.is_true( entity.tags.person )
          end)

          it( "has the specified tags", function()
            assert.is_true( entity.tags.awesome )
            assert.is_true( entity.tags.heroic )
          end)
        end)

        context( "when template doesn't exist", function()
          it( "throws an error", function()
            expected = "unknown entity template 'some_unknown_template'"
            assert.has_error( function() EM:createEntity( "some_unknown_template" ) end, expected )
          end)
        end)
      end)

      context( "when adding components without template", function()
        local overrides = {
          identity = { first_name = 'Susan' }, position = { x = -4 },
        }
        local entity = EM:createEntity( nil, overrides, tags )

        it( "has the specified components", function()
          local expected = { 'identity', 'position' }
          local result = table_keys( entity.components )
          table.sort( result )
          assert.is_same( expected, result )
        end)

        it( "has its own copies of the components", function()
          assert.is_not_equal( EM.component_templates.position, entity.position )
          assert.is_not_equal( EM.component_templates.identity, entity.identity )
        end)

        it( "has values from the component template", function()
          assert.is_equal( 'Smith', entity.identity.last_name )
          assert.is_equal( 12, entity.position.y )
        end)

        it( "has values from the overrides", function()
          assert.is_equal( 'Susan', entity.identity.first_name )
          assert.is_equal( -4, entity.position.x )
        end)

        it( "has the expected tags", function()
          local entity_tags = table_keys( entity.tags )
          table.sort( entity_tags )
          local expected = { 'awesome', 'heroic' }
          assert.is_same( expected, entity_tags )
        end)
      end)

      context( "when specifying both template and overrides", function()
        local overrides = {
          identity = { first_name = 'Susan' }, position = { x = -4 },
        }
        local entity = EM:createEntity( 'person', overrides, tags )

        it( "has the expected components", function()
          local expected = { 'animation', 'complex', 'hitbox', 'identity', 'position' }
          local result = table_keys( entity.components )
          table.sort( result )
          assert.is_same( expected, result )
        end)

        it( "has its own copies of the components", function()
          assert.is_not_equal( EM.component_templates.position, entity.position )
          assert.is_not_equal( EM.component_templates.identity, entity.identity )
          assert.is_not_equal( EM.entity_templates.person.position, entity.position )
          assert.is_not_equal( EM.component_templates.animation.frames, entity.animation.frames )
          assert.is_not_equal( EM.entity_templates.person.animation.frames, entity.animation.frames )
        end)

        it( "has values from the component template", function()
          assert.is_equal( 'Smith', entity.identity.last_name )
          assert.is_equal( 12, entity.position.y )
        end)

        it( "has values from the entity template", function()
          assert.is_equal( 9, entity.complex.nested.tables.are.difficult.values[ 6 ] )
          assert.is_equal( 'circle', entity.hitbox.shape )
        end)

        it( "overrides strings", function()
          assert.is_equal( 'Susan', entity.identity.first_name )
        end)

        it( "overrides numbers", function()
          assert.is_equal( -4, entity.position.x )
        end)

        it( "overrides boolean values", function()
          assert.is_equal( false, entity.animation.is_loop )
        end)

        it( "has the expected tags", function()
          local entity_tags = table_keys( entity.tags )
          table.sort( entity_tags )
          local expected = { 'awesome', 'heroic', 'person' }
          assert.is_same( expected, entity_tags )
        end)

        context( "when the override is for a component isn't on the entity template", function()
          context( "when the component template exists", function()
            local good_overrides = { identity = { first_name = "Rocky" } }

            it( "adds the component", function()
              local entity = EM:createEntity( 'person', good_overrides, tags )

              assert.is.equal( true, entity.components.identity )
              assert.is_equal( "Smith", entity.identity.last_name )
            end)

            it( "uses the component override values", function()
              local entity = EM:createEntity( 'person', good_overrides, tags )

              assert.is_equal( "Rocky", entity.identity.first_name )
            end)

            it( "doesn't throw an error", function()
              assert.has_no_error( function() EM:createEntity( "rock", good_overrides, tags ) end )
            end)
          end)

          context( "when the component template does not exist", function()
            local bad_overrides = { ice_cream = { flavour = "Rocky Road" } }

            it( "throws an error", function()
              local expected = "unknown component 'ice_cream'"
              assert.has_error( function() EM:createEntity( "rock", bad_overrides, tags ) end, expected )
            end)
          end)
        end)
      end)
    end)

    context( "when making multiple instances", function()
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
    end)
  end)

  describe( "#getEntityWithTag", function()
    local EM = EntityManager:new( entity_templates, component_templates )
    EM:createEntity( 'rock' )
    local e1 = EM:createEntity( nil, nil, { 'foo', 'bar' } )

    context( "when no matching tagged entities", function()
      local result = EM:getEntityWithTag( 'wuzzle' )

      it( "returns nil", function()
        assert.is_nil( result )
      end)
    end)

    context( "when only one tagged entity", function()
      local result = EM:getEntityWithTag( 'foo' )
      it( "returns the tagged entity", function()
        assert.is_same( e1, result )
      end)
    end)

    context( "when multiple entities tagged", function()
      it( "returns the first matching entity", function()
        local result = EM:getEntityWithTag( 'bar' )
        assert.is_same( e1, result )
      end)
    end)
  end)

  describe( "#getEntitiesWithTag", function()
    local EM = EntityManager:new( entity_templates, component_templates )
    EM:createEntity( 'rock' )
    local e1 = EM:createEntity( nil, nil, { 'foo', 'bar' } )
    local e2 = EM:createEntity( nil, nil, { 'bar' } )

    context( "when no matching tagged entities", function()
      local results = EM:getEntitiesWithTag( 'wuzzle' )

      it( "returns an empty list", function()
        assert.is_same( {}, results )
      end)
    end)

    context( "when only one tagged entity", function()
      local results = EM:getEntitiesWithTag( 'foo' )

      it( "returns a single item list", function()
        local expected = { e1 }
        assert.is_same( expected, results )
      end)
    end)

    context( "when multiple entities tagged", function()
      local results = EM:getEntitiesWithTag( 'bar' )

      it( "returns all matching entities", function()
        local expected = { e1, e2 }
        assert.is_same( expected, results )
      end)
    end)
  end)

  describe( "#addTagsToEntity", function()
    local EM = EntityManager:new( entity_templates, component_templates )

    context( "when tags is nil", function()
      local e1 = EM:createEntity( 'person', nil, { 'chocolate' } )
      EM:addTagsToEntity( e1, nil )

      it( "has the original tags", function()
        assert.is_true( EM:entityHasTag( e1, 'chocolate' ) )
      end)
    end)

    context( "when tags is an empty list", function()
      local e1 = EM:createEntity( 'person', nil, { 'chocolate' } )
      EM:addTagsToEntity( e1, {} )

      it( "has the original tags", function()
        assert.is_true( EM:entityHasTag( e1, 'chocolate' ) )
      end)
    end)

    context( "when a single tag is specified", function()
      local e1 = EM:createEntity( 'person', nil, { 'chocolate' } )
      EM:addTagsToEntity( e1, { 'blueberry' } )

      it( "has the original tags", function()
        assert.is_true( EM:entityHasTag( e1, 'chocolate' ) )
      end)

      it( "adds the tags", function()
        assert.is_true( EM:entityHasTag( e1, 'blueberry' ) )
      end)

      it( "is found when searching for the tag", function()
        local result = EM:getEntityWithTag( 'blueberry' )
        assert.is_equal( e1, result )
      end)
    end)

    context( "when multiple tags specified", function()
      local e1 = EM:createEntity( 'person', nil, { 'chocolate' } )
      EM:addTagsToEntity( e1, { 'blueberry', 'muffin' } )

      it( "has the original tags", function()
        assert.is_true( EM:entityHasTag( e1, 'chocolate' ) )
      end)

      it( "adds the tags", function()
        assert.is_true( EM:entityHasTag( e1, 'blueberry' ) )
        assert.is_true( EM:entityHasTag( e1, 'muffin' ) )
      end)

      it( "is found when searching for an added tag", function()
        local result = EM:getEntityWithTag( 'muffin' )
        assert.is_equal( e1, result )
      end)
    end)
  end)

  describe( "#removeTagFromEntity", function()
    local EM = EntityManager:new( entity_templates, component_templates )

    context( "when tags is nil", function()
      local e1 = EM:createEntity( 'person', nil, { 'tag1', 'tag2', 'tag3' } )
      EM:removeTagFromEntity( e1, nil )

      it( "has the other tags", function()
        assert.is_true( EM:entityHasTag( e1, 'tag1' ) )
        assert.is_true( EM:entityHasTag( e1, 'tag3' ) )
      end)
    end)

    context( "when tag is valid", function()
      local e1 = EM:createEntity( 'person', nil, { 'tag1', 'tag2', 'tag3' } )
      EM:removeTagFromEntity( e1, 'tag2' )

      it( "has the other tags", function()
        assert.is_true( EM:entityHasTag( e1, 'tag1' ) )
        assert.is_true( EM:entityHasTag( e1, 'tag3' ) )
      end)

      it( "does not have the removed tag", function()
        assert.is_false( EM:entityHasTag( e1, 'tag2' ) )
      end)

      it( "is not returned by a search for the removed tags", function()
        local results = EM:getEntitiesWithTag( 'tag2' )
        local is_found = false
        for _, result in ipairs( results ) do
          if result == e1 then
            is_found = true
            break
          end
        end
        assert.is_false( is_found )
      end)
    end)

    context( "when tag is not present", function()
      local e1 = EM:createEntity( 'person', nil, { 'tag1', 'tag2', 'tag3' } )
      EM:removeTagFromEntity( e1, 'nosuchtag' )

      it( "has the other tags", function()
        assert.is_true( EM:entityHasTag( e1, 'tag1' ) )
        assert.is_true( EM:entityHasTag( e1, 'tag2' ) )
        assert.is_true( EM:entityHasTag( e1, 'tag3' ) )
      end)
    end)
  end)

  describe( "#removeTagsFromEntity", function()
    local EM = EntityManager:new( entity_templates, component_templates )
    local e1 = EM:createEntity( 'person', nil, { 'tag1', 'tag2', 'tag3' } )

    context( "when tags is nil", function()
      EM:removeTagsFromEntity( e1, nil )

      it( "has the other tags", function()
        assert.is_true( EM:entityHasTag( e1, 'tag1' ) )
        assert.is_true( EM:entityHasTag( e1, 'tag3' ) )
      end)
    end)

    context( "when tags is an empty list", function()
      EM:removeTagsFromEntity( e1, {} )

      it( "has the other tags", function()
        assert.is_true( EM:entityHasTag( e1, 'tag1' ) )
        assert.is_true( EM:entityHasTag( e1, 'tag3' ) )
      end)
    end)

    context( "when multiple tags are specified", function()
      EM:removeTagsFromEntity( e1, { 'tag2', 'nosuchtag' } )

      it( "no longer has the removed tags", function()
        assert.is_false( EM:entityHasTag( e1, 'tag2' ) )
        assert.is_false( EM:entityHasTag( e1, 'nosuchtag' ) )
      end)

      it( "has the other tags", function()
        assert.is_true( EM:entityHasTag( e1, 'tag1' ) )
        assert.is_true( EM:entityHasTag( e1, 'tag3' ) )
      end)

      it( "is not returned by a search for the removed tags", function()
        local result = EM:getEntityWithTag( 'tag2' )
        assert.is_nil( result )
      end)
    end)
  end)

  describe( "#deleteEntity", function()
    local EM = EntityManager:new( entity_templates, component_templates )
    local e1 = EM:createEntity( 'person' )
    local e2 = EM:createEntity( 'person' )
    local id = e1.id

    context( "when entity is nil", function()
      it( "throws an error", function()
        local expected = "can't delete nonexistant entity"
        assert.has_error( function() EM:deleteEntity() end, expected )
      end)
    end)

    context( "when entity is valid", function()
      EM:deleteEntity( e1 )

      it( "still exists", function()
        assert.is_not_nil( e1 )
        assert.is_equal( id, e1.id )
      end)

      it( "is in the list of deleted entities to be reaped", function()
        assert.is_not_nil( EM.deleted_entities[ id ] )
      end)
    end)

    context( "when entity is waiting to be reaped", function()
      EM:deleteEntity( e2 ) -- delete once.
      EM:deleteEntity( e2 ) -- try deleting again.

      it( "is in the list of deleted entities to be reaped", function()
        assert.is_not_nil( EM.deleted_entities[ id ] )
      end)
    end)
  end)

  describe( "#reapEntities", function()
    local EM = EntityManager:new( entity_templates, component_templates )
    local e1 = EM:createEntity( 'person', nil, { 'deleter' } )
    local e2 = EM:createEntity( 'person', nil, { 'keeper' } )

    context( "when there are no entities to reap", function()
      EM:reapEntities()

      it( "empties the list of deleted entities", function()
        assert.is_same( {}, EM.deleted_entities )
      end)
    end)

    context( "when there are entities to reap", function()
      EM:deleteEntity( e1 )
      EM:reapEntities()

      it( "empties the list of deleted entities", function()
        assert.is_same( {}, EM.deleted_entities )
      end)

      it( "doesn't delete other entities", function()
        local result = EM:getEntityWithTag( 'keeper' )
        assert.is_equal( e2, result )
      end)
    end)
  end)

  describe( "#deleteAllEntities", function()
    context( "when there are no entities", function()
      local EM = EntityManager:new( entity_templates, component_templates )
      EM:deleteAllEntities()

      it( "doesn't have anything in the list of entities to be reaped", function()
        assert.is_same( {}, EM.deleted_entities )
      end)

      it( "doesn't have anything in the list of entities by tag", function()
        local result1 = EM.tagged_entities[ 'tag1' ]
        assert.is_nil( result1 )
        local result2 = EM.tagged_entities[ 'tag2' ]
        assert.is_nil( result2 )
      end)

      it( "doesn't have anything in the list of entities by component", function()
        local result1 = EM.componented_entities[ 'identity' ]
        assert.is_nil( result1 )
        local result2 = EM.componented_entities[ 'complex' ]
        assert.is_nil( result2 )
      end)
    end)

    context( "when there are entities", function()
      local EM = EntityManager:new( entity_templates, component_templates )
      EM:createEntity( 'person', nil, { 'tag1', 'tag2' } )
      EM:createEntity( 'person', nil, { 'tag1' } )
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
        assert.is_same( {}, EM.deleted_entities )
      end)

      it( "doesn't have anything in the list of entities by tag", function()
        local result1 = EM.tagged_entities[ 'tag1' ]
        assert.is_nil( result1 )
        local result2 = EM.tagged_entities[ 'tag2' ]
        assert.is_nil( result2 )
      end)

      it( "doesn't have anything in the list of entities by component", function()
        local result1 = EM.componented_entities[ 'identity' ]
        assert.is_nil( result1 )
        local result2 = EM.componented_entities[ 'complex' ]
        assert.is_nil( result2 )
      end)
    end)
  end)

  describe( "#getEntityData", function()
    local EM = EntityManager:new( entity_templates, component_templates )

    context( "when entity is nil", function()
      local components, tags = EM:getEntityData( nil )

      it( "returns an empty list of components", function()
        assert.is_same( {}, components )
      end)

      it( "returns an empty list of tags", function()
        assert.is_same( {}, tags )
      end)
    end)

    context( "when entity has tags and components", function()
      local entity = EM:createEntity( 'rock', nil, { 'rocky', 'heroic' } )
      local components, tags = EM:getEntityData( entity )
      table.sort( tags )

      it( "has the expected components", function()
        local expected = {
          position = { x = 10, y = 12, angle = 0 },
          hitbox = { shape = 'triangle', offset = { x = 23, y = 43 } },
        }
        assert.is_same( expected, components )
      end)

      it( "has the expected tags", function()
        local expected = { 'heroic', 'rock', 'rocky' }
        assert.is_same( expected, tags )
      end)
    end)
  end)

  describe( "#getAllEntitiesData", function()
    local EM = EntityManager:new( entity_templates, component_templates )

    context( "when no entities", function()
      local results = EM:getAllEntitiesData()

      it( "returns an empty list", function()
        assert.is_same( {}, results )
      end)
    end)

    context( "when one entity present", function()
      local entity = EM:createEntity( 'rock', nil, { 'rocky', 'heroic' } )
      local results = EM:getAllEntitiesData()
      local result = results[ 1 ]
      local id, components, tags = result.id, result.components, result.tags
      table.sort( tags )

      it( "has the expected components", function()
        local expected = {
          position = { x = 10, y = 12, angle = 0 },
          hitbox = { shape = 'triangle', offset = { x = 23, y = 43 } },
        }
        assert.is_same( expected, components )
      end)

      it( "has the expected tags", function()
        local expected = { 'heroic', 'rock', 'rocky' }
        assert.is_same( expected, tags )
      end)

      it( "has the expected id", function()
        local expected = entity.id
        assert.is_same( expected, id )
      end)
    end)
  end)
end)
