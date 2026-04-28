local helpers = {}

function helpers.try(f, catch_f, ...)
    local status, exception = xpcall(f, debug.traceback, ...)
    if not status
    then
        catch_f(exception)
    end
end

function helpers.dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. helpers.dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
end

return helpers