local Module = {}
local objectEditor = nil
local objectsList = {}
local copiedObject = nil
local beginBoxSelection = nil

-- Selected objects
local selection = {}
local selectionCopy = {}

local ObjectEditor = {
}

local Grid = {
	x = 0,
	y = 0,
	w = 64,
	h = 64,
	active = false
}

local MainLevel = nil
local MainCamera = nil

--
function ObjectEditor:new (level, layer, object)
	local o = {
		level = level,
		layer = layer,
		object = object,
		grabPosition = {
			x = 0,
			y = 0
		},
		grabbing = false
	}

	setmetatable (o, {__index=self})

	return o
end

function ObjectEditor:render (camera)
	if self == objectEditor then
		love.graphics.setColor (0, 255, 0);
	else
		love.graphics.setColor (255, 128, 0);
	end

	love.graphics.rectangle ('line', camera:getX(self.object.properties.x), camera:getY(self.object.properties.y),
									  camera:getW(self.object.properties.w), camera:getH(self.object.properties.h))
end

function ObjectEditor:isInside (x,y,w,h, px, py)
	if px >= x and px <= x+w and
	   py >= y and py <= y+h then
	   return true
	end

	return false
end

function isNumber (value)
	if type(value) == 'number' then
		return true
	end

	local s

	for s=1, #value do
		local c = value:sub(s,s)

		if not (c == '0' or c == '1' or c == '2' or
		   c == '3' or c == '4' or c == '5' or
		   c == '6' or c == '7' or c == '8' or
		   c == '9' or c == '.' or c == '-') then
			print (value .. ' isnt a number')
			return false
		end
	end

	return true
end

function ObjectEditor:updateProps ()
	local p
	for p=1, #self.propList.widgets do
		local key = self.propList.widgets[p].widgets[1].text
		local value = self.propList.widgets[p].widgets[2].text

		if isNumber(value) then
			self.object.properties[key] = tonumber(value)
		else
			self.object.properties[key] = value
		end
	end
end

function ObjectEditor:onPropsCancel ()
	self.window:close()
	self.window = nil
end

function ObjectEditor:onPropsApply ()
	self:updateProps()
end

function ObjectEditor:onPropsOkay ()
	self:updateProps()
	self.window:close()
	self.window = nil
end

function ObjectEditor:onPropsFile ()
	editor.openFileWindow()
end

function ObjectEditor:onPropsNew ()
	local container = gui.HContainer:new()

	key = gui.TextBox:new()
	key:begin('')
	key.fixedW = 48
	value = gui.TextBox:new()
	value:begin('')

	container:begin()
	container:addWidget(key)
	container:addWidget(value)

	container:invalidate()

	self.propList:addWidget(container)
	self.propList.offY = 0

	--	self:updateGUIProps()
end

function ObjectEditor:openPropertiesWindow ()
	local c1,c2,c3,c4,bar,b1,b2,b3,b4

	if not self.window then
		self.window = gui.Window:new()
		c1 = gui.VContainer:new() -- For c2, c4
		c2 = gui.HContainer:new() -- For c3, scrollbar
		c3 = gui.VContainer:new() -- For the props
		c4 = gui.HContainer:new() -- For apply/cancel/ok buttons
		
		-- Widgets
		bar = gui.ScrollBar:new()
		b1 = gui.Button:new('Cancel')
		b2 = gui.Button:new('Apply')
		b3 = gui.Button:new('Okay')
		b4 = gui.Button:new('New')
		b5 = gui.Button:new('File')

		c1:begin()
		c2:begin()
		c3:begin()
		c4:begin()
		c4.fixedH = 50

		b1:begin(self.onPropsCancel)
		b1.userData = self
		b2:begin(self.onPropsApply)
		b2.userData = self
		b3:begin(self.onPropsOkay)
		b3.userData = self
		b4:begin(self.onPropsNew)
		b4.userData = self
		b5:begin(self.onPropsFile)
		b5.userData = self

		bar:begin('vertical')
		bar:scrollContainer(c3)
		bar.fixedW = 24

		c1:addWidget(c2)
		c1:addWidget(c4)

		c2:addWidget(c3)
		c2:addWidget(bar)

		c4:addWidget(b1)
		c4:addWidget(b2)
		c4:addWidget(b3)
		c4:addWidget(b4)
		c4:addWidget(b5)

		self.propList = c3

		self:updateGUIProps ()

		self.window:setRootContainer(c1)

		gui.addWindow(self.window)
	end
