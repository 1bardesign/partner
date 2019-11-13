--[[
	basic retained ui library for love2d

	see license.txt for usage requirements
]]

local ui = {}

--basic draw rect function
--generally override with something more flashy
function draw_rect_base(x, y, w, h)
	love.graphics.rectangle("fill", x, y, w, h)
end

--ui base node element
local ui_base = {}
ui.base = ui_base

ui_base._mt = {__index = ui_base}
function ui_base:new()
	return setmetatable({
		children = {},
		x = 0, y = 0,
		w = 0, h = 0,
		--todo: minw, minh

		--(defaults)
		position = "relative", --"relative" | "absolute"
		size = "fixed",        --"fixed" | "adaptive"
		col = {
			fg =       {1, 1, 1, 1},
			fg_hover = {1, 1, 1, 1},
			bg =       {0.15, 0.15, 0.15, 1},
			bg_hover = {0.15, 0.15, 0.15, 1},
		},
		hidden = false,
		visible = {
			fg = true,
			bg = true,
			children = true,
		},
		padding = {
			h = 10,
			v = 10,
			--fractional
			before = 1.0,
			between = 1.0,
			after = 1.0,
		},
		anchor = {
			h = "left",
			v = "top",
		},
		layout_direction = "v",
		--ignores inputs if yes
		noclip = false,
		--flags to track
		is_hovered = false,
		is_dirty = true,
		--override-friendly rect rendering function for this element
		rect_fn = draw_rect_base,
	}, ui_base._mt)
end

--mark a node's tree dirty
function ui_base:dirty()
	if not self.is_dirty then
		self.is_dirty = true
		--todo: figure out which way this should actually propagate :)
		--		difficulty: depends on reason for dirty
		--		(size change = parent needs to know, moved = kids do)
		if self.parent then
			self.parent:dirty()
		end
		for i,v in ipairs(self.children) do
			v:dirty()
		end
	end
	return self
end

