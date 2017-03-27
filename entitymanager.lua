--------------------------------
-- Entity Manager , takes care of all creation/update/search of entities.
-- entities and components are JUST DATA - think of this like a DB Model,
-- returning resultsets, NOT objects. Performance matters, so don't split
-- things into sub classes.
-- should NOT know about rendering engine or systems.

local EntityManager = {}

-- magic constructor for the system. real init code goes in init().
function EntityManager:new( ... )
  local instance = {}
  setmetatable( instance, self )
  self.__index = self
  self._init( instance, ... )
  return instance
end

-- entity_templates are named tables so we can quickly create new entities then override as needed.
-- component_templates are named tables, basically the default values for each component.
function EntityManager:_init( entity_templates, component_templates, create_cb )
  -- store entity and component templates for later use. avoids globals.
  self.entity_templates = entity_templates
  self.component_templates = component_templates

  -- set up some indexes for fast retrieval
  self.entities = {}
  self.tagged_entities = {}
  self.componented_entities = {}

  -- additional lists for managing entities
  self.deleted_entities = {}  -- store deleted entities so they can be reaped together

  -- set callback
  if create_cb then
    assert( type( create_cb ) == 'function', "create callback must be a function" )
    self.on_create = create_cb
  end
end

-- should be called once in the update callback.
function EntityManager:update( dt )
  -- reap old entities
  self:reapEntities()
end

-----------------
-- Top-level Entity functions
-----------------

-- createEntity( template_name, components, tags )
-- create a new entity
-- if template_name is nil, then don't use a template, just build it from the given components.
-- otherwise, components and tags can be empty/skipped.
-- return the new entity
function EntityManager:createEntity( template_name, component_overrides, tags )
  local new_id = #(self.entities) + 1  -- get next available id. Works even on sparse hash!
  -- create the basic entity structure.
  local entity = {
    id = new_id,     -- store the id inside the entity as well
    tags = {},       -- entity tracks what tags it has
    components = {}, -- tracks which components present, this is NOT the data.
  }
  self.entities[ entity.id ] = entity

  -- fetch the component overrides from the given entity template.
  if template_name and self.entity_templates[ template_name ] then
    local entity_template = self.entity_templates[ template_name ]

    for component_name, template_overrides in pairs( entity_template ) do
      -- first, copy the component defaults onto our new entity
      -- then use template overrides right away
      self:addComponentToEntity( entity, component_name, template_overrides )
    end
    -- now layer on the instance-specific overrides.
    self:updateEntityComponents( entity, component_overrides )

    -- tag it with the template used, since that's the most common use for tags.
    self:addTagToEntity( entity, template_name )
  elseif template_name then -- specified a template, but can't find it
    error( "unknown entity template '" .. template_name .. "'" )
  else
    -- no template, just use the component defaults as well as the instance-specific overrides
    self:addComponentsToEntity( entity, component_overrides )
  end

  -- add entity to all of the relevant tag lists/indexes
  if ( tags and #tags > 0 ) then
    self:addTagsToEntity( entity, tags )
  end

  -- invoke the creation callback
  if self.on_create then
    self.on_create( entity )
  end

  return entity
end

function EntityManager:updateEntityComponents( entity, components )
  if ( components ) then
    for component_name, overrides in pairs( components ) do
      self:updateEntityComponent( entity, component_name, overrides )
    end
  end
end

function EntityManager:updateEntityComponent( entity, component_name, overrides )
  if not entity.components[ component_name ] then
    error( "entity id " .. entity.id .. " does not have component '" .. component_name .. "'" )
  end

  -- keep it simple.
  for key, override in pairs( overrides ) do
    if ( type( override ) ~= 'table' ) then
      -- easy, just copy it over directly.
      entity[ component_name ][ key ] = override
    else -- it's a sub-table.
      -- FIXME: this isn't super robust, in that we can't have arbitrary nesting.
      -- in practice, I haven't used more nesting than this (or I'm clobbering it all anyway)

      -- ensure target table exists.
      if type( entity[ component_name ][ key ] ) ~= 'table' then
        entity[ component_name ][ key ] = {}
      end
      for sub_key, sub_value in pairs( override ) do
        entity[ component_name ][ key ][ sub_key ] = sub_value
      end
    end
  end
end

-- deleteEntity( entity )
-- mark an existing entity for deletion. okay to call from systems/callbacks.
-- note that the entity will not actually be deleted until reapEntities()
-- is called.
function EntityManager:deleteEntity( entity )
  assert( entity, "can't delete nonexistant entity" )
  -- just flag the entity as deleted.
  self.deleted_entities[ entity.id ] = entity