end

function ObjectEditor:updateGUIProps()
	self.propList.widgets = {}
	self.propList.offY = 0

	-- Add all props
	local k,v
	for k,v in pairs(self.object.properties) do
		local key,value
		local container = gui.HContainer:new()

		key = gui.TextBox:new()
		key:begin(k)
		key.fixedW = 48
		value = gui.TextBox:new()
		value:begin(v)

		container:begin()
		container:addWidget(key)
		container:addWidget(value)

		self.propList:addWidget(container)
	end
end

function ObjectEditor:mouseDown (x, y, button)
	if love.keyboard.isDown ('lctrl') then
		if button == 'l' then
			if self:isInside(self.object.properties.x, self.object.properties.y,
							 self.object.properties.w, self.object.properties.h, x, y) then
				self.grabbing = true
				self.grabPosition.x = x
				self.grabPosition.y = y
			end
		end
	else
		if button == 'l' then
			if self:isInside(self.object.properties.x, self.object.properties.y,
							 self.object.properties.w, self.object.properties.h, x, y) then
				self.moving = true
				self.grabPosition.x = x
				self.grabPosition.y = y
			end
		end		
	end
end

function ObjectEditor:selected()
	local s
	for s=1, #selection do
		if selection[s] == self then
			return true
		end
	end

	return false
end

function ObjectEditor:toGrid3 (x, y)
	local px, py

	px = self.object.properties.x
	py = self.object.properties.y

	self.object.properties.x = x + px - (px+x-Grid.x)%Grid.w
	self.object.properties.y = y + py - (py+y-Grid.y)%Grid.h
end

function ObjectEditor:toGrid1 (x, y)
	local px, py, pw, ph

	px = self.object.properties.x
	py = self.object.properties.y
	pw = self.object.properties.w
	ph = self.object.properties.h

	self.object.properties.x = x + px - (px+x-Grid.x)%Grid.w+Grid.w - pw
	self.object.properties.y = y + py - (py+y-Grid.y)%Grid.h+Grid.h - ph
end

function ObjectEditor:toGrid2 (x, y)
	local px, py, pw, ph

	px = self.object.properties.x
	py = self.object.properties.y
	pw = self.object.properties.w
	ph = self.object.properties.h

	self.object.properties.x = x + px - (px+x-Grid.x)%Grid.w
	self.object.properties.y = y + py - (py+y-Grid.y)%Grid.h+Grid.h - ph
end

function ObjectEditor:toGrid4 (x, y)
	local px, py, pw, ph

	px = self.object.properties.x
	py = self.object.properties.y
	pw = self.object.properties.w
	ph = self.object.properties.h

	self.object.properties.x = x + px - (px+x-Grid.x)%Grid.w+Grid.w - pw
	self.object.properties.y = y + py - (py+y-Grid.y)%Grid.h
end

function ObjectEditor:toGrid (x, y)
	if not Grid.active then
		return
	end

	local cx, cy
	local ox, oy
	local d, l, q

	local q1 = {
		x = math.sqrt(2),
		y = math.sqrt(2)
	}

	local q2 = {
		x = -math.sqrt(2),
		y = math.sqrt(2)
	}

	local q3 = {
		x = -math.sqrt(2),
		y = -math.sqrt(2)
	}

	local q4 = {
		x = math.sqrt(2),
		y = -math.sqrt(2)
	}

	ox = self.object.properties.x
	oy = self.object.properties.y
	cx = ox-(ox-Grid.x)%Grid.w+Grid.w/2
	cy = oy-(oy-Grid.y)%Grid.h+Grid.h/2

	-- Find direction vector
	d = {
		x = cx-ox,
		y = cy-oy
	}

	-- Initialize l with an array and q with an array of quadrants
	l = {}
	q = {
		q1, q2, q3, q4
	}

	local quad

	for quad=1, #q do
		l[quad] = vmath.dot(q[quad], d)
	end

	if l[1] < l[2] and l[1] < l[3] and l[1] < l[4] then
		self:toGrid1(x, y)
	end

	if l[2] < l[1] and l[2] < l[3] and l[2] < l[4] then
		self:toGrid2(x, y)
	end

	if l[3] < l[2] and l[3] < l[1] and l[3] < l[4] then
		self:toGrid3(x, y)
	end

	if l[4] < l[2] and l[4] < l[3] and l[4] < l[1] then
		self:toGrid4(x, y)
	end
