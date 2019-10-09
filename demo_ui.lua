local ui = require("partner")

return function(w, h)
	--allocate the container
	local container = ui.container:new()

	local font_heading = love.graphics.newFont(24)
	local font_body = love.graphics.newFont(14)

	local function example_callback(b, x, y)
		-- body
	end

	local function example_button(t)
		return ui.button:new(t, 32, 32, example_callback)
	end

	container:add_children({
		--welcome tray
		ui.tray:new(w * 0.5, 10, 400, 84):add_children({
			ui.text:new(font_heading, "Partner, a UI Library for Love", 400, "center"),
			ui.text:new(font_body, "\"Bringing U and I Together\"", 400, "center"),
			ui.text:new(font_body, table.concat({
				"This is an example app for my little ui library, partner.",
				"Partner handles the boring bits of ui like layout, passing input around, "..
				"and retaining state, so that you don't have to - while providing easy "..
				"room for extension with new components or rendering capabilities.",
				"Please let me know if you use the library! Contribution on github is also welcome.",
				"Enjoy!",
			}, "\n\n"), 400, "left"),
			ui.text:new(font_body, "~Max", 400, "right"),
		}):set_anchor("center", "top"),

		--example of a grid with row+col
		ui.tray:new(w - 10, h - 10, 84, 84):add_children({
			ui.col:new():add_children({
				ui.row:new():add_children({
					example_button("1"),
					example_button("2"),
					example_button("3"),
				}),
				ui.row:new():add_children({
					example_button("4"),
					example_button("5"),
					ui.col:new():add_children({
						example_button("6a"),
						example_button("6b"),
					}),
				}),
				ui.row:new():add_children({
					example_button("7"),
					example_button("8"),
					example_button("9"),
				}),
				ui.text:new(font_body, "(look, grids!)", 32 * 3, "left"),
			})
		}):set_anchor("right", "bottom"),
		ui.tray:new(10, h - 10, 84, 84):add_children({
			ui.col:new():add_children({
				ui.button:new("github", 200, 32, function()
					love.system.openURL("https://github.com/1bardesign/partner")
				end),
				ui.button:new("quit", 200, 32, function()
					love.event.quit()
				end),
			})
		}):set_anchor("left", "bottom"),
	})


	function container:update(dt)
		container:layout()
		--if we needed to do any updates, this is where we'd do them
	end

	return container
end