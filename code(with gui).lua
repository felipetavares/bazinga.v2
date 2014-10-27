local Module = {}

function love.mousepressed (x, y, button)
	if love.keyboard.isDown ("lctrl") then
		-- Camera movement
		MainCamera:beginMove (x, y)
	else
		if button == 'r' then
			-- Add a new object at mouse position
			MainLevel:addObject (level.Object:new(MainCamera:getIX(x), MainCamera:getIY(y)))
		end
	end

	if button == 'r' then
	end

	gui.mouseDown (x, y, button)
end

function love.mousereleased (x, y, button)
	gui.mouseUp (x, y, button)
end

function love.keypressed (key, isrepeat)
	gui.keyDown(key, isrepeat)
end

function love.keyreleased (key)
	gui.keyUp(key)
end

function love.textinput (unicode)
	gui.input (unicode)
end

function onCancel (window)
	window.isVisible = false
end

function onLoad (data)
	if love.filesystem.isFile (data.container.path) then
		print ('loading map from '..data.container.path..'...')
		MainLevel:readFromFile (data.container.path)
	else
		print ('trying to load directory')
	end
end

function onClick (data)
	local path

	if love.filesystem.isDirectory(data.container.path) then
		path = data.container.path..'/'..data.entry.text
	else
		path = data.container.path
	end

	print ('saving map to '..path..'...')
	
	if MainLevel:writeToFile (path) then
		print ('saved!')
	else
		print ('error saving!')
	end
end

function enterDir (data)
	local container = data.container
 	local path

 	if data.lastdir ~= '' then
		path = data.lastdir..'/'..data.dir
	else
		path = data.dir
	end

	if love.filesystem.isDirectory (path) then
		-- Reset container
		container.widgets = {}
		container.fullH = nil
		container.offY = 0

		local filesInDir = love.filesystem.getDirectoryItems(path)

		if data.lastdir ~= '' or data.dir ~= '' then
			local goBack = gui.Button:new('^')
			goBack:begin(enterDir)
			goBack.userData = {container=container, dir=data.lastdir, lastdir=''}
			container:addWidget(goBack)
		end

		local i
		for i=1, #filesInDir do
			local folder = gui.Button:new(filesInDir[i])
			folder:begin(enterDir)
			folder.userData = {container=container, dir=filesInDir[i], lastdir=path}
			container:addWidget(folder)
		end
	else
		if love.filesystem.isFile (path) then
			--print (love.filesystem.read(path))
		end
	end

	container.path = path

	container:invalidate()
end

-- Local functions

local function begin ()
	if not love.filesystem.isDirectory('maps') then
		love.filesystem.createDirectory('maps')

		if not love.filesystem.isFile('maps/map00.json') then
			love.filesystem.write ('map00.json', '')
		end
	end

	MainLevel = level.Level:new()
	MainCamera = camera.Camera:new()

	local window = gui.Window:new(true)
	local maincontainer = gui.VContainer:new()
	local vcontainer = gui.VContainer:new()
	local hcontainer = gui.HContainer:new()
	local scroll = gui.ScrollBar:new()
	local buttoncontainer = gui.HContainer:new()
	local entrycontainer = gui.HContainer:new()

	scroll.fixedW = 12

	scroll:begin('vertical')
	scroll:scrollContainer(vcontainer)
	vcontainer:begin()
	hcontainer:begin()
	maincontainer:begin()
	entrycontainer:begin()
	buttoncontainer:begin()

	entrycontainer.fixedH = 50
	buttoncontainer.fixedH = 50

	hcontainer:addWidget(vcontainer)
	hcontainer:addWidget(scroll)

	hcontainer.path = 'maps'

	enterDir ({
		dir = hcontainer.path,
		lastdir = '',
		container = vcontainer
	})

	local textEntry = gui.TextBox:new()
	textEntry:begin()

	entrycontainer:addWidget(gui.Widget:new('File name:'))
	entrycontainer:addWidget(textEntry)

	local button = gui.Button:new('save')
	button:begin(onClick)
	button.userData = {container=vcontainer,entry=textEntry}

	local load = gui.Button:new('load')
	load:begin(onLoad)
	load.userData = {container=vcontainer,entry=textEntry}

	local cancel = gui.Button:new('cancel')
	cancel:begin(onCancel)
	cancel.fixedH = 50
	cancel.userData = window

	buttoncontainer:addWidget(cancel)
	buttoncontainer:addWidget(load)
	buttoncontainer:addWidget(button)

	maincontainer:addWidget(hcontainer)
	maincontainer:addWidget(entrycontainer)
	maincontainer:addWidget(buttoncontainer)

	window:setRootContainer(maincontainer)

	gui.addWindow (window)

	MainLevel:addLayer (level.Layer:new())
end

local function update ()
	-- Camera movement
	if love.keyboard.isDown ('lctrl') and love.mouse.isDown('l') then
		MainCamera:move(love.mouse.getX(), love.mouse.getY())
	else
		MainCamera:endMove()
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
	gui.render()
end

Module.begin = begin
Module.update = update
Module.render = render

return Module