end

function ObjectEditor:mouseUp (x, y)
	if self.grabbing then
		MainLevel:markInHistory()
		self.grabbing = false
	end

	if self.moving then
		MainLevel:markInHistory()
		self.moving = false
	end

	if self:selected() then
		self:toGrid(self.object.properties.w/2,
					self.object.properties.h/2)
		MainLevel:markInHistory()
	end
end

function ObjectEditor:mouseMove (x, y)
	local dx, dy

	if self.grabbing then
		dx = self.grabPosition.x-x
		dy = self.grabPosition.y-y

		self.object.properties.w = self.object.properties.w - dx
		self.object.properties.h = self.object.properties.h - dy
	
		self.grabPosition.x = x
		self.grabPosition.y = y
	end

	if self.moving then
		dx = self.grabPosition.x-x
		dy = self.grabPosition.y-y

		local s
		for s=1, #selection do
			selection[s].object.properties.x = selection[s].object.properties.x - dx
			selection[s].object.properties.y = selection[s].object.properties.y - dy
		end

		self.grabPosition.x = x
		self.grabPosition.y = y
	end
end

function ObjectEditor:delete ()
	self.level:selectLayer(self.level:getLayerIndex(self.layer))
	self.level:selectObject(self.layer:getObjectIndex(self.object))
	self.level:removeObject()

	MainLevel:markInHistory()
end

local function collide (object, x, y)
	if isNumber(object.properties.x) then
		object.properties.x = tonumber(object.properties.x)
	end

	if isNumber(object.properties.y) then
		object.properties.y = tonumber(object.properties.y)
	end

	if isNumber(object.properties.w) then
		object.properties.w = tonumber(object.properties.w)
	end

	if isNumber(object.properties.h) then
		object.properties.h = tonumber(object.properties.h)
	end

	if x >= object.properties.x and x <= object.properties.x+object.properties.w and
	   y >= object.properties.y and y <= object.properties.y+object.properties.h then
	   return true
	end

	return false
end

local function collideI (box, x, y)
	if x >= box.x and x <= box.x+box.w and
	   y >= box.y and y <= box.y+box.h then
	   return true
	end

	return false
end

function boxCollide (object, box)
	if collide (object, box.x, box.y) or
	   collide (object, box.x+box.w, box.y) or
	   collide (object, box.x+box.w, box.y+box.h) or
	   collide (object, box.x, box.y+box.h) or
	   collideI(box, object.properties.x, object.properties.y) or
	   collideI(box, object.properties.x+object.properties.w, object.properties.y) or
	   collideI(box, object.properties.x+object.properties.w, object.properties.y+object.properties.h) or
	   collideI(box, object.properties.x, object.properties.y+object.properties.h) then
	   return true
	else
		return false
	end
end

local function inSelection (object)
	local s
	for s=1, #selection do
		if selection[s].object == object then
			return selection[s]
		end
	end

	return false
end

local function mouseDown (x, y, button, level)
	local l,o
	local click = false

	if button == 'l' then
		-- For every object in the map
		for l=1, #level.data.layers do
			if level.data.layers[l].active then
				for o=#level.data.layers[l].data,1,-1  do
					-- Check collision
					if collide(level.data.layers[l].data[o], x, y) then
						click = true

						-- Remove old selection
						if not love.keyboard.isDown('lshift') then
							selection = {}
						end
					
						if #selection == 0 or (#selection > 0 and not inSelection(level.data.layers[l].data[o])) then
							objectEditor = ObjectEditor:new(level, level.data.layers[l], level.data.layers[l].data[o])						
							table.insert (selection, objectEditor)
						else
							objectEditor = inSelection(level.data.layers[l].data[o])
						end

						break
					end
				end
			end
		end
	end

	-- If the user clicked in a blank space
	if not click then
		-- Remove old selection
		if not love.keyboard.isDown('lshift') then
			selection = {}
		end
		objectEditor = nil

		beginBoxSelection = {
			x=x,
			y=y,
			w=0,
			h=0
		}
	end

	local s
	for s=1,#selection do
		selection[s]:mouseDown (x, y, button)
	end
end
Module.mouseDown = mouseDown

