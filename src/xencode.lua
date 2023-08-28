function ordat(msg, idx)
    if #msg >= idx then
        return string.byte(msg, idx)
    end
    return 0
end

function sencode(msg, key)
    local l = #msg
    local pwd = {}
    for i = 0, l - 1, 4 do
        table.insert(pwd, ordat(msg, i+1) | ordat(msg, i + 2) << 8 | ordat(msg, i + 3) << 16 | ordat(msg, i + 4) << 24)
    end
    if key then
        table.insert(pwd, l)
    end
    return pwd
end

function lencode(msg, key)
    local l = #msg
    local ll = (l - 1) << 2
    if key then
        local m = msg[l]
        if m < ll - 3 or m > ll then
            return
        end
        ll = m
    end
    for i = 1, l do
        msg[i] = string.char(msg[i] & 0xff, msg[i] >> 8 & 0xff, msg[i] >> 16 & 0xff, msg[i] >> 24 & 0xff)
    end
    
    if key then
        return table.concat(msg):sub(1, ll+1)
    end
    return table.concat(msg)
end

function py_idx(idx)
    return idx + 1
end


function get_xencode(msg, key)
    if msg == "" then
        return ""
    end
    local pwd = sencode(msg, true)
    local pwdk = sencode(key, false)
    if #pwdk < 4 then
        for i = #pwdk + 1, 4 do
            table.insert(pwdk, 0)
        end
    end

    local n = #pwd - 1
    local z = pwd[py_idx(n)]
    local y = pwd[py_idx(0)]
    local c = 0x86014019 | 0x183639A0
    local m = 0
    local e = 0
    local p = 0
    local q = math.floor(6 + 52 / (n + 1))
    local d = 0
    while 0 < q do
        d = d + c & (0x8CE0D9BF | 0x731F2640)
        e = d >> 2 & 3
        p = 0
        while p < n do
            y = pwd[py_idx(p+1)]
            m = (z >> 5 ~ y << 2) + ((y >> 3 ~ z << 4) ~ (d ~ y))
            m = m + (pwdk[py_idx((p & 3) ~ e)] ~ z)
            pwd[py_idx(p)] = pwd[py_idx(p)] + m & (0xEFB8D130 | 0x10472ECF)
            z = pwd[py_idx(p)]
            p = p + 1
        end
        y = pwd[py_idx(0)]
        m = (z >> 5 ~ y << 2) + ((y >> 3 ~ z << 4) ~ (d ~ y))
        m = m + (pwdk[py_idx((p & 3) ~ e)] ~ z)
        pwd[py_idx(n)] = pwd[py_idx(n)] + m & (0xBB390742 | 0x44C6F8BD)
        z = pwd[py_idx(n)]
        q = q - 1
    end
    print(pwd)
    return lencode(pwd, false)
end

function bytes_to_hex(str)
    local hex = ''
    for i = 1, #str do
        local char = str:sub(i, i)
        local byte = string.format('%02x', string.byte(char))
        hex = hex .. byte
    end
    return hex
end

function printArray(t)
    local result = "{"
    for i, v in ipairs(t) do
        if i ~= 1 then
            result = result .. ", "
        end
        result = result .. v
    end
    result = result .. "}"
    print(result)
end