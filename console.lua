-- console module.
-- author: Jesse van Herk <jesse@imaginaryrobots.net>

local Console = {}

function Console:new( ... )
    local instance = {}
    setmetatable( instance, self )
    self.__index = self
    self._init( instance, ... )
    return instance
end

function Console:_init( ... )

end

-- context is a table of variables we want to operate on.
-- they get copied in to the top level for evaluating.
function Console.eval( expression, context )
    local output = ""

    -- evaluate it (or try to)
    -- catch errors!
    local func, err_str = loadstring( expression )

    -- Compilation error
    if not func then
        if err_str then
            -- Could be an expression instead of a statement -- try auto-adding return before it
            func, err_str = loadstring( "return " .. expression )
            if err_str then
                output = '! Compilation error: ' .. err_str
                return false
            end
        else
            output = '! Unknown compilation error'
        end
    end

    -- It compiled. Try evaluating it.
    if func then
        -- make sure function is executed in a safe environment
        -- so it can't clobber the global environment, purposely or accidentally.
        -- pre-load it with a copy of the standard globals.
        local new_env = {}        -- create new environment
        setmetatable( new_env, { __index = _G } )
        setfenv( func, new_env )

        -- make sure our context data is available
        if context then
            for key, value in pairs( context ) do
                new_env[ key ] = value
            end
        end

        local results = { pcall( func ) }

        local success = results[ 1 ]  -- grab the first item, which is the success code
        if success then
            local escaped = {}
            -- copy everything else into a new list, escaping as we go
            for i = 2, #results do
                table.insert( escaped, tostring( results[ i ] ) )
            end
            output = table.concat( escaped, ", " )
        else
            local err_str = results[ 2 ]
            output = '! Evaluation error: ' .. err_str
        end
    end

    return output
end

return Console
