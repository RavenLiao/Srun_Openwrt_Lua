#!/usr/bin/env lua

-- 基本参数
local username = ""
local password = ""
local base_url = "http://10.248.98.2"

-- 其他参数，一般不需要调整
local n = '200'
local ac_id = '1'
local enc = "srun_bx1"
local Type = '1'
local get_challenge_api = base_url .. "/cgi-bin/get_challenge?callback=a&username=" .. username
local srun_portal_api = base_url .. "/cgi-bin/srun_portal"
local UA ="User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36 Edg/116.0.1938.62"

-- 执行外部命令的封装
function execute(cmd)
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()
    return result
end

-- curl 开始 ··············································································
function curl_get(url)
    return execute(string.format('curl -s -X GET -H "%s" "%s"', UA, url))
end

function curl_get_params(url, params)
    local kv_pairs = {}
    for k, v in pairs(params) do
        table.insert(kv_pairs, string.format('--data-urlencode "%s=%s"', k, v))
    end
    local p = table.concat(kv_pairs, " ")
    local command = string.format('curl -G -s -H "%s" %s "%s"', UA, p, url)
    return execute(command)
end

-- curl 结束 ··············································································


-- hash 开始 ··············································································
function get_sha1(value)
    return execute('echo -n "' .. value .. '" | openssl dgst -sha1'):gsub('%(stdin%)= ', ''):gsub('\n', ''):gsub('SHA1','')
end

function get_hmac_md5(password, token)
    return execute('echo -n "' .. password .. '" | openssl dgst -md5 -hmac "' .. token .. '"'):gsub('%(stdin%)= ', ''):gsub('\n', ''):gsub('MD5', '')
end

-- hash 结束 ··············································································


-- 定制的base64，与原版的最大差别应该是换掉了字符表_ALPHA
function base64_encode(s)
    local _PADCHAR = "="
    local _ALPHA = "LVoJPiCN2R8G90yg+hmFHuacZ1OWMnrsSTXkYpUq/3dlbfKwv6xztjI7DeBE45QA"
    local i = 0
    local b10 = 0
    local x = {}
    local imax = #s - #s % 3
    if #s == 0 then
        return s
    end
    for i = 1, imax, 3 do
        b10 = (string.byte(s, i) * 2 ^ 16) + (string.byte(s, i + 1) * 2 ^ 8) + string.byte(s, i + 2)
        table.insert(x, string.sub(_ALPHA, math.floor(b10 / 2 ^ 18) + 1, math.floor(b10 / 2 ^ 18) + 1))
        table.insert(x, string.sub(_ALPHA, math.floor((b10 / 2 ^ 12) % 64) + 1, math.floor((b10 / 2 ^ 12) % 64) + 1))
        table.insert(x, string.sub(_ALPHA, math.floor((b10 / 2 ^ 6) % 64) + 1, math.floor((b10 / 2 ^ 6) % 64) + 1))
        table.insert(x, string.sub(_ALPHA, math.floor(b10 % 64) + 1, math.floor(b10 % 64) + 1))
    end
    i = imax
    if #s - imax == 1 then
        b10 = string.byte(s, i + 1) * 2 ^ 16
        table.insert(x,
            string.sub(_ALPHA, math.floor(b10 / 2 ^ 18) + 1, math.floor(b10 / 2 ^ 18) + 1) ..
            string.sub(_ALPHA, math.floor((b10 / 2 ^ 12) % 64) + 1, math.floor((b10 / 2 ^ 12) % 64) + 1) ..
            _PADCHAR .. _PADCHAR)
    elseif #s - imax == 2 then
        b10 = (string.byte(s, i + 1) * 2 ^ 16) + (string.byte(s, i + 2) * 2 ^ 8)
        table.insert(x,
            string.sub(_ALPHA, math.floor(b10 / 2 ^ 18) + 1, math.floor(b10 / 2 ^ 18) + 1) ..
            string.sub(_ALPHA, math.floor((b10 / 2 ^ 12) % 64) + 1, math.floor((b10 / 2 ^ 12) % 64) + 1) ..
            string.sub(_ALPHA, math.floor((b10 / 2 ^ 6) % 64) + 1, math.floor((b10 / 2 ^ 6) % 64) + 1) .. _PADCHAR)
    end
    return table.concat(x)
end

-- xencode 开始 ············································································································

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
        table.insert(pwd, ordat(msg, i + 1) | ordat(msg, i + 2) << 8 | ordat(msg, i + 3) << 16 | ordat(msg, i + 4) << 24)
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
        return table.concat(msg):sub(1, ll + 1)
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
            y = pwd[py_idx(p + 1)]
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
    return lencode(pwd, false)
end

-- xencode 结束 ············································································································

function get_info(ip, token)
    local info_temp = string.format(
        '{"username":"%s","password":"%s","ip":"%s","acid":"%s","enc_ver":"%s"}',
        username, password, ip, ac_id, enc
    )
    local i = info_temp:gsub(" ", "")
    return "{SRBX1}" .. base64_encode(get_xencode(i, token))
end

function get_info(ip, token)
    local info_temp = string.format(
        '{"username":"%s","password":"%s","ip":"%s","acid":"%s","enc_ver":"%s"}',
        username, password, ip, ac_id, enc
    ):gsub(" ", "")
    return "{SRBX1}" .. base64_encode(get_xencode(info_temp, token))
end

function get_chksum(token, hmd5, ip, info)
    local chkstr = token ..
        username .. token .. hmd5 .. token .. ac_id .. token .. ip .. token .. n .. token .. Type .. token .. info
    return get_sha1(chkstr)
end

function login()
    print("开始登录流程")
    local challengResult = curl_get(get_challenge_api)

    local client_ip = challengResult:match('"client_ip":"(.-)"')
    if client_ip == nil then
        print("IP获取失败")
        return
    else
        print("登录IP：" .. client_ip)
    end
    local token = challengResult:match('"challenge":"(.-)"')
    if token == nil then
        print("token获取失败!")
        return
    else
        print("本次token：" .. token)
    end

    local info = get_info(client_ip, token)
    local hmd5 = get_hmac_md5(password, token)
    local chksum = get_chksum(token, hmd5, client_ip, info)
    local srun_portal_params = {
        callback = 'a',
        action = 'login',
        username = username,
        password = '{MD5}' .. hmd5,
        ac_id = ac_id,
        ip = client_ip,
        chksum = chksum,
        info = info,
        n = n,
        type = Type,
    }
    local result = curl_get_params(srun_portal_api, srun_portal_params)
    local suc_msg = result:match('"suc_msg":"(.-)"')
    if suc_msg then
        print("登录结果：" .. suc_msg)
    else
        print("登录异常，返回内容：" .. result)
    end
    print("登录结束")
end

function test_network()
    local url = "http://connect.rom.miui.com/generate_204"
    return execute(string.format('wget --timeout=3 -qO- "%s" --user-agent="%s"', url, UA)) == ""
end

function main()
    local result = test_network()
    if result then
        print("网络已连接")
    else
        print("网络断开")
        login()
    end
end

main()