end

function EntityManager:deleteAllEntities()
  for id, entity in pairs( self.entities ) do
    self:deleteEntity( entity )
  end
  self:reapEntities()

  -- since we've deleted everything, clear out all indices.
  self.entities = {}
  self.tagged_entities = {}
  self.componented_entities = {}
end

-- reapEntities()
-- go through the list of deleted entities and remove them completely
-- should be called once at the end of the update callback.
function EntityManager:reapEntities()
  for id, entity in pairs( self.deleted_entities ) do
    self:_reapEntity( entity )
  end
  -- reset the list of deleted entities.
  self.deleted_entities = {}
end

-- internal method
function EntityManager:_reapEntity( entity )
  local id = entity.id
  -- remove components and indexes first.
  self:removeAllTagsFromEntity( entity )
  self:removeAllComponentsFromEntity( entity )

  -- remove the actual entity from the master list.
  self.entities[ id ] = nil
end

-----------------
-- Component functions
-----------------

-- addComponentsToEntity( entity, components )
--  add multiple components to an entity
function EntityManager:addComponentsToEntity( entity, components )
  if ( components ) then
    for component_name, overrides in pairs( components ) do
      self:addComponentToEntity( entity, component_name, overrides )
    end
  end
end

-- addComponentToEntity( entity, component_name, overrides )
--  add a single component to an entity
function EntityManager:addComponentToEntity( entity, component_name, overrides )
  -- ensure the component is tracked on the entity itself.
  entity.components[ component_name ] = true

  if self.component_templates[ component_name ] ~= nil then
    -- deep-copy the component template onto the entity
    -- override with any values that were passed in.
    -- these may be coming from the entity template.
    local component_template = self.component_templates[ component_name ]
    entity[ component_name ] = deepmerge( component_template, overrides )
  else
    -- this is only an informative message.
    print( "addComponentToEntity: unknown component '" .. component_name .. "'. Check for typos?" )
  end

  -- add this entity to the index so we can quickly find it
  -- first make sure we've got an index for this component name
  if self.componented_entities[ component_name ] == nil then
    self.componented_entities[ component_name ] = {}
  end
  -- add this entity id to the index for this component.
  self.componented_entities[ component_name ][ entity.id ] = entity
end

-- removeAllComponentsFromEntity( entity )
--  clear out all components from the entity. used by reap/etc.
function EntityManager:removeAllComponentsFromEntity( entity )
  for component_name, _ in pairs( entity.components ) do
    self:removeComponentFromEntity( entity, component_name )
  end
end

-- removeComponentsFromEntity( entity, components )
--  remove multiple components from an entity
function EntityManager:removeComponentsFromEntity( entity, components )
  for component_name, _ in pairs( components ) do
    self:removeComponentFromEntity( entity, component_name )
  end
end

-- removeComponentFromEntity( entity, component_name )
--  remove a single component from an entity
function EntityManager:removeComponentFromEntity( entity, component_name )
  if not component_name then
    return  -- success, I guess.
  end
  -- remove the component from the entity itself
  entity[ component_name ] = nil

  -- remove the entity from the index for that component
  self.componented_entities[ component_name ][ entity.id ] = nil
end

