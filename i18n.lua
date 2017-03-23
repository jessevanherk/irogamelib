-- this is a namespace more than it is a module.

local I18n = {
    strings = {}
}


-- create new entity manager, pass in component data to use.
function I18n.init( locale_dir )
    local locale_strings = {}
    local files = love.filesystem.getDirectoryItems( locale_dir )

    for _, filename in ipairs( files ) do
        local locale_name = filename:match( "(.+).lua" )
        locale_strings[ locale_name ] = require( locale_dir .. "." .. locale_name )
    end

    I18n.locale_strings = locale_strings
end

function I18n.setLocale( locale )
    I18n.locale = locale
    if I18n.locale_strings[ locale ] then
        I18n.strings = I18n.locale_strings[ locale ]
    else
        I18n.strings = {} -- go back to defaults.
    end
end

-- main translation function.
-- this should be used ANY time you are OUTPUTTING a string. See dstr for data files though.
-- params is a list of variables to sub in.
-- the string template should look like:
--    "hello {1}, welcome to {2}."
function I18n.str( string, params )
    local translation = string
    if I18n.strings[ string ] then
        translation = I18n.strings[ string ]
    end

    -- super awesome lua code to replace all params at once.
    if params then
        return translation:gsub( "{(%d+)}", function( i ) return params[ tonumber( i ) ] or "" end )
    end

    return translation
end

-- dummy translation function.
-- basically just makes it easy to find strings that need translating later.
-- this should mainly just be used in data files.
function I18n.dstr( string )
    return string
end

-- return wrapper functions too
return I18n, I18n.str, I18n.dstr
