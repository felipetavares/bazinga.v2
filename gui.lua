--[=[
	How widgets are resized to the right size?
	The system queries for the wanted size of the element.
	The element(widget) can return values either in percent or in pixels.
	The system puts the element in the closest possible size.

	If the element returns no preferred size, the system
	automatically resizes it to the remaining space.
--]=]

local focusedWidget = nil

local Module = {}
Module.border = 12

local windows = {}

local Widget = {
}

local Window = {	
}

local Rectangle = {
}

function Rectangle:new (x, y, w, h)
	local o = {
		x = x,
		y = y,
		w = w,
		h = h
	}

	setmetatable (o, {__index=self})

	return o
end

local iScissor = {
	-- Stack of scissors for save/restore
	stack = {},
	scissor = nil
}

function iScissor:apply ()
	if self.scissor then
		love.graphics.setScissor (self.scissor.x, self.scissor.y, self.scissor.w, self.scissor.h)
	end
end

-- Combine the new & old scissor
function iScissor:combineScissor (x,y,w,h)
	local scissor = Rectangle:new(x,y,w,h)
	local finalScissor = Rectangle:new(0,0,0,0)

	if scissor.x > self.scissor.x then
		finalScissor.x = scissor.x
	else
		finalScissor.x = self.scissor.x
	end

	if scissor.x+scissor.w < self.scissor.x+self.scissor.w then
		finalScissor.w = (scissor.x+scissor.w)-finalScissor.x
	else
		finalScissor.w = (self.scissor.x+self.scissor.w)-finalScissor.x
	end

	if scissor.y > self.scissor.y then
		finalScissor.y = scissor.y
	else
		finalScissor.y = self.scissor.y
	end

	if scissor.y+scissor.h < self.scissor.y+self.scissor.h then
		finalScissor.h = (scissor.y+scissor.h)-finalScissor.y
	else
		finalScissor.h = (self.scissor.y+self.scissor.h)-finalScissor.y
	end

	if finalScissor.w < 0 or finalScissor.h < 0 then
		self.scissor = self.scissor
	else
		self.scissor = finalScissor
	end
	
	self:apply()
end

-- Set the current scissor
function iScissor:setScissor (x, y, w, h)
	self.scissor = Rectangle:new(x,y,w,h)
	self:apply()
end

-- Save the current scissor
function iScissor:save ()
	table.insert(self.stack,self.scissor)
end

-- Load the current scissor
function iScissor:restore ()
	if #self.stack > 0 then
		self.scissor = table.remove(self.stack)
	end
	self:apply()
end

-- Interpolated value
local iv = {
	
}

function iv:new (time)
	local o = {
		time = time,
		x0 = 0,
		x1 = 0,
		y0 = 0,
		y1 = 0
	}
	setmetatable (o, {__index=self})

	return o
end

function iv:set (value)
	self.y0 = self:get()
	self.y1 = value
	self.x0 = love.timer.getTime()
	self.x1 = self.x0+self.time
end

function iv:get ()
	local x = love.timer.getTime()

	if self.x1 == self.x0 then
		return 0
	end

	if x > self.x1 then
		return self.y1
	end

	if x < self.x0 then
		return self.y0
	end

	return self.y0 + (self.y1-self.y0)*(x-self.x0)/(self.x1-self.x0)
end

function Widget:new (name)
	local o = {
		x = 0, y = 0, w = 0, h = 0,
		container = nil,
		invalid = true,
		mouseInside = false,
		color = {
			r = iv:new(0.5),
			g = iv:new(0.5),
			b = iv:new(0.5)
		},
		name = ''
	}
	setmetatable (o, {__index=self})

	if name then
		o.name = name
	end

	o.color.r:set(0)
	o.color.g:set(128)
	o.color.b:set(0)

	return o
end

function Widget:input (unicode)
	-- do nothing
end

function Widget:keyDown (key, isrepeat)
end

function Widget:keyUp (key)
end

function Widget:select ()
	self.color.r:set(0)
	self.color.g:set(0)
	self.color.b:set(128)
end

function Widget:enter ()
	self.color.r:set(0)
	self.color.g:set(255)
	self.color.b:set(0)
end

function Widget:leave ()
	self.color.r:set(0)
	self.color.g:set(128)
	self.color.b:set(0)
end

function Widget:click ()
	self.color.r:set(0)
	self.color.g:set(0)
	self.color.b:set(255)

	-- Now we have keyboard focus
	gui.setFocus(self)
end

