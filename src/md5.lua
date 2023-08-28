function hmac_md5(password, token)
    local command = 'echo -n "' .. password .. '" | openssl dgst -md5 -hmac "' .. token .. '"'
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()
    -- output from openssl includes some extra text, so remove it
    result = result:gsub('%(stdin%)= ', ''):gsub('\n', ''):gsub('MD5', '') -- remove newline character
    return result
end