local function mouseUp (x, y, level)
	local s
	for s=1,#selection do
		selection[s]:mouseUp (x,y)
	end

	if beginBoxSelection then
		-- Remove old selection
		if not love.keyboard.isDown('lshift') then
			selection = {}
		end

		-- For every object in the map
		for l=1, #level.data.layers do
			if level.data.layers[l].active then
				for o=1, #level.data.layers[l].data do
					-- Check collision
					if boxCollide(level.data.layers[l].data[o], beginBoxSelection) then
						if #selection == 0 or (#selection > 0 and not inSelection(level.data.layers[l].data[o])) then
							objectEditor = ObjectEditor:new(level, level.data.layers[l], level.data.layers[l].data[o])						
							table.insert (selection, objectEditor)
						else
							objectEditor = inSelection(level.data.layers[l].data[o])
						end
					end
				end
			end
		end

		beginBoxSelection = nil
	end
end
Module.mouseUp = mouseUp

local function mouseMove (x, y)
	local s
	for s=1,#selection do
		selection[s]:mouseMove (x,y)
	end

	if beginBoxSelection then
		beginBoxSelection.w = x-beginBoxSelection.x
		beginBoxSelection.h = y-beginBoxSelection.y
	end
end
Module.mouseMove = mouseMove

local function render (camera)
	local i

	if Grid.active then
		drawGrid()
	end

	if beginBoxSelection then
		love.graphics.setColor (0,128,255,255)
		love.graphics.rectangle('line', camera:getX(beginBoxSelection.x), camera:getY(beginBoxSelection.y),
										camera:getW(beginBoxSelection.w), camera:getH(beginBoxSelection.h))
	end

	local s
	for s=1,#selection do
		selection[s]:render(camera)
	end
end
Module.render = render

local window = nil

local function onSaveCancel ()
	window:close()
	window = nil
end

local function onSaveLoad (data)
	local path

	if love.filesystem.isDirectory(data.container.path) then
		path = data.container.path..'/'..data.entry.text
	else
		path = data.container.path
	end

	print ('loading map from '..path..'...')
	
	MainLevel:readFromFile (path)

	data.window:close()
	window = nil
end

local function onSaveSave (data)
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

	data.window:close()
	window = nil
end

local function onFileOk(data)
	local path

	if love.filesystem.isDirectory(data.container.path) then
		path = data.container.path..'/'..data.entry.text
	else
		path = data.container.path
	end

	if gui.getFocused() and gui.getFocused().text then
		gui.getFocused().text = path
		gui.getFocused().cursor = 0
	end

	data.window:close()
	window = nil
end

local function getFile (path)
	local n = 0
	while utf8.sub(path, utf8.len(path)-n, utf8.len(path)-n) ~= '/' and n < utf8.len(path) do
		n = n+1
	end

	if n >= utf8.len(path) then
		return path
	else
		return utf8.sub(path, utf8.len(path)-n+1, utf8.len(path))
	end
end

local function listDir (data)
	local container = data.container
 	local path

 	if data.lastdir ~= '' then
		path = data.lastdir..'/'..data.dir
	else
		path = data.dir
	end

	if love.filesystem.isDirectory (path) then
		container.widgets = {}
		container.fullH = nil
		container.offY = 0

		local filesInDir = love.filesystem.getDirectoryItems(path)

		if data.lastdir ~= '' or data.dir ~= '' then
			local goBack = gui.Button:new('^')
			goBack:begin(listDir)
			goBack.userData = {container=container, dir=data.lastdir, lastdir='', entry=data.entry}
			container:addWidget(goBack)
		end

		local i
		for i=1, #filesInDir do
			local folder = gui.Button:new(filesInDir[i])
			folder:begin(listDir)
			folder.userData = {container=container, dir=filesInDir[i], lastdir=path, entry=data.entry}
			container:addWidget(folder)
		end
		container.path = path
	else
		if love.filesystem.isFile (path) then
			data.entry.text= getFile(path)
		end
	end

	container:invalidate()
end