function Widget:focus ()
	self.focused = true
end

function Widget:unfocus ()
	self.focused = nil
end

function Widget:move (x, y)
end

function Widget:down (button)
end

function Widget:up (button)
end

function Widget:mouseMove (x, y)
	if not self.mouseInside and self:isInside (x, y) then
		self:enter()
		self.mouseInside = true
	end

	if not self:isInside(x, y) and self.mouseInside then
		self:leave()
		self.mouseInside = false
	end

	if self:isInside(x, y) then
		self:move(x, y)
	end
end

function Widget:mouseDown (x, y, button)
	if self:isInside(x, y) then
		self:select()
	end

	self:down(button)
end

function Widget:mouseUp (x, y, button)
	if self:isInside(x, y) then
		self:click()
	end

	self:up(button)
end

function Widget:invalidate ()
	self.invalid = true
end

function Widget:resize()
	self.invalid = false
end

function Widget:update ()
	if self.invalid then
		self:resize()
	end
end

function Widget:render ()
	iScissor:save()
	iScissor:combineScissor (self.x, self.y, self.w, self.h)

	love.graphics.setColor (self.color.r:get(), self.color.g:get(), self.color.b:get(), 255)
	love.graphics.rectangle ('fill', self.x+1, self.y+1,
									 self.w-2, self.h-2)

	love.graphics.setColor (0, 0, 0, 255)
	love.graphics.print (self.name, self.x+self.w/2-love.graphics.getFont():getWidth(self.name)/2, self.y+self.h/2-8)

	if self.focused then
		love.graphics.setColor (255, 0, 0, 255)
		love.graphics.rectangle ('line', self.x, self.y,
											 self.w, self.h)
	end

	iScissor:restore()
end

function Widget:isInside (x, y)
	if x >= self.x and x <= self.x+self.w and
	   y >= self.y and y <= self.y+self.h then
	   return true
	end

	return false
end

local TextBox = Widget:new()

function TextBox:begin(text)
	self.cursor = 0

	if text then
		self.text = tostring(text)
	else
		self.text = ''
	end
end

function TextBox:input (unicode)
	if self.cursor > utf8.len(self.text) then
		self.text = self.text..unicode
	else if self.cursor == 0 then
		self.text = unicode..self.text
	else
		self.text = utf8.sub(self.text, 0, self.cursor)..unicode..utf8.sub(self.text,self.cursor+1,utf8.len(self.text))
	end
	end
	
	self.cursor = self.cursor+1
end

function TextBox:keyUp (key)
	if key == 'backspace' then
		if utf8.len(self.text) == 1 then
			self.text = ''
		else
			self.text = utf8.sub(self.text, 0, utf8.len(self.text)-1)
			self.cursor = self.cursor-1
		end
	end

	if key == 'left' then
		if self.cursor > 0 then
			self.cursor = self.cursor-1
		end
	end

	if key == 'right' then
		if self.cursor < utf8.len(self.text) then
			self.cursor = self.cursor+1
		end
	end

	if key == 'home' then
		self.cursor = 0
	end

	if key == 'end' then
		self.cursor = utf8.len(self.text)
	end
end

function TextBox:render ()
	iScissor:save()
	iScissor:combineScissor (self.x, self.y, self.w, self.h)

	love.graphics.setColor (self.color.r:get(), self.color.g:get(), self.color.b:get(), 255)
	love.graphics.rectangle ('fill', self.x+1, self.y+1,
									 self.w-2, self.h-2)

	love.graphics.setColor (0, 0, 0, 255)
	love.graphics.print (self.text, self.x, self.y+self.h/2-love.graphics.getFont():getHeight('')/2)

	local cursorPosition

	if self.cursor == 0 then
		cursorPosition = 0
	else
		cursorPosition = love.graphics.getFont():getWidth(utf8.sub(self.text,0,self.cursor))
	end

	love.graphics.rectangle ('fill', self.x+cursorPosition, self.y+self.h/8,
									 2, self.h-self.h/4)

	if self.focused then
		love.graphics.setColor (255, 0, 0, 255)
		love.graphics.rectangle ('line', self.x, self.y,
											 self.w, self.h)
	end

	iScissor:restore()
end
Module.TextBox = TextBox

local ScrollBar = Widget:new()

function ScrollBar:begin(type)
	self.position = 0
	self.isclicked = false
	self.type = type

	if not self.type then
		self.type = 'horizontal'
	end
end

