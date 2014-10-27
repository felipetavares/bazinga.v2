local Module = {}

local MainCamera = {}

function love.mousepressed (x, y, button)
	if love.keyboard.isDown (' ') then
		-- Camera movement
		MainCamera:beginMove (x, y)
	else
		if #gui.windows == 0 then
			editor.mouseDown (MainCamera:getIX(x), MainCamera:getIY(y), button, MainLevel)
		end
	end

	gui.mouseDown (x, y, button)
end

function love.mousereleased (x, y, button)
	if #gui.windows == 0 then
		editor.mouseUp(MainCamera:getIX(x),MainCamera:getIY(y), MainLevel)
	end
	gui.mouseUp (x, y, button)
end

function love.keypressed (key, isrepeat)
	if #gui.windows == 0 then
		editor.keyDown (key, isrepeat, MainCamera)
	end
	gui.keyDown(key, isrepeat)
end

function love.keyreleased (key)
	gui.keyUp(key)
end

function love.textinput (unicode)
	gui.input (unicode)
end

-- Local functions

local function begin ()
	MainLevel = level.Level:new()
	MainCamera = camera.Camera:new()
	Module.MainCamera = MainCamera

	editor.setCamera (MainCamera)
	editor.setLevel (MainLevel)

	-- Add one layer
	MainLevel:addLayer (level.Layer:new())
end

local function update ()
	-- Camera movement
	if love.keyboard.isDown (' ') and love.mouse.isDown('l') then
		MainCamera:move(love.mouse.getX(), love.mouse.getY())
	else
		MainCamera:endMove()
	end

	local x,y

	x = love.mouse.getX()
	y = love.mouse.getY()

	if #gui.windows == 0 then
		editor.mouseMove(MainCamera:getIX(x),MainCamera:getIY(y))
	end

	-- Fake events for mousemove
	-- since Löve2d don't provides one
	gui.mouseMove (love.mouse.getX(), love.mouse.getY())

	-- GUI update
	gui.update()
end

local function render ()
	love.graphics.setScissor (0,0,love.window:getWidth(),love.window:getHeight())
	love.graphics.clear()

	MainLevel:render(MainCamera)
	
	editor.render(MainCamera)

	gui.render()
end

Module.begin = begin
Module.update = update
Module.render = render

return Module