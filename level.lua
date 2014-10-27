local Module = {}

local Object = {
}

local Layer = {
}

-- Represents a level
local Level = {
}

-- [Object]
-- Helper
function Object:new (x, y)
	local o = {
		properties = {
			-- Some default properties
			-- All spatial related
			x = 0,
			y = 0,
			w = 16,
			h = 16,
			name = 'unamed',
		}
	}
	setmetatable (o, {__index=self})

	if x and y then
		o.properties.x = x
		o.properties.y = y
	end

	return o
end

-- Rendering
function Object:render (camera)
	if self.properties.img then
		local image = cache.getImage(self.properties.img)
		love.graphics.setColor (255, 255, 255, 0)
		love.graphics.rectangle ('fill', camera:getX(self.properties.x), camera:getY(self.properties.y),
									 camera:getW(self.properties.w), camera:getH(self.properties.h))
		love.graphics.setColor (255, 255, 255, 255)
		love.graphics.draw (image, camera:getX(self.properties.x), camera:getY(self.properties.y), 0, camera.sx, camera.sy)
	else
		love.graphics.setColor (255, 0, 0, 255)
		love.graphics.rectangle ('fill', camera:getX(self.properties.x), camera:getY(self.properties.y),
									 camera:getW(self.properties.w), camera:getH(self.properties.h))
	end
end

-- [Layer]
-- Helper functions

-- Creates a new object
function Layer:new ()
	local o = {
		active = true,
		visible = true,
		name = '',
		properties = {},
		data = {}
	}

	if o.name == '' then
		o.name = 'unamed'
	end

	setmetatable (o, {__index=self})

	return o
end

function Layer:getObjectIndex (object)
	local o

	for o=1, #self.data do
		if object == self.data[o] then
			return o
		end
	end

	return -1
end

-- [Level]
-- Helper functions below

-- Creates a new object
function Level:new ()
	local o = {
		data = {
			name = '',
			properties = {},
			layers = {}
		},

		-- Information about what we are currently editing
		editing = {
			layer = 0,
			object = 0
		}
	}
	setmetatable (o, {__index=self})

	return o
end

function Level:getLayerIndex (layer)
	local l

	for l=1, #self.data.layers do
		if layer == self.data.layers[l] then
			return l
		end
	end

	return -1
end

-- Verifies if self.editing contains valid data
function Level:isEditSafe ()
	-- If we have valid values in both self.editing.layer and self.editing.object
	if self.editing.layer > 0 and self.editing.layer <= #self.data.layers and
		self.editing.object > 0 and self.editing.object <= #self.data.layers[self.editing.layer].data then
		return true
	end

	return false
end

-- Verifies just if the layer is safe
function Level:isLayerSafe ()
	if self.editing.layer > 0 and self.editing.layer <= #self.data.layers then
		return true
	end

	return false
end

-- Load a level from disk
function Level:readFromFile (fileName)
	if love.filesystem.isFile (fileName) then
		self.data = json.decode (love.filesystem.read(fileName), 1, nil)

		editor.clearBookmarks()

		print (#self.data.layers..' layers loaded')

		local l
		for l=1, #self.data.layers do
			setmetatable (self.data.layers[l], {__index=Layer})
		
			print (#self.data.layers[l].data..' objects in layer '..l)

			local o
			for o=1, #self.data.layers[l].data do
				setmetatable (self.data.layers[l].data[o], {__index=Object})
				if self.data.layers[l].data[o].properties.name ~= 'unamed' then
					editor.bookmarkObject (self.data.layers[l].data[o])
				end
			end
		end

		return true
	end

	return false
end

-- Write a level to the disk
function Level:writeToFile (fileName)
	local string

	string = json.encode(self.data)

	local sucess = love.filesystem.write (fileName, string)

	return sucess
end

-- Select a layer
function Level:selectLayer (layer)
	if layer > 0 and layer <= #self.data.layers then
		self.editing.layer = layer
		return true
	end

	return false
end

function Level:findObject (layer, object)
	local o
	for o=1, #layer.data do
		if layer.data[o] == object then
			return o
		end
	end

	return false
end

-- Move a object to the current layer
function Level:moveToLayer (objectEditor)
	self:addObject(objectEditor.object)
	table.remove(objectEditor.layer.data, self:findObject(objectEditor.layer, objectEditor.object))
	objectEditor.layer = self.data.layers[self.editing.layer]
end

-- Select an object
function Level:selectObject (object)
	if self:isLayerSafe() then
		if object > 0 and object <= #self.data.layers[self.editing.layer].data then
			self.editing.object = object
			return true
		end
	end

	return false
end

-- Add an object
function Level:addObject (object)
	if self:isLayerSafe() then
		table.insert (self.data.layers[self.editing.layer].data, object)
		return true
	end

	return false
end

-- Remove an object
function Level:removeObject ()
	if self:isEditSafe() then
		table.remove (self.data.layers[self.editing.layer].data, self.editing.object)
		self.editing.object = 0
		return true
	end

	return false
end

-- Add a layer
function Level:addLayer (layer)
	table.insert (self.data.layers, layer)

	-- If we had no layers, select this one
	if #self.data.layers == 1 then
		self.editing.layer = 1
	end

	return true
end

-- Remove a layer
function Level:removeLayer ()
	if self:isLayerSafe() then
		table.remove (self.data.layers, self.editing.layer)
		self.editing.layer = 0
		return true
	end

	return false
end

-- Render everything
function Level:render (camera)
	--print (#self.data.layers[1].data)

	local l,o
	for l=1, #self.data.layers do
		if self.data.layers[l].visible then
			for o=1, #self.data.layers[l].data do
				self.data.layers[l].data[o]:render(camera)
			end
		end
	end
end

Module.Object = Object
Module.Layer  = Layer
Module.Level  = Level

return Module