function ScrollBar:move (x, y)
	if self.isclicked == true then
		if self.type == 'horizontal' then
			self.position = (x-self.x)/self.w
		else
			self.position = (y-self.y)/self.h			
		end

		if self.linkedContainer then
			self.linkedContainer.offY = -self.position*(self.linkedContainer.fullH-self.linkedContainer.h)
			self.linkedContainer:invalidate()
		end
	end
end

function ScrollBar:down (button)
	if button == 1 then
		self.isclicked = true
	end
end

function ScrollBar:up (button)
	if button == 1 then
		self.isclicked = false
	end
end

function ScrollBar:leave ()
	Widget.leave (self)

	self.isclicked = false
end

function ScrollBar:scrollContainer (container)
	self.linkedContainer = container
end

function ScrollBar:render ()
	iScissor:save()
	iScissor:combineScissor (self.x, self.y, self.w, self.h)

	love.graphics.setColor (self.color.r:get(), self.color.g:get(), self.color.b:get(), 255)
	love.graphics.rectangle ('fill', self.x+1, self.y+1,
									 self.w-2, self.h-2)

	if self.type == 'horizontal' then
		love.graphics.setColor (255, 0, 0, 255)
		love.graphics.rectangle ('fill', self.x, self.y,
										 self.w*self.position, self.h)
	else
		love.graphics.setColor (255, 0, 0, 255)
		love.graphics.rectangle ('fill', self.x, self.y,
										 self.w, self.h*self.position)		
	end
	
	love.graphics.setColor (255, 255, 255, 255)
	love.graphics.print (self.name, self.x, self.y+self.h/2-8)

	if self.focused then
		love.graphics.setColor (255, 0, 0, 255)
		love.graphics.rectangle ('line', self.x, self.y,
											 self.w, self.h)
	end

	iScissor:restore()
end
Module.ScrollBar = ScrollBar

local CheckBox = Widget:new()

function CheckBox:begin(callback)
	self.callback = callback
	self.checked = false
end

function CheckBox:click ()
	self.checked = not self.checked

	if self.callback then
		self.callback(self.userData, self.checked)
	end
end

function CheckBox:render ()
	if self.checked == true then
		love.graphics.setColor (255, 0, 0, 255)
	else
		love.graphics.setColor (self.color.r:get(), self.color.g:get(), self.color.b:get(), 255)
	end

	love.graphics.rectangle ('fill', self.x+1, self.y+1,
									 self.w-2, self.h-2)

	love.graphics.setColor (0, 0, 0, 255)
	love.graphics.print (self.name, self.x+self.w/2-love.graphics.getFont():getWidth(self.name)/2, self.y+self.h/2-8)

	if self.focused then
		love.graphics.setColor (255, 0, 0, 255)
		love.graphics.rectangle ('line', self.x, self.y,
											 self.w, self.h)
	end
end
Module.CheckBox = CheckBox

local Button = Widget:new()

function Button:begin(callback)
	self.callback = callback
end

function Button:click ()
	if self.callback then
		self.callback(self.userData)
	end
end

function Button:render ()
	iScissor:save()
	iScissor:combineScissor (self.x, self.y, self.w, self.h)
	
	love.graphics.setColor (self.color.r:get(), self.color.g:get(), self.color.b:get(), 255)
	love.graphics.rectangle ('fill', self.x+1, self.y+1,
									 self.w-2, self.h-2)

	love.graphics.setColor (0, 0, 0, 255)
	love.graphics.print (self.name, self.x+self.w/2-love.graphics.getFont():getWidth(self.name)/2, self.y+self.h/2-8)

	if self.focused then
		love.graphics.setColor (255, 0, 0, 255)
		love.graphics.rectangle ('line', self.x, self.y,
											 self.w, self.h)
	end

	iScissor:restore()
end
Module.Button = Button

-- Special type of widget
local Container = Widget:new()

local VContainer = Container:new()

local HContainer = Container:new()

function HContainer:resize ()
	local wid

	local pX = self.x+self.offX
	local pY = self.y+self.offY
	local pW = self.w
	local pH = self.h

	local unfixedW = self.w
	local unfixedN = #self.widgets

	for wid=1, #self.widgets do
		if self.widgets[wid].fixedW then
			unfixedW = unfixedW - self.widgets[wid].fixedW
			unfixedN = unfixedN - 1
		end
	end

	for wid=1, #self.widgets do
		self.widgets[wid].x = pX
		self.widgets[wid].y = pY
		
		if self.widgets[wid].fixedW then
			self.widgets[wid].w = self.widgets[wid].fixedW
		else
			self.widgets[wid].w = unfixedW/unfixedN
		end

		self.widgets[wid].h = pH

		pW = pW - self.widgets[wid].w
		pX = pX + self.widgets[wid].w
	end

	self.invalid = false
