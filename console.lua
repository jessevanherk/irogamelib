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
function Console.eval( expression )
    local output = ""

    -- try to parse/compile it into lua code
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
        -- we're in the CONSOLE, so we want to access the global environment.
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
            err_str = results[ 2 ]
            output = '! Evaluation error: ' .. err_str
        end
    end

    return output
end

return Console