local function openSaveWindow ()
	local c1,c2,c3,c4
	local b1,b2,b3,b4
	local bar,entry

	window = gui.Window:new()

	c1 = gui.VContainer:new()
	c2 = gui.HContainer:new()
	c3 = gui.HContainer:new()
	c4 = gui.VContainer:new()

	c1:begin()
	c2:begin()
	c3:begin()
	c4:begin()

	bar = gui.ScrollBar:new()
	bar:begin('vertical')
	bar:scrollContainer(c4)
	bar.fixedW = 24

	entry = gui.TextBox:new()
	entry:begin()
	entry.fixedH = 24

	b1 = gui.Button:new('Cancel')
	b1:begin(onSaveCancel)
	b1.userData = window
	b2 = gui.Button:new('Load')
	b2:begin(onSaveLoad)
	b2.userData = {
		container=c4,
		entry=entry,
		window=window
	}

	b3 = gui.Button:new('Save')
	b3:begin(onSaveSave)
	b3.userData = {
		container=c4,
		entry=entry,
		window=window
	}

	b4 = gui.Button:new('Quit')
	b4:begin(function ()
		love.event.push('quit')
	end)

	c1:addWidget(c2)
	c1:addWidget(entry)
	c1:addWidget(c3)

	c2:addWidget(c4)
	c2:addWidget(bar)

	c3.fixedH = 48
	c3:addWidget(b4)	
	c3:addWidget(b1)
	c3:addWidget(b2)
	c3:addWidget(b3)

	if not love.filesystem.isDirectory('maps') then
		love.filesystem.createDirectory ('maps');
	end

	listDir ({
		container = c4,
		lastdir = '',
		dir = 'maps',
		entry = entry
	})

	window:setRootContainer(c1)

	gui.addWindow(window)
end

local function openFileWindow ()
	local c1,c2,c3,c4
	local b1,b2
	local bar,entry

	window = gui.Window:new()

	c1 = gui.VContainer:new()
	c2 = gui.HContainer:new()
	c3 = gui.HContainer:new()
	c4 = gui.VContainer:new()

	c1:begin()
	c2:begin()
	c3:begin()
	c4:begin()

	bar = gui.ScrollBar:new()
	bar:begin('vertical')
	bar:scrollContainer(c4)
	bar.fixedW = 24

	entry = gui.TextBox:new()
	entry:begin()
	entry.fixedH = 24

	b1 = gui.Button:new('Cancel')
	b1:begin(onSaveCancel)
	b1.userData = window

	b2 = gui.Button:new('Ok')
	b2:begin(onFileOk)
	b2.userData = {
		container=c4,
		entry=entry,
		window=window
	}

	c1:addWidget(c2)
	c1:addWidget(entry)
	c1:addWidget(c3)

	c2:addWidget(c4)
	c2:addWidget(bar)

	c3.fixedH = 48
	c3:addWidget(b1)
	c3:addWidget(b2)

	if not love.filesystem.isDirectory('maps') then
		love.filesystem.createDirectory ('maps');
	end

	listDir ({
		container = c4,
		lastdir = '',
		dir = 'assets',
		entry = entry
	})

	window:setRootContainer(c1)

	gui.addWindow(window)
end
Module.openFileWindow = openFileWindow

local function openAboutWindow ()
	local c1,c2
	local b1,w1,w2

	window = gui.Window:new()

	c1 = gui.VContainer:new()

	c1:begin()

	b1 = gui.Button:new('Ok')
	b1:begin(onSaveCancel)
	b1.userData = window
	b1.fixedH = 48

	w1 = gui.Widget:new('About')
	w1.fixedH = 24

	w2 = gui.Widget:new('IFGames Map Editor beta')

	c1:addWidget(w1)
	c1:addWidget(w2)
	c1:addWidget(b1)

	window:setRootContainer(c1)

	gui.addWindow(window)
end

local function objectCopy (o)
	local newO = {}
	local k,v

	newO.properties = {}

	for k,v in pairs(o.properties) do
		newO.properties[k] = v
	end

	setmetatable(newO, {__index=level.Object})

	return newO
end

local function onNewObject (object)
	local newObject = objectCopy(object)

	newObject.properties.x = code.MainCamera:getX(love.window:getWidth()/2)
	newObject.properties.y = code.MainCamera:getY(love.window:getHeight()/2)

	MainLevel:addObject(newObject)

	copiedObject = objectCopy(object)

	MainLevel:markInHistory()

	window:close()
	window = nil
end

local function updateObjectsList(container)
	local o

	container.widgets = {}
	container.offY = 0
	container.fullH = nil

	for o=1, #objectsList do
		local button = gui.Button:new(objectsList[o].properties.name)
		button:begin(onNewObject)
		button.userData = objectsList[o]

		container:addWidget(button)
	end

	container:invalidate()
end

local function onAddObject ()
	if objectEditor then
		table.insert(objectsList,objectCopy(objectEditor.object))
	end

	MainLevel:markInHistory()

	window:close()
	window = nil
end

