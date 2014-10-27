local Module = {}
local images = {}

local function getImage (fileName)
	if images[fileName] then
		return images[fileName]
	else
		print ('cache: '..'loading '..fileName)
		images[fileName] = love.graphics.newImage (fileName)
		images[fileName]:setFilter ('nearest', 'nearest')
		return getImage(fileName);
	end
end
Module.getImage = getImage;

return Module