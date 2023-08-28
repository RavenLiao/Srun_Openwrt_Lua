function get_sha1(value)
    local command = 'echo -n "' .. value .. '" | openssl dgst -sha1'
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()
    -- output from openssl includes some extra text, so remove it
    result = result:gsub('%(stdin%)= ', ''):gsub('\n', ''):gsub('SHA1', '') -- remove newline character
    return result
end