end

function VContainer:resize ()
	local wid

	local pX = self.x+self.offX
	local pY = self.y+self.offY
	local pW = self.w
	local pH = self.h

	local unfixedH = self.fullH
	local unfixedN = #self.widgets

	for wid=1, #self.widgets do
		if self.widgets[wid].fixedH then
			unfixedH = unfixedH - self.widgets[wid].fixedH
			unfixedN = unfixedN - 1
		end
	end

	for wid=1, #self.widgets do
		self.widgets[wid].x = pX
		self.widgets[wid].y = pY
		self.widgets[wid].w = pW

		if self.widgets[wid].fixedH then
			self.widgets[wid].h = self.widgets[wid].fixedH
		else
			self.widgets[wid].h = unfixedH/unfixedN
		end

		pH = pH - self.widgets[wid].h
		pY = pY + self.widgets[wid].h
	end

	self.invalid = false
end

function Container:begin ()
	self.widgets = {}
	self.invertWidgets = {}

	self.offX = 0
	self.offY = 0

	self.mouseInside = false
end

function Container:invalidate ()
	local wid

	for wid=1, #self.widgets do
		self.widgets[wid]:invalidate()
	end

	self.invalid = true
end

function Container:mouseDown (x, y, button)
	if not self:isInside(x, y) then
		return
	end

	local wid

	for wid=1, #self.widgets do
		self.widgets[wid]:mouseDown (x, y, button)
	end
end

function Container:mouseUp (x, y, button)
	if not self:isInside(x, y) then
		return
	end

	local wid

	for wid=1, #self.widgets do
		if self.widgets[wid] then
			self.widgets[wid]:mouseUp (x, y, button)
		end
	end
end

function Container:mouseMove (x, y)
	if not self.mouseInside and self:isInside (x, y) then
		self:enter()
		self.mouseInside = true
	end

	if not self:isInside(x, y) and self.mouseInside then
		self:leave()
		self.mouseInside = false
	end

	if not self:isInside(x, y) then
		return
	end

	local wid

	for wid=1, #self.widgets do
		self.widgets[wid]:mouseMove (x, y, button)
	end
end

function Container:addWidget (widget)
	widget.container = self

	table.insert (self.widgets, widget)

	self.invertWidgets = table.invert(self.widgets)

	return true
end

function Container:render ()
	local wid

	for wid=1, #self.widgets do
		iScissor:save()
		iScissor:combineScissor (self.x, self.y, self.w, self.h)
		--print ('combined scissor on container: '..iScissor.scissor.x..';'..iScissor.scissor.y..';'
		--										..iScissor.scissor.w..';'..iScissor.scissor.h)

			self.widgets[wid]:render()
		iScissor:restore()
	end
end

function Container:resize ()
	local wid

	local pX = self.x
	local pY = self.y
	local pW = self.w
	local pH = self.h

	for wid=1, #self.widgets do
		self.widgets[wid].x = pX
		self.widgets[wid].y = pY
		self.widgets[wid].w = self.w/#self.widgets
		self.widgets[wid].h = pH

		pW = pW - self.widgets[wid].w
		pX = pX - self.widgets[wid].w

		self.widgets[wid].invalid = false
	end

	self.invalid = false
end

function Container:leave ()
	local wid

	for wid=1, #self.widgets do
		self.widgets[wid]:leave()
	end
end

function Container:update ()
	local wid

	if not self.fullH then
		self.fullH = self.h
	end

	-- Less than 50 pixels per thing
	if self.fullH/#self.widgets < 50 then
		-- Put a size of 50 pixels per thing
		self.fullH = #self.widgets*50
	end

	if self.invalid then
		self:resize()
	end

	for wid=1, #self.widgets do
		self.widgets[wid]:update()
	end
end

function Window:onBar (x, y)
	if x >= self.x and x <= self.x+self.w and
	   y >= self.y and y <= self.y+24 then
	   return true
	end

	return false
end

function Window:isInside (x, y)
	if x >= self.x and x <= self.x+self.w and
	   y >= self.y and y <= self.y+self.h then
	   return true
	end

	return false
end

function Window:setRootContainer (container)
	container.container = self
	self.rootContainer = container
