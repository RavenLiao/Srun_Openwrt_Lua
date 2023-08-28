function base64_encode(s)
    local _PADCHAR = "="
    local _ALPHA = "LVoJPiCN2R8G90yg+hmFHuacZ1OWMnrsSTXkYpUq/3dlbfKwv6xztjI7DeBE45QA"
    local i=0
    local b10=0
    local x = {}
    local imax = #s - #s % 3
    if #s == 0 then
        return s
    end
    for i = 1, imax, 3 do
        b10 = (string.byte(s, i) * 2^16) + (string.byte(s, i + 1) * 2^8) + string.byte(s, i + 2)
        table.insert(x, string.sub(_ALPHA, math.floor(b10 / 2^18) + 1, math.floor(b10 / 2^18) + 1))
        table.insert(x, string.sub(_ALPHA, math.floor((b10 / 2^12) % 64) + 1, math.floor((b10 / 2^12) % 64) + 1))
        table.insert(x, string.sub(_ALPHA, math.floor((b10 / 2^6) % 64) + 1, math.floor((b10 / 2^6) % 64) + 1))
        table.insert(x, string.sub(_ALPHA, math.floor(b10 % 64) + 1, math.floor(b10 % 64) + 1))
    end
    i=imax
    if #s - imax == 1 then
        b10 = string.byte(s, i + 1) * 2^16
        table.insert(x, string.sub(_ALPHA, math.floor(b10 / 2^18) + 1, math.floor(b10 / 2^18) + 1) .. string.sub(_ALPHA, math.floor((b10 / 2^12) % 64) + 1, math.floor((b10 / 2^12) % 64) + 1) .. _PADCHAR .. _PADCHAR)
    elseif #s - imax == 2 then
        b10 = (string.byte(s, i + 1) * 2^16) + (string.byte(s, i + 2) * 2^8)
        table.insert(x, string.sub(_ALPHA, math.floor(b10 / 2^18) + 1, math.floor(b10 / 2^18) + 1) .. string.sub(_ALPHA, math.floor((b10 / 2^12) % 64) + 1, math.floor((b10 / 2^12) % 64) + 1) .. string.sub(_ALPHA, math.floor((b10 / 2^6) % 64) + 1, math.floor((b10 / 2^6) % 64) + 1) .. _PADCHAR)
    end
    return table.concat(x)
end