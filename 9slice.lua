--9slice rendering base code
--offset from edges
--collapse corners dynamically

local _9slice_patch_cache = {}
local _9slice_patch_cache_size = 30
local function _get_9slice_patch(atlas, w, h, nocache)
	--get some dimensions dimensions
	local aw, ah = atlas:getDimensions()

	local cw = math.floor(math.min(w, aw) * 0.5)
	local ch = math.floor(math.min(h, ah) * 0.5)

	--pull out of cache if we have it
	local cache_id = table.concat({tostring(atlas), w, h}, "_")
	local cached_patch = _9slice_patch_cache[cache_id]
	if not cached_patch then
		--slow path
		--build patch for cache
		cached_patch = {
			love.graphics.newQuad(0, 0, 0, 0, aw, ah),
			{
				--corners
				{0,      0,      0,     0,     cw, ch, 1, 1},
				{w-cw,   0,      aw-cw, 0,     cw, ch, 1, 1},
				{w-cw,   h-ch,   aw-cw, ah-ch, cw, ch, 1, 1},
				{0,      h-ch,   0,     ah-ch, cw, ch, 1, 1},
				--sides
				{cw,     0,      cw,    0,     1,  ch, w-cw * 2, 1},
				{cw,     h-ch,   cw,    ah-ch, 1,  ch, w-cw * 2, 1},
				{0,      ch,     0,     ch,    cw, 1,  1, h-ch * 2},
				{w-cw,   ch,     aw-cw, ch,    cw, 1,  1, h-ch * 2},
				--centre
				{cw,     ch,     cw, ch,       1, 1,   w-cw * 2, h-ch * 2},
			}
		}
		if not nocache then
			--add to cache
			_9slice_patch_cache[cache_id] = cached_patch
			--shred some elements if beyond target cache size
			local cache_count = 0
			local cache_shred = nil
			for k,_ in pairs(_9slice_patch_cache) do
				cache_count = cache_count + 1
				if k ~= cache_id and love.math.random() < 0.5 then
					if not cache_shred then
						cache_shred = {}
					end
					table.insert(cache_shred, k)
				end
			end
			if cache_shred and cache_count > _9slice_patch_cache_size then
				for i = 1, cache_count - _9slice_patch_cache_size do
					local idx = love.math.random(1, #cache_shred)
					local k = cache_shred[idx]
					_9slice_patch_cache[k] = nil
				end
			end
		end
	end
	return cached_patch
end

local function draw_9slice(atlas, x, y, w, h, pad, nocache)
	--sanitise+check inputs
	if not atlas then
		error("missing atlas for 9slice draw")
	end

	x = math.floor(x)
	y = math.floor(y)
	if w < 0 then
		return draw_9slice(atlas, x+w, y, -w, h, pad, nocache)
	elseif h < 0 then
		return draw_9slice(atlas, x, y+h, w, -h, pad, nocache)
	end
	w = math.ceil(w)
	h = math.ceil(h)

	--pad dimensions
	if pad and pad > 0 then
		x = x - pad
		y = y - pad
		w = w + pad * 2
		h = h + pad * 2
	end

	--get the patch
	local _q, patch_pattern = unpack(_get_9slice_patch(atlas, w, h, nocache))
	--render patches
	for i,v in ipairs(patch_pattern) do
		local ox, oy, u, v, uw, uh, sx, sy = unpack(v)
		_q:setViewport(u, v, uw, uh)
		love.graphics.draw(
			atlas, _q,
			x + ox, y + oy,
			0,
			sx, sy
		)
	end
end

return draw_9slice