--layout an entire tree
function ui_base:layout()
	--base size is just padding around zero
	local between = self.padding.between
	local before = self.padding.before
	local after = self.padding.after
	local ba_total = before + after

	local adaptive_size = self.size == "adaptive"

	if adaptive_size then
		self.w = self.padding.h * ba_total
		self.h = self.padding.v * ba_total
	end

	--start of positioning
	local x = self.layout_direction == "v" and self.padding.h * before or 0
	local y = self.layout_direction == "h" and self.padding.v * before or 0

	local done_before = false

	for i, v in ipairs(self.children) do
		if v.hidden then
			--(skipped)
		elseif v.position == "absolute" then
			--just layout child + its children (doesn't affect out layout)
			v:layout()
		else
			local pad_amount = not done_before and before or between
			done_before = true
			if self.layout_direction == "v" then
				y = y + self.padding.v * pad_amount
			elseif self.layout_direction == "h" then
				x = x + self.padding.h * pad_amount
			end

			--position child
			v.x = x
			v.y = y
			--layout child + its children
			v:layout()
			--step around it in the right direction
			if self.layout_direction == "v" then
				if adaptive_size then
					self.w = math.max(self.w, self.padding.h * ba_total + v.w)
				end
				y = y + v.h
			elseif self.layout_direction == "h" then
				if adaptive_size then
					self.h = math.max(self.h, self.padding.v * ba_total + v.h)
				end
				x = x + v.w
			end
		end
	end

	if adaptive_size then
		if self.layout_direction == "v" then
			self.h = y + self.padding.v * after
		elseif self.layout_direction == "h" then
			self.w = x + self.padding.h * after
		end
	end

	return self
end

--child management
function ui_base:add_child(c)
	c:remove()
	table.insert(self.children, c)
	c.parent = self
	return self:dirty()
end

function ui_base:add_children(c)
	for i,v in ipairs(c) do
		self:add_child(v)
	end
	return self:dirty()
end

function ui_base:remove_child(c)
	for i, v in ipairs(self.children) do
		if v == c then
			table.remove(self.children, i)
			self:dirty()
			break
		end
	end
	return self
end

function ui_base:clear_children()
	while #self.children > 0 do
		self.children[1]:remove()
	end
	return self
end

function ui_base:remove()
	if self.parent then
		self.parent:remove_child(self)
		self.parent = nil
		self:dirty()
	end
	return self
end

--chainable modifiers
function ui_base:set_width(w)
	self.w = w
	return self:dirty()
end

function ui_base:set_height(h)
	self.h = h
	return self:dirty()
end

function ui_base:set_size(w, h)
	self.w = w
	self.h = h
	return self:dirty()
end

function ui_base:set_padding(name, p)
	if self.padding[name] == nil then
		error("attempt to set bogus padding "..name)
	end
	self.padding[name] = p
	return self:dirty()
end

function ui_base:set_colour(name, r, g, b, a)
	local c = self.col[name]
	if c == nil then
		error("attempt to set bogus colour "..name)
	end
	c[1] = r
	c[2] = g
	c[3] = b
	c[4] = a
	return self
end

function ui_base:set_visible(name, v)
	if self.visible[name] == nil then
		error("attempt to set bogus visibility "..name)
	end
	self.visible[name] = v
	self:dirty()
	return self
end

function ui_base:set_anchor(h, v)
	if h then
		self.anchor.h = h
		self:dirty()
	end
	if v then
		self.anchor.v = v
		self:dirty()
	end
	return self
end

--todo: collapse/expand children, neighbours

function ui_base:hide(hidden)
	if hidden == nil then
		hidden = true
	end
	self.hidden = hidden
	self:dirty()
end

function ui_base:hide_children(hidden, set_neighbours)
	for i,v in ipairs(self.children) do
		v:hide(hidden)
	end

	if set_neighbours ~= nil and self.parent then
		for i,v in ipairs(self.parent.children) do
			if v ~= self then
				v:hide_children(set_neighbours, nil)
			end
		end
	end
	self:dirty()
	return self
end

function ui_base:hide_neighbours(hidden)
	if set_neighbours ~= nil and self.parent then
		for i,v in ipairs(self.parent.children) do
			if v ~= self then
				v:hide(hidden)
			end
		end
	end
	return self
end

function ui_base:pos()
	--todo: cache this?
	local x, y = self.x, self.y
	local ah, av = self.anchor.h, self.anchor.v

	if ah == "left" then
		--no change
	elseif ah == "center" or ah == "centre" then
		x = x - self.w * 0.5
	elseif ah == "right" then
		x = x - self.w
	end

	if av == "top" then
		--no change
	elseif av == "center" or av == "centre" then
		y = y - self.h * 0.5
	elseif av == "bottom" then
		y = y - self.h
	end

	return math.floor(x), math.floor(y)
end

function ui_base:pos_absolute()
	local px, py = 0, 0
	if
		self.position ~= "absolute"
		and self.parent
	then
		px, py = self.parent:pos_absolute()
	end
	local sx, sy = self:pos()
	return px + sx, py + sy
end

--drawing
function ui_base:draw_background()
	self.rect_fn(0, 0, self.w, self.h)
end

function ui_base:draw_children()
	for _,v in ipairs(self.children) do
		v:draw()
	end
end

function ui_base:base_draw(inner)
	--bail on hidden
	if self.hidden then
		return
	end

	--cache old colour
	local o_r, o_g, o_b, o_a = love.graphics.getColor()
	--and old state
	love.graphics.push()

	--set up position
	if self.position == "absolute" then
		love.graphics.origin()
	end
	love.graphics.translate(self:pos())
	--draw bg
	if self.visible.bg then
		local r, g, b, a = unpack(self.is_hovered and self.col.bg_hover or self.col.bg)
		love.graphics.setColor(o_r * r, o_g * g, o_b * b, o_a * a)
		self:draw_background()
	end
	--draw fg
	if self.visible.fg then
		local r, g, b, a = unpack(self.is_hovered and self.col.fg_hover or self.col.fg)
		love.graphics.setColor(o_r * r, o_g * g, o_b * b, o_a * a)
		if inner then
			inner(self)
		end
	end
	--draw children
	--todo: figure out what's appropriate here in terms of reverting the colour?..
	if self.visible.children then
		self:draw_children()
	end
	--restore state
	love.graphics.pop()
	love.graphics.setColor(o_r, o_g, o_b, o_a)
end

function ui_base:draw(inner)
	self:base_draw(inner)
end

--inputs
function ui_base:pointer(event, x, y)
	self.is_hovered = false
	if self.hidden then
		return false
	end

	local px, py = self:pos_absolute()
	local dx = x - px
	local dy = y - py

	--todo: consider if we want to support overlapping children?
	local clipped = false
	for i,v in ipairs(self.children) do
		if v:pointer(event, x, y) then
			clipped = true
		end
	end
	if clipped then
		return true
	end

	if not self.noclip then
		self.is_hovered =
			dx >= 0 and dx < self.w
			and dy >= 0 and dy < self.h
	end

	if self.is_hovered then
		if event == "click" and self.onclick then
			self:onclick(dx, dy)
		end
		if event == "drag" and self.ondrag then
			self:ondrag(dx, dy)
		end
		if event == "release" and self.onrelease then
			self:onrelease(dx, dy)
		end
	end

	return self.is_hovered
end

function ui_base:key(event, k)
	if self.hidden then
		return false
	end

	local clipped = false
	for i,v in ipairs(self.children) do
		if v:key(event, k) then
			clipped = true
		end
	end
	if clipped then
		return true
	end

	if self.onkey then
		return self:onkey(event, k)
	end

	return false
end

--nop function to dummy out functions with
function ui_base:nop()
	return self
end

--(internal)
local _leaf_nops = {
	"add_child",
	"remove_child",
	"layout",
	"draw_children",
}
--set up a leaf type (meant for constructors not for individuals)
function ui_base:_set_leaf_type()
	for i,v in ipairs(_leaf_nops) do
		self[v] = ui_base.nop
	end
	self.is_leaf = true
	return self
end

--dummy container for linking everything together
local ui_container = ui_base:new()
ui.container = ui_container
ui_container._mt = {__index = ui_container}

function ui_container:new()
	self = setmetatable(ui_base:new(), ui_container._mt)
	self.visible.bg = false
	self.visible.fg = false
	self.noclip = true
	return self
end

--tray for holding buttons etc
local ui_tray = ui_base:new()
ui.tray = ui_tray
ui_tray._mt = {__index = ui_tray}

function ui_tray:new(x, y, w, h)
	self = setmetatable(ui_base:new(), ui_tray._mt)
	self.x, self.y = x, y
	self.w, self.h = w, h
	self.position = "absolute"
	self.size = "adaptive"
	return self
end

--inline row
local ui_row = ui_base:new()
ui.row = ui_row
ui_row._mt = {__index = ui_row}

function ui_row:new(v)
	self = setmetatable(ui_base:new(), ui_row._mt)
	self.size = "adaptive"
	self.layout_direction = "h"
	self.padding.v = 0
	self.padding.before = 0
	self.padding.after = 0
	self.visible.bg = v
	self.noclip = true
	return self
end

--inline col
local ui_col = ui_base:new()
ui.col = ui_col
ui_col._mt = {__index = ui_col}

function ui_col:new(v)
	self = setmetatable(ui_base:new(), ui_row._mt)
	self.size = "adaptive"
	self.layout_direction = "v"
	self.padding.h = 0
	self.padding.before = 0
	self.padding.after = 0
	self.visible.bg = v
	self.noclip = true
	return self
end

--button
local ui_button = ui_base:new()
ui.button = ui_button
ui_button._mt = {__index = ui_button}

function ui_button:new(asset_or_text, w, h, callback, key)
	self = setmetatable(ui_base:new(), ui_button._mt)

	if asset_or_text then
		if type(asset_or_text) == "string" then
			self.ui_button_text = love.graphics.newText(love.graphics.getFont(), nil)
			self.ui_button_text:setf(asset_or_text, w, "center")
		else
			self.ui_button_asset = asset_or_text
			--take asset size if bigger
			self.aw, self.ah = self.ui_button_asset:getDimensions()
			w = math.max(self.aw, w or 0)
			h = math.max(self.ah, h or 0)
		end
	end
	self.w, self.h = w, h

	self.col.bg       = {0.1, 0.1, 0.1, 1}
	self.col.bg_hover = {0.2, 0.2, 0.2, 1}

	self.onclick = callback
	if key ~= nil then
		function self:onkey(event, k)
			if event == "press" and k == key then
				self:onclick(self.w * 0.5, self.h * 0.5)
				return true
			end
		end
	end

	return self
end

--draw button image centred
function ui_button:_draw()
	if self.ui_button_text then
		love.graphics.draw(self.ui_button_text, 0, (self.h - self.ui_button_text:getHeight()) * 0.5)
	elseif self.ui_button_asset then
		love.graphics.draw(
			self.ui_button_asset,
			math.floor(self.w * 0.5),
			math.floor(self.h * 0.5),
			0,
			1, 1,
			math.floor(self.aw * 0.5),
			math.floor(self.ah * 0.5)
		)
	end
end

function ui_button:draw()
	self:base_draw(self._draw)
end

--text element
local ui_text = ui_base:new():_set_leaf_type()
ui.text = ui_text
ui_text._mt = {__index = ui_text}
function ui_text:new(font, t, w, align)
	self = setmetatable(ui_base:new(), ui_text._mt)

	--default
	font = font or love.graphics.getFont()

	self.set_w = w
	self.align = align or "center"
	self.ui_text = love.graphics.newText(font, nil)
	self.visible.bg = false

	return self:set_text(t, w, align)
end

function ui_text:set_text(t, w, align)
	self.set_w = w or self.set_w
	self.align = align or self.align

	self.ui_text:setf(t, self.set_w, self.align)

	local ba_total = (self.padding.before + self.padding.after)
	self.w = self.set_w + self.padding.h * ba_total
	self.h = self.ui_text:getHeight() + self.padding.v * ba_total

	return self
end

function ui_text:_draw()
	love.graphics.draw(
		self.ui_text,
		self.padding.h * self.padding.before,
		self.padding.v * self.padding.before
	)
end

function ui_text:draw()
	return self:base_draw(self._draw)
end

--collapse
local ui_collapse = ui_base:new()
function ui.collapse_panel(panel, button, children)
	--hook up the toggle button
	panel._b = button
	panel:add_child(panel._b)
	local prev_onclick = button.onclick
	function button:onclick(x, y)
		self.parent:toggle()
		if prev_onclick then
			prev_onclick(self, x, y)
		end
	end

	--hook up the various collapse panel callbacks
	--(todo: consider if we need to hoist these)
	function panel:collapsed()
		for i,v in ipairs(self.children) do
			if v ~= self._b and v.hidden then
				return true
			end
		end
		return false
	end

	function panel:set_collapsed(set)
		for i,v in ipairs(self.children) do
			if v ~= self._b then
				v:hide(set)
			end
		end
		return self
	end

	function panel:collapse()
		return self:set_collapsed(true)
	end

	function panel:expand()
		return self:set_collapsed(false)
	end

	function panel:toggle()
		return self:set_collapsed(not self:collapsed())
	end

	panel:add_children(children)

	panel:collapse()

	return panel
end

return ui