end

function Window:mouseDown (x, y, button)
	if not self.isVisible then
		return false
	end

	if self:isInside (x,y) then
		if self:onBar (x, y) then
			self.moving = true
			self.barX = x-self.x
			self.barY = y-self.y
		end

		if self.rootContainer then
			self.rootContainer:mouseDown(x, y, button)
		end

		return true
	else
		return false
	end
end

function Window:mouseUp (x, y, button)
	if not self.isVisible then
		return
	end

	self.moving = false

	if self:isInside (x,y) then
		if self.rootContainer then
			self.rootContainer:mouseUp(x, y, button)
		end

		return true
	end

	return false
end

function Window:mouseMove (x, y)
	if self.moving then
		self.x = x-self.barX
		self.y = y-self.barY
		if self.rootContainer then
			self.rootContainer:invalidate()
		end
	end

	if self:isInside (x,y) then
		if self.rootContainer then
			self.rootContainer:mouseMove(x, y)
		end
	
		return true
	end

	return false
end

function Window:new (visible)
	local o = {
		isVisible = true,
		x = love.graphics.getWidth()/4, y = love.graphics.getHeight()/4,
		w = love.graphics.getWidth()/2, h = love.graphics.getHeight()/2,
		rootContainer = nil
	}

	if visible then
		o.isVisible = visible
	end

	setmetatable (o, {__index=self})

	return o
end

function Window:render ()
	if not self.isVisible then
		return
	end

	iScissor:setScissor(self.x, self.y, self.w, self.h)

	love.graphics.setColor (30,40,50,255)
	love.graphics.rectangle ('fill', self.x, self.y, self.w, self.h)

	self.rootContainer:render()
end

function Window:close ()
	self.closed = true
end

function Window:update ()
	if not self.isVisible then
		return
	end

	self.rootContainer.x = self.x
	self.rootContainer.y = self.y+24
	self.rootContainer.w = self.w
	self.rootContainer.h = self.h-24

	self.rootContainer:update()
end

local function addWindow (window)
	table.insert (windows, 1, window)
	
	focusedWindow = window

	return true
end
Module.addWindow = addWindow

local function render ()
	local w

	for w=#windows, 1, -1 do
		if windows[w].isVisible then
			windows[w]:render()
		end
	end
end
Module.render = render

local function update ()
	local w

	for w=1, #windows do
		if windows[w] then
			if windows[w].isVisible then
				windows[w]:update()
			end

			if windows[w].closed then
				table.remove (windows, w)
				w = w-1
			end
		end
	end	
end
Module.update = update

local function mouseDown (x, y, button)
	local w

	for w=1, #windows do
		if windows[w]:mouseDown(x, y, button) then
			if windows[w] ~= focusedWindow then
				gui.bringUp(w)
			end
			break
		end
	end
end
Module.mouseDown = mouseDown

local function mouseUp (x, y, button)
	local w

	for w=1, #windows do
		if windows[w]:mouseUp(x, y, button) then
			if windows[w] ~= focusedWindow then
				gui.bringUp(w)
			end
			break
		end
	end
end
Module.mouseUp = mouseUp

local function mouseMove (x, y)
	local w

	for w=1, #windows do
		if windows[w]:mouseMove(x, y) then
			--amiga-like behaviour
			--if windows[w] ~= focusedWindow then
			--	gui.bringUp(w)
			--end
			break
		end
	end
end
Module.mouseMove = mouseMove

local function bringUp (w)
	local window = windows[w]

	table.remove(windows,w)
	table.insert(windows, 1, window)

	focusedWindow = window
end
Module.bringUp = bringUp

local function setFocus (widget)
	if focusedWidget then
		focusedWidget:unfocus()
	end

	if widget.text then
		widget:focus()

		focusedWidget = widget		
	end
end
Module.setFocus = setFocus

local function keyDown (key, isrepeat)
	if focusedWidget then
		focusedWidget:keyDown (key, isrepeat)
	end
end
Module.keyDown = keyDown

local function keyUp (key)
	if focusedWidget then
		focusedWidget:keyUp (key)
	end
end
Module.keyUp = keyUp

local function input (unicode)
	if focusedWidget then
		focusedWidget:input (unicode)
	end
end
Module.input = input

local function getFocused ()
	return focusedWidget
end
Module.getFocused = getFocused

Module.Widget = Widget
Module.VContainer = VContainer
Module.HContainer = HContainer
Module.Window = Window
Module.windows = windows

return Module