local function openObjectsWindow ()
	local c1,c2,c3,c4
	local b1,b2
	local bar,entry

	window = gui.Window:new()

	c1 = gui.VContainer:new()
	c2 = gui.HContainer:new()
	c3 = gui.HContainer:new()
	c4 = gui.VContainer:new()

	c1:begin()
	c2:begin()
	c3:begin()
	c4:begin()

	bar = gui.ScrollBar:new()
	bar:begin('vertical')
	bar:scrollContainer(c4)
	bar.fixedW = 24

	--entry = gui.TextBox:new()
	--entry:begin()
	--entry.fixedH = 24

	b1 = gui.Button:new('Cancel')
	b1:begin(onSaveCancel)
	b1.userData = window

	b2 = gui.Button:new('Add')
	b2:begin(onAddObject)
	b2.userData = nil

	c1:addWidget(c2)
	--c1:addWidget(entry)
	c1:addWidget(c3)

	c2:addWidget(c4)
	c2:addWidget(bar)

	c3.fixedH = 48
	c3:addWidget(b1)
	c3:addWidget(b2)

	updateObjectsList(c4)

	window:setRootContainer(c1)

	gui.addWindow(window)
end

function onSelectLayer (data)
	if #selection == 0 then
		MainLevel:selectLayer(data.l)
	else
		MainLevel:selectLayer(data.l)
		local s
		for s=1, #selection do
			MainLevel:moveToLayer(selection[s])
		end
	end

	updateLayersList(data.container)
end

function onDeleteLayer (data)
	MainLevel:selectLayer(data.l)
	MainLevel:removeLayer()

	MainLevel:markInHistory()

	updateLayersList(data.container)
end

function onRenameOkay (data)
	MainLevel.data.layers[data.l].name = data.e.text

	updateLayersList(data.container)

	MainLevel:markInHistory()

	data.window:close()
end

function onRenameLayer (data)
	local renameWindow = gui.Window:new()
	local c1 = gui.VContainer:new()

	c1:begin()

	local b1
	local e1

	e1 = gui.TextBox:new()
	e1:begin()

	b1 = gui.Button:new('Okay')
	b1:begin(onRenameOkay)
	b1.userData = {
		l = data.l,
		e = e1,
		window = renameWindow,
		container = data.container
	}
	b1.fixedH = 48

	c1:addWidget(e1)
	c1:addWidget(b1)

	renameWindow:setRootContainer(c1)

	gui.addWindow(renameWindow)
end

function onActiveLayer (data, checked)
	MainLevel.data.layers[data.l].active = checked
	updateLayersList(data.container)
end

function onVisibleLayer (data, checked)
	MainLevel.data.layers[data.l].visible = checked
	MainLevel:markInHistory()
	updateLayersList(data.container)
end

