require( "spec.spec_helper" )

describe( "Class", function()
  context( "when base class is not specified", function()
    describe( "creating a new class", function()
      it( "should return an object", function()
        local MyClass = Class()
        assert.is_not_nil( MyClass )
      end)

      it( "should use the base class", function()
        local MyClass = Class()
        assert.are.equal( type( MyClass._init ), "function" )
      end)
    end)
  end)

  context( "when base class is specified", function()
    local MyBaseClass = Class()
    function MyBaseClass:special() print( "I am special" ) end
    function MyBaseClass:override_me() print( "from the base" ) end

    describe( "creating a new class", function()
      it( "should return an object", function()
        local MyClass = Class( MyBaseClass )
        assert.is_not_nil( MyClass )
      end)

      it( "should inherit methods from the parent", function()
        local MyClass = Class( MyBaseClass )
        assert.are.equal( type( MyClass.special ), "function" )
      end)

      it( "should override existing methods", function()
        local MyClass = Class( MyBaseClass )
        assert.are.equal( type( MyClass.special ), "function" )
      end)
    end)
  end)

  context( "when inheriting multiple times", function()
    local GrandparentClass = Class()
    function GrandparentClass:special() print( "I am special" ) end
    local ParentClass = Class( GrandparentClass )

    describe( "creating a new class", function()
      it( "should return an object", function()
        local ChildClass = Class( ParentClass )
        assert.is_not_nil( ChildClass )
      end)

      it( "should inherit functions from the grandparent", function()
        local ChildClass = Class( ParentClass )
        assert.are.equal( type( ChildClass.special ), "function" )
      end)
    end)
  end)
end)
