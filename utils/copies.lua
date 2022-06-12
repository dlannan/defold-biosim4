function string.split( str )
    lines = {}
    for s in str:gmatch("[^\r\n]+") do
        table.insert(lines, s)
    end
    return lines 
end

function table.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[table.deepcopy(orig_key)] = table.deepcopy(orig_value)
        end
        setmetatable(copy, table.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function table.shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            if(orig_value) then copy[orig_key] = orig_value end 
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function table.clone(org)
    return { unpack(org) }
end

function table.count( t)
    if(t == nil) then return 0 end 
    if(type(t) ~= "table") then return 0 end
    local count = 0
    for k,v in pairs(t) do 
        if(v) then count = count + 1 end
    end 
    return count 
end 