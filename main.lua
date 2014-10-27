function love.load ()
	print ('bazinga.v2')

	--love.window.setMode(0, 0, {fullscreen=true, resizable=false})
	love.window.setMode(800, 600, {fullscreen=false, resizable=true})

	-- Fast terminal out
	io.stdout:setvbuf("no")

	print ('loading modules...')
	-- JSON module [EXTERNAL]
	json 	= love.filesystem.load('dkjson.lua')()
	-- UTF8 module [EXTERNAL]
	utf8 	= love.filesystem.load('utf8.lua')()
	
	-- Modules from bazinga itself
	gui 	= love.filesystem.load('gui.lua')()
	camera  = love.filesystem.load('camera.lua')()
	level 	= love.filesystem.load('level.lua')()
	code 	= love.filesystem.load('code.lua')()
	editor 	= love.filesystem.load('editor.lua')()
	cache 	= love.filesystem.load('cache.lua')()
	heap	= love.filesystem.load('sort.lua')()

	love.graphics.setFont (
		love.graphics.newFont("Schoolbell.ttf", 16)
	)

	print ('setting window title...')
	love.window.setTitle ('bazinga.v2')

	print ('running user startup code...')
	code.begin()
end

function love.update ()
	code.update()
end

function love.draw ()
	code.render()
end

-- Helper
function table.invert(t)
  local u = { }
  for k, v in pairs(t) do u[v] = k end
  return u
end