local redis = require "resty.redis"

ngx.log(ngx.NOTICE, "--- log.lua: Body filter started ---") -- Log start

-- Only process if we have a response to cache
if not ngx.ctx.save_cache then
  ngx.log(ngx.NOTICE, "log.lua: No ngx.ctx.save_cache found, exiting.") -- Log exit condition
  return -- 如果 route.lua 没有设置 save_cache (例如缓存已命中)，这里会退出
end
ngx.log(ngx.NOTICE, "log.lua: Found cache key: ", ngx.ctx.save_cache) -- Log cache key

-- Get the response body
local resp_body = ngx.arg[1]
local eof = ngx.arg[2] -- Check if this is the last chunk

ngx.log(ngx.NOTICE, "log.lua: Received response chunk. EOF: ", tostring(eof)) -- Log chunk info

-- We should ideally buffer the chunks until we get the last one (eof=true)
-- For simplicity in debugging now, let's try caching even partial bodies,
-- but log if the body is empty or nil.
if not resp_body or resp_body == "" then
  ngx.log(ngx.NOTICE, "log.lua: Response body chunk is empty or nil.") -- Log empty body
  -- Depending on your needs, you might want to 'return' here if eof is false,
  -- or buffer chunks. For now, we proceed to see Redis connection.
end

-- Only attempt Redis operations on the last chunk to avoid partial writes
if not eof then
    ngx.log(ngx.NOTICE, "log.lua: Not the last chunk (EOF is false), skipping Redis write for now.")
    return -- Important: Wait for the final chunk
end

ngx.log(ngx.NOTICE, "log.lua: Last chunk received. Attempting Redis connection.") -- Log Redis attempt

-- Connect to Redis
local r = redis:new()
r:set_timeout(50)
local ok, err = r:connect("redis", 6379)
if not ok then
  ngx.log(ngx.ERR, "log.lua: Failed to connect to Redis: ", err) -- Log Redis connection error
  return
end
ngx.log(ngx.NOTICE, "log.lua: Connected to Redis successfully.") -- Log Redis success

-- Cache the response with the key saved in access phase
ngx.log(ngx.NOTICE, "log.lua: Attempting to SET key '", ngx.ctx.save_cache, "' with body length: ", #resp_body) -- Log SET attempt
local ok, err = r:set(ngx.ctx.save_cache, resp_body)
if not ok then
  ngx.log(ngx.ERR, "log.lua: Failed to cache response (SET failed): ", err) -- Log SET error
  -- Close connection on error before returning
  r:set_keepalive(0, 100) -- Close connection
  return
end
ngx.log(ngx.NOTICE, "log.lua: Successfully SET key '", ngx.ctx.save_cache, "'") -- Log SET success

-- Set cache expiry (optional, adjust TTL as needed)
ngx.log(ngx.NOTICE, "log.lua: Setting EXPIRE for key '", ngx.ctx.save_cache, "' to 60 seconds.") -- Log EXPIRE attempt
local ok, err = r:expire(ngx.ctx.save_cache, 60)  -- 60 seconds TTL
if not ok then
    ngx.log(ngx.ERR, "log.lua: Failed to set EXPIRE: ", err) -- Log EXPIRE error
    -- Continue to keepalive even if expire fails
end

-- Put connection back to pool
ngx.log(ngx.NOTICE, "log.lua: Setting keepalive for Redis connection.") -- Log keepalive attempt
local ok, err = r:set_keepalive(10000, 100)
if not ok then
  ngx.log(ngx.ERR, "log.lua: Failed to set keepalive: ", err) -- Log keepalive error
end

ngx.log(ngx.NOTICE, "--- log.lua: Body filter finished ---") -- Log end