function updateLayersList(container)
	local l

	container.widgets = {}
	container.offY = 0
	container.fullH = nil

	for l=1, #MainLevel.data.layers do
		local hcontainer = gui.HContainer:new()
		hcontainer:begin()

		local button = gui.Button:new(MainLevel.data.layers[l].name)
		button:begin(onSelectLayer)
		button.userData = {
			l = l,
			container = container
		}

		local deleteButton = gui.Button:new('D')
		deleteButton:begin(onDeleteLayer)
		deleteButton.userData = {
			l = l,
			container = container
		}
		deleteButton.fixedW = 24

		local renameButton = gui.Button:new('R')
		renameButton:begin(onRenameLayer)
		renameButton.userData = {
			l = l,
			container = container
		}
		renameButton.fixedW = 24

		local active = gui.CheckBox:new('A')
		active:begin(onActiveLayer)
		active.checked = MainLevel.data.layers[l].active
		active.userData = {
			l = l,
			container = container
		}
		active.fixedW = 24

		local visible = gui.CheckBox:new('V')
		visible:begin(onVisibleLayer)
		visible.checked = MainLevel.data.layers[l].visible
		visible.userData = {
			l = l,
			container = container
		}
		visible.fixedW = 24

		local objects = gui.Widget:new(tostring (#MainLevel.data.layers[l].data))
		objects.fixedW = 24

		hcontainer:addWidget(button)
		hcontainer:addWidget(objects)
		hcontainer:addWidget(renameButton)
		hcontainer:addWidget(deleteButton)
		hcontainer:addWidget(visible)
		hcontainer:addWidget(active)

		container:addWidget(hcontainer)
	end

	container:invalidate()
end

local function onNewLayer (container)
	MainLevel:addLayer (level.Layer:new())
	updateLayersList(container)
	MainLevel:markInHistory()
end

local function onGridAlign (nothing)
	if #selection > 0 then
		Grid.x = selection[1].object.properties.x
		Grid.y = selection[1].object.properties.y
	end
end

local function onGridToggle (data, active)
	Grid.active = active
end

local function onGridClose (data)
	if isNumber(data.w.text) and isNumber (data.h.text) then
		Grid.w = tonumber (data.w.text)
		Grid.h = tonumber (data.h.text)
	end

	window:close()
	window = nil
end

local function openGridWindow ()
	local c1,c2,c3,c4,ch1
	local b1,b2
	local bar,entry

	window = gui.Window:new()

	c1 = gui.VContainer:new()
	c2 = gui.VContainer:new()
	c3 = gui.HContainer:new()
	c4 = gui.HContainer:new()

	c1:begin()
	c2:begin()
	c3:begin()
	c4:begin()

	--bar = gui.ScrollBar:new()
	--bar:begin('vertical')
	--bar:scrollContainer(c4)
	--bar.fixedW = 24

	--entry = gui.TextBox:new()
	--entry:begin()
	--entry.fixedH = 24

	b1 = gui.Button:new('Align')
	b1:begin(onGridAlign)
	--b1.userData = window
	b1.fixedH = 50

	b2 = gui.Button:new('Ok')
	b2:begin(onGridClose)
	b2.userData = {}
	b2.fixedH = 50

	ch1 = gui.CheckBox:new('Active')
	ch1:begin(onGridToggle)
	ch1.fixedH = 50
	ch1.checked = Grid.active

	c1:addWidget(ch1)
	c1:addWidget(c2)
	c2:addWidget(c3)
	c2:addWidget(c4)
	c1:addWidget(b1)
	c1:addWidget(b2)

	local w1,e1
	w1 = gui.Widget:new('w')
	w1.fixedW = 24
	e1 = gui.TextBox:new()
	e1:begin()
	e1.text = tostring (Grid.w)
	b2.userData.w = e1

	c3:addWidget (w1)
	c3:addWidget (e1)

	w1 = gui.Widget:new('h')
	w1.fixedW = 24
	e1 = gui.TextBox:new()
	e1:begin()
	e1.text = tostring (Grid.h)
	b2.userData.h = e1

	c4:addWidget (w1)
	c4:addWidget (e1)

	window:setRootContainer(c1)

	gui.addWindow(window)
end

local function openLayersWindow ()
	local c1,c2,c3,c4
	local b1,b2
	local bar,entry

	window = gui.Window:new()

	c1 = gui.VContainer:new()
	c2 = gui.HContainer:new()
	c3 = gui.HContainer:new()
	c4 = gui.VContainer:new()

	c1:begin()
	c2:begin()
	c3:begin()
	c4:begin()

	bar = gui.ScrollBar:new()
	bar:begin('vertical')
	bar:scrollContainer(c4)
	bar.fixedW = 24

	--entry = gui.TextBox:new()
	--entry:begin()
	--entry.fixedH = 24

	b1 = gui.Button:new('Cancel')
	b1:begin(onSaveCancel)
	b1.userData = window

	b2 = gui.Button:new('New')
	b2:begin(onNewLayer)
	b2.userData = c4

	c1:addWidget(c2)
	--c1:addWidget(entry)
	c1:addWidget(c3)

	c2:addWidget(c4)
	c2:addWidget(bar)

	c3.fixedH = 48
	c3:addWidget(b1)
	c3:addWidget(b2)

	updateLayersList(c4)

	window:setRootContainer(c1)

	gui.addWindow(window)
end

local function groupHorizontally ()
	if #selection == 0 then
		return
	end

	-- Selection width
	local sw = 0

	local minY = selection[1].object.properties.y+selection[1].object.properties.h/2
	local maxY = selection[1].object.properties.y+selection[1].object.properties.h/2
	local minX = selection[1].object.properties.x
	local maxX = selection[1].object.properties.x+selection[1].object.properties.w

	local s
	for s=1,#selection do
		if selection[s].object.properties.y+selection[1].object.properties.h/2 < minY then
			minY = selection[s].object.properties.y+selection[1].object.properties.h/2
		end

		if selection[s].object.properties.y+selection[s].object.properties.h/2 > maxY then
			maxY = selection[s].object.properties.y+selection[s].object.properties.h/2
		end

		if selection[s].object.properties.x < minX then
			minX = selection[s].object.properties.x
		end

		if selection[s].object.properties.x+selection[s].object.properties.w > maxX then
			maxX = selection[s].object.properties.x+selection[s].object.properties.w
		end
	
		sw = sw + selection[s].object.properties.w
	end

	local p = 0
	for s=1,#selection do
		selection[s].object.properties.y = (minY+maxY)/2-selection[s].object.properties.h/2
		selection[s].object.properties.x = minX+((maxX-minX)-sw)/#selection*(s-1)+p
		p = p+selection[s].object.properties.w
	end

	MainLevel:markInHistory()
end

local function bookmarkObject (object)
	table.insert(objectsList,objectCopy(object))
end
Module.bookmarkObject = bookmarkObject

local function clearBookmarks (object)
	objectsList = {}
end
Module.clearBookmarks = clearBookmarks

local function setCamera (camera)
	MainCamera = camera
end
Module.setCamera = setCamera

local function setLevel (level)
	MainLevel = level
end
Module.setLevel = setLevel

local function copySelection ()
	selectionCopy = {}

	local s
	for s=1, #selection do
		table.insert(selectionCopy, objectCopy(selection[s].object))
	end
end

local function pasteSelection ()
	local s
	for s=1, #selectionCopy do
		local newObject = objectCopy(selectionCopy[s])

		newObject.properties.x = newObject.properties.x+code.MainCamera:getIX(love.mouse.getX())-selectionCopy[1].properties.x
		newObject.properties.y = newObject.properties.y+code.MainCamera:getIY(love.mouse.getY())-selectionCopy[1].properties.y

		MainLevel:addObject(newObject)
	end	

	MainLevel:markInHistory()
end

function drawGrid ()
	local x,y

	love.graphics.setColor(0, 128, 128)

	for x=(MainCamera:getX(0)+Grid.x)%Grid.w, love.window.getWidth(), Grid.w do
		love.graphics.line (x, 0, x, love.window.getHeight())
	end

	for y=(MainCamera:getY(0)+Grid.y)%Grid.h, love.window.getHeight(), Grid.h do
		love.graphics.line (0, y, love.window.getWidth(), y)
	end
end

local function keyDown (key, isrepeat, camera)
	if objectEditor then
		if key == 'delete' then
			local s
			for s=1, #selection do
				selection[s]:delete()
			end
			objectEditor = nil
			selection = {}
		end

		if key == 'c' and love.keyboard.isDown('lctrl') then
			copiedObject = objectCopy(objectEditor.object)

			copySelection()
		end

		if copiedObject then
			if key == 'v' and love.keyboard.isDown('lctrl') then
				pasteSelection()
			end
		end

		if key == 'w' and love.keyboard.isDown('lctrl') then
			groupHorizontally()	
		end

		if key == 'f1' then
			objectEditor:openPropertiesWindow()
		end
	end

	if key == '1' then
		camera.sx = 1
		camera.sy = 1
	end

	if key == '2' then
		camera.sx = 2
		camera.sy = 2 
	end

	if key == '3' then
		camera.sx = 4
		camera.sy = 4 
	end

	if key == 'z' and love.keyboard.isDown('lctrl') and not love.keyboard.isDown('lshift') then
		MainLevel:undo()
	end

	if key == 'z' and love.keyboard.isDown('lctrl') and love.keyboard.isDown('lshift') then
		MainLevel:redo()
	end

	if key == 'n' and love.keyboard.isDown('lctrl') then
		-- Add a new object at mouse position
		local newObject

		if copiedObject then
			newObject = objectCopy(copiedObject)
		else
			newObject = level.Object:new()
		end 

		newObject.properties.x = code.MainCamera:getIX(love.mouse.getX())
		newObject.properties.y = code.MainCamera:getIY(love.mouse.getY())

		MainLevel:addObject(newObject)

		MainLevel:markInHistory()
	end

	if key == 'f2' and not window then
		openSaveWindow()
	end

	if key == 'f3' and not window then
		openObjectsWindow()
	end

	if key == 'f4' and not window then
		openLayersWindow()
	end

	if key == 'f5' and not window then
		openAboutWindow()
	end

	if key == 'f6' and not window then
		openGridWindow()
	end
end
Module.keyDown = keyDown

Module.ObjectEditor = ObjectEditor

return Module