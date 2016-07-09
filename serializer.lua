local serializer = {}

function serializer.getAsFile( input, table_name )
    local serialized = serializer.getstring( input )
    local contents = "local " .. table_name .. " = " .. serialized .. "\r\nreturn " .. table_name .. "\r\n"
    return contents
end

-- getstring ~ by YellowAfterlife. http://yal.cc/lua-serializer/
-- Converts value back into string according to Lua presentation
-- Accepts strings, numbers, boolean values, and tables.
-- Table values are serialized recursively, so tables linking to themselves or
-- linking to other tables in "circles". Table indexes can be numbers, strings,
-- and boolean values.
-- local: fixed to also escape 'return' key . jvh, 20140726.
function serializer.getstring(object, multiline, depth, name)
    depth = depth or 0
    if multiline == nil then multiline = true end
    local padding = string.rep('    ', depth) -- can use '\t' if printing to file
    local r = padding -- result string
    if name then -- should start from name
        r = r .. (
            -- enclose in brackets if not string or not a valid identifier
            -- thanks to Boolsheet from #love@irc.oftc.net for string pattern
            (type(name) ~= 'string' or name:find('^([%a_][%w_]*)$') == nil or name == 'return')
            and ('[' .. (
                (type(name) == 'string')
                and string.format('%q', name)
                or tostring(name))
                .. ']')
            or tostring(name)) .. ' = '
    end
    if type(object) == 'table' then
        r = r .. '{' .. (multiline and '\r\n' or ' ')
        local length = 0
        for i, v in ipairs(object) do
            r = r .. serializer.getstring(v, multiline, multiline and (depth + 1) or 0) .. ','
                .. (multiline and '\r\n' or ' ')
            length = i
        end
        for i, v in pairs(object) do
            local itype = type(i) -- convert type into something easier to compare:
            itype =(itype == 'number') and 1
                or (itype == 'string') and 2
                or (itype == 'boolean') and 3
                or error('Serialize: Unsupported index type "' .. itype .. '"')
            local skip = -- detect if item should be skipped
                ((itype == 1) and ((i % 1) == 0) and (i >= 1) and (i <= length)) -- ipairs part
                or ((itype == 2) and (string.sub(i, 1, 1) == '_')) -- prefixed string
            if not skip then
                r = r .. serializer.getstring(v, multiline, multiline and (depth + 1) or 0, i) .. ','
                    .. (multiline and '\r\n' or ' ')
            end
        end
        r = r .. (multiline and padding or '') .. '}'
    elseif type(object) == 'string' then
        r = r .. string.format('%q', object)
    elseif type(object) == 'number' or type(object) == 'boolean' then
        r = r .. tostring(object)
    else
        error('Cannot serialize value "' .. tostring(object) .. '"')
    end
    return r
end

return serializer
