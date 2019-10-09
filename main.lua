--[[
	demo application for our ui
]]

--shared ui reference for all these callbacks
--will be set up by love.load in a bit
local ui

function love.resize(w, h)
	ui:resize(w, h)
end

--keyboard handling
function love.keypressed(key, scan)
	--(non-ui related for demo)
	--restart
	if key == "r" and love.keyboard.isDown("lctrl") then
		love.event.quit("restart")
	end
	--quick-exit
	if key == "q" then
		love.event.quit()
	end

	--pass key to ui
	ui:key("pressed", key)
end

--mouse handling
--(single button for now)
local is_clicked = false
function love.mousemoved( x, y, dx, dy, istouch )
	ui:pointer(is_clicked and "drag" or "move", x, y)
end

function love.mousepressed( x, y, button, istouch, presses )
	if button == 1 then
		ui:pointer("click", x, y)
		is_clicked = true
	end
end

function love.mousereleased( x, y, button, istouch, presses )
	if button == 1 then
		ui:pointer("release", x, y)
		is_clicked = false
	end
end

--todo: move most of the above into ui:add_hook() or something?

--core love handlers
function love.load()
	love.window.setTitle("Partner Demo")
	ui = require("demo_ui")(love.graphics.getDimensions())
end

function love.update(dt)
	ui:update(dt)
end

function love.draw()
	ui:draw()
end
