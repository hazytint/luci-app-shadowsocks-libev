--[[
    hazytint@gmail.com
]]--

local running = (luci.sys.call("pidof ss-local > /dev/null") == 0) or
                (luci.sys.call("pidof ss-redir > /dev/null") == 0) or
                (luci.sys.call("pidof ss-tunnel > /dev/null") == 0)
local description = ""
if running then
    description = "ShadowSocks is running"
else
    description = "ShadowSocks is not running"
end

m = Map("shadowsocks", translate("ShadowSocks"), translate(description))

-- Server Setting
s = m:section(TypedSection, "shadowsocks", translate("Server Setting"))
s.anonymous = true

o = s:option(Value, "remote_server", translate("Server Address"))
o.datatype = "host"

o = s:option(Value, "remote_port", translate("Server Port"))
o.datatype = "port"

o = s:option(Value, "password", translate("Password"))
o.password = true

e = {
    "table",
    "rc4",
    "rc4-md5",
    "aes-128-cfb",
    "aes-192-cfb",
    "aes-256-cfb",
    "bf-cfb",
    "camellia-128-cfb",
    "camellia-192-cfb",
    "camellia-256-cfb",
    "cast5-cfb",
    "des-cfb",
    "idea-cfb",
    "rc2-cfb",
    "seed-cfb",
    "salsa20",
    "chacha20",
}

o = s:option(ListValue, "cipher", translate("Encrypt Method"))
for i,v in ipairs(e) do
    o:value(v)
end

-- Sock5 Proxy
s = m:section(TypedSection, "shadowsocks", translate("SOCKS5 Proxy"))
s.anonymous = true

o = s:option(Flag,"enabled", translate("Enable"))
o.default = 1
o.rmempty = false

o = s:option(Value, "local_port", translate("Local Port"))
o.datatype = "port"

-- Redir
s = m:section(TypedSection, "shadowsocks", translate("Transparent Proxy"))
s.anonymous = true

o = s:option(Flag, "redir_enabled", translate("Enable"))
o.default = 1
o.rmempty = false

o = s:option(Value, "redir_port", translate("Transparent Proxy Local Port"))
o.datatype = "port"

o = s:option(Value, "blacklist", translate("Bypass Lan IP"))
o.template = "cbi/tvalue"
o.rows = 6
o.size = 20

function o.cfgvalue(self, section)
    return nixio.fs.readfile("/etc/ipset/blacklist") or ""
end

function o.write(self, section, value)
    if value then
        value = value:gsub("\r\n?", "\n")
        nixio.fs.writefile("/tmp/ipset_blacklist", value)
        if (luci.sys.call("cmp -s /tmp/ipset_blacklist /etc/ipset/blacklist") == 1) then
            nixio.fs.writefile("/etc/ipset/blacklist", value)
        end
        nixio.fs.remove("/tmp/ipset_blacklist")
    end
end

o = s:option(Value, "whitelist", translate("Bypass IP Whitelist"))
o.template = "cbi/tvalue"
o.rows = 6
o.size = 20

function o.cfgvalue(self, section)
    return nixio.fs.readfile("/etc/ipset/whitelist") or ""
end

function o.write(self, section, value)
    if value then
        value = value:gsub("\r\n?", "\n")
        nixio.fs.writefile("/tmp/ipset_whitelist", value)
        if (luci.sys.call("cmp -s /tmp/ipset_whitelist /etc/ipset/whitelist") == 1) then
            nixio.fs.writefile("/etc/ipset/whitelist", value)
        end
        nixio.fs.remove("/tmp/ipset_whitelist")
    end
end

-- UDP Forward
s = m:section(TypedSection, "shadowsocks", translate("UDP Forward"))
s.anonymous = true

o = s:option(Flag, "tunnel_enabled", translate("Enable"))
o.default = 1
o.rmempty = false

o = s:option(Value, "tunnel_port", translate("UDP Local Port"))
o.datatype = "port"
o.default = 5300
o.placeholder = 5300

o = s:option(Value, "tunnel_dest", translate("Forwarding Tunnel"))
o.default = "8.8.4.4:53"
o.placeholder = "8.8.4.4:53"

return m