-- getEntitiesWithComponent( component_name )
-- get the list of all entities having the given component
-- return as a basic table, not a hash.
function EntityManager:getEntitiesWithComponent( component_name )
  local matching_entities = {}
  if self.componented_entities[ component_name ] then
    for id, entity in pairs( self.componented_entities[ component_name ] ) do
      matching_entities[ #matching_entities + 1 ] = entity
    end
  end

  return matching_entities
end

-- getEntitiesWithComponents( components )
-- get the list of all entities having ALL of the given components
function EntityManager:getEntitiesWithComponents( components )
  local matching_entities = {}
  -- get the list of entities with the fist required component
  local potential_entities = self:getEntitiesWithComponent( components[ 1 ] )
  for _, entity in ipairs( potential_entities ) do
    -- make sure this entity has all of the required components
    local has_all = true
    for _, component_name in ipairs( components ) do
      if not entity[ component_name ] then  -- doesn't have this one
        has_all = false
        break
      end
    end

    if has_all then
      matching_entities[ #matching_entities + 1 ] = entity
    end
  end

  return matching_entities
end

function EntityManager:entityHasComponent( entity, component_name )
  local has_component = false
  if entity.components[ component_name ] then
    has_component = true
  end
  return has_component
end


-----------------
-- Tag functions
-----------------

-- addTagsToEntity( entity, tags )
--  add multiple tags to an entity
function EntityManager:addTagsToEntity( entity, tags )
  if tags then
    for _, tag_name in ipairs( tags ) do
      self:addTagToEntity( entity, tag_name )
    end
  end
end

-- addTagToEntity( entity, tag_name )
--  add a single tag to an entity
function EntityManager:addTagToEntity( entity, tag_name )
  if not tag_name then
    return
  end
  -- ensure the tag is represented on the entity itself
  entity.tags[ tag_name ] = true

  -- add this entity id to the index for this tag.
  -- make sure index exists for this tag.
  if self.tagged_entities[ tag_name ] == nil then
    self.tagged_entities[ tag_name ] = {}
  end
  -- add the actual entity.
  self.tagged_entities[ tag_name ][ entity.id ] = entity
end

-- removeAllTagsFromEntity( entity )
--  clear out all tags from the entity. used by reap/etc.
function EntityManager:removeAllTagsFromEntity( entity )
  for tag_name, _ in pairs( entity.tags ) do
    self:removeTagFromEntity( entity, tag_name )
  end
end

-- removeTagsFromEntity( entity, tags )
--  remove multiple tags from an entity
function EntityManager:removeTagsFromEntity( entity, tags )
  if tags then
    for _, tag_name in ipairs( tags ) do
      self:removeTagFromEntity( entity, tag_name )
    end
  end
end

-- removeTagFromEntity( entity, tag_name )
--  remove a single tag from an entity
function EntityManager:removeTagFromEntity( entity, tag_name )
  -- remove the tag from the entity
  if not tag_name then
    return -- success, ish.
  end
  -- clear it off of the entity itself.
  entity.tags[ tag_name ] = nil

  -- remove the entity from the index for that tag
  if self.tagged_entities[ tag_name ] then
    self.tagged_entities[ tag_name ][ entity.id ] = nil
  end
end

-- getEntitiesWithTag( tag_name )
-- get the list of all entities having the given tag
-- also returns a count of the entities
function EntityManager:getEntitiesWithTag( tag_name )
  local matching_entities = {}
  if self.tagged_entities[ tag_name ] then
    for id, entity in pairs( self.tagged_entities[ tag_name ]  ) do
      matching_entities[ #matching_entities + 1 ] = entity
    end
  end

  return matching_entities
end

function EntityManager:entityHasTag( entity, tag_name )
  local has_tag = false
  if entity.tags[ tag_name ] then
    has_tag = true
  end
  return has_tag
end

function EntityManager:getEntityById( id )
  assert( id > 0, "entity ID must be greater than zero" )
  return self.entities[ id ]
end

-- getEntityWithTag( tag_name )
-- get the FIRST entity with the given tag
-- only useful when you're expecting only a single entity to have this tag.
function EntityManager:getEntityWithTag( tag_name )
  local entity = nil
  local tagged_entities = self:getEntitiesWithTag( tag_name )
  if tagged_entities and #tagged_entities > 0 then
    -- take the first one in the list.
    entity = tagged_entities[ 1 ]
  end

  return entity
end

-- output the given entity as tables, suitable for use as overrides.
-- returns two tables - one of components, one of tags.
function EntityManager:getEntityData( entity )
  local data_tags = {}
  local data_components = {}

  if entity then
    -- FIXME: test for references, keep them from breaking
    for component_name, _ in pairs( entity.components ) do
      data_components[ component_name ] = deepcopy( entity[ component_name ] )
    end

    -- return tags as a flat list.
    for tag_name, _ in pairs( entity.tags ) do
      data_tags[ #data_tags + 1 ] = tag_name
    end
  end

  return data_components, data_tags
end

function EntityManager:getEntitiesData( entities )
  local results = {}
  for id, entity in pairs( entities ) do
    local data_components, data_tags = self:getEntityData( entity )
    local entity_data = {
      id = id,
      components = data_components,
      tags = data_tags,
    }
    results[ #results + 1 ] = entity_data
  end

  return results
end

function EntityManager:getAllEntitiesData()
  local entities = self.entities
  local results = self:getEntitiesData( entities )

  return results
end

function EntityManager:getTaggedEntitiesData( tag )
  local entities = self.getEntitiesWithTag( tag )
  local results = self:getEntitiesData( entities )

  return results
end

return EntityManager
