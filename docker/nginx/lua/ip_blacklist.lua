-- a quick LUA access script for nginx to check IP addresses against an
-- `ip_blacklist` set in Redis, and if a match is found send a HTTP 403.
--
-- allows for a common blacklist to be shared between a bunch of nginx
-- web servers using a remote redis instance. lookups are cached for a
-- configurable period of time.
--
-- block an ip:
--   redis-cli SADD ip_blacklist 10.1.1.1
-- remove an ip:
--   redis-cli SREM ip_blacklist 10.1.1.1
--
-- also requires lua-resty-redis from:
--   https://github.com/agentzh/lua-resty-redis
--
-- your nginx http context should contain something similar to the
-- below: (assumes resty/redis.lua exists in /etc/nginx/lua/)
--
--   lua_package_path "/etc/nginx/lua/?.lua;;";
--   lua_shared_dict ip_blacklist 1m;
--
-- you can then use the below (adjust path where necessary) to check
-- against the blacklist in a http, server, location, if context:
--
-- access_by_lua_file /etc/nginx/lua/ip_blacklist.lua;
--
-- from https://gist.github.com/chrisboulton/6043871
-- modify by Ceelog

local redis_host = ngx.var.REDIS_IP
local redis_port = ngx.var.REDIS_PORT
local redis_password = ngx.var.REDIS_PASSWORD
local redis_database = ngx.var.REDIS_DATABASE

-- connection timeout for redis in ms. don't set this too high!
local redis_connection_timeout = 100

-- cache lookups for this many seconds
local cache_ttl = 60

-- end configuration
local banned_ip_pattern = "BANNED_IP"
local ip = ngx.var.remote_addr
local pattern_ip = banned_ip_pattern .. ":" .. ip
local ip_blacklist = ngx.shared.ip_blacklist
local last_update_time = ip_blacklist:get("last_update_time");

-- only update ip_blacklist from Redis once every cache_ttl seconds:
if last_update_time == nil or last_update_time < (ngx.now() - cache_ttl) then

    local redis = require "resty.redis";
    local red = redis:new();

    red:set_timeout(redis_connection_timeout);

    local ok, err = red:connect(redis_host, redis_port);
    if not ok then
        ngx.log(ngx.DEBUG, "Redis connection error while retrieving ip_blacklist: " .. err);
    else

        local res, err = red:auth(redis_password)
        if not res then
            ngx.log(ngx.DEBUG, "Failed to authenticate: ", err);
        else

            local ok, err = red:select(redis_database);
            if not ok then
                ngx.log(ngx.DEBUG, "Failed to select database: ", err);
            else

                local new_ip_blacklist, err = red:scan("0", "match", banned_ip_pattern .. ":*", "count", "1000")

                if not new_ip_blacklist then
                    ngx.log(ngx.DEBUG, "failed to scan: " .. err);
                else

                    local cursor, new_ip_blacklist, err = unpack(new_ip_blacklist)

                    if err then
                        ngx.log(ngx.DEBUG, "Redis read error while retrieving ip_blacklist: " .. err);
                    else
                        -- replace the locally stored ip_blacklist with the updated values:
                        ip_blacklist:flush_all();
                        for index, banned_ip in ipairs(new_ip_blacklist) do
                            ip_blacklist:set(banned_ip, true);
                            ngx.log(ngx.DEBUG, "Banned IP added: " .. banned_ip);
                        end

                        -- update time
                        ip_blacklist:set("last_update_time", ngx.now());
                    end
                end
            end
        end
    end
end

if ip_blacklist:get(pattern_ip) then
    ngx.log(ngx.DEBUG, "Banned IP detected and refused access: " .. ip);
    return ngx.exit(ngx.HTTP_FORBIDDEN);
end