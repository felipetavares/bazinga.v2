local Module = {}

local Camera = {
}

-- [Camera]
-- Helper

function Camera:new ()
	local o = {
		x = 0,
		y = 0,
		sx = 1,
		sy = 1,
		smx = 0,
		smy = 0,
		moving = false
	}
	setmetatable (o, {__index=self})

	return o
end

-- Transformations
function Camera:getX (x)
	return (x)*self.sx-self.x
end

function Camera:getY (y)
	return (y)*self.sy-self.y
end

function Camera:getIX (x)
	return (x+self.x)/self.sx
end

function Camera:getIY (y)
	return (y+self.y)/self.sy
end

function Camera:getW (w)
	return w*self.sx
end

function Camera:getH (h)
	return h*self.sy
end

function Camera:beginMove (x, y)
	self.smx = (-self.x-x)
	self.smy = (-self.y-y)
	self.moving = true
end

function Camera:move (x, y)
	if self.moving then
		self.x = -(self.smx+x)
		self.y = -(self.smy+y)
	end
end

function Camera:endMove ()
	self.moving = false
end

Module.Camera = Camera
return Module