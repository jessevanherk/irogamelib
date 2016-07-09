-- trace calls
-- original source from here:
-- http://download.redis.io/redis-stable/deps/lua/test/trace-calls.lua
--
--
-- example: lua -ltracer bisect.lua

local level = 0

local function hook( event )
    local t = debug.getinfo( 3 )
    io.stderr:write( level, " >>> " )
    if t ~= nil and t.currentline >= 0 then
        io.stderr:write( t.short_src, ":", t.currentline, " " )
    end
    t = debug.getinfo( 2 )
    if event == "call" then
        level = level + 1
    else
        level = level - 1
        if level < 0 then 
            level = 0 
        end
    end
    if t.what == "main" then
        if event == "call" then
            io.stderr:write( "begin ", t.short_src )
        else
            io.stderr:write( "end ", t.short_src )
        end
    elseif t.what == "Lua" then
        io.stderr:write( event, " ", t.name or "( Lua )", " <", t.linedefined, ":", t.short_src, ">" )
    else
        io.stderr:write( event, " ", t.name or "( C )", " [", t.what, "] " )
    end
    io.stderr:write( "\n" )
end

-- debug on (c)all and (r)eturn
debug.sethook( hook, "cr" )
level = 0
