local redis = require "resty.redis"
local cjson = require "cjson"
local function cache_key()
    return ngx.var.request_method .. ":" .. ngx.var.uri
end
local r = redis:new(); r:set_timeout(50); r:connect("redis",6379) -- 连接 Redis

-- 1) cache check -- 检查缓存
local cached = r:get(cache_key())
if cached and cached ~= ngx.null then
  ngx.log(ngx.NOTICE, "route.lua: Cache HIT for key: ", cache_key()) -- 添加命中日志
  ngx.say(cached); return ngx.exit(ngx.HTTP_OK) -- 缓存命中，直接返回
end
ngx.log(ngx.NOTICE, "route.lua: Cache MISS for key: ", cache_key()) -- 添加未命中日志

-- 2) pick lightest backend (svc1/2/3 -> weight stored in redis:weights json)
-- local weights = cjson.decode(r:get("weights") or "{}") -- Original line with error potential
local weights_json = r:get("weights") -- Get the value first
if weights_json == ngx.null then -- Explicitly check for ngx.null
    weights_json = "{}" -- Default to empty JSON string if key doesn't exist
end
local weights = cjson.decode(weights_json) -- Now decode the guaranteed string
local best, min = "svc1:5000", 1e9
for host,w in pairs(weights) do if w<min then min=w; best=host end end
ngx.var.upstream = "http://" .. best       -- used by Kong proxy_pass
ngx.log(ngx.NOTICE, "route.lua: Selected upstream: ", ngx.var.upstream) -- 添加上游选择日志

-- save key for log phase to write response (handled by Kong proxy-cache like flow)
ngx.ctx.save_cache = cache_key() -- 关键：在缓存未命中时，设置 ctx 变量供 log.lua 使用
ngx.log(ngx.NOTICE, "route.lua: Set ngx.ctx.save_cache = ", ngx.ctx.save_cache) -- 添加 ctx 设置日志
