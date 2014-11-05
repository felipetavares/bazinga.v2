local Module = {}

local function dot (v1, v2)
	return v1.x*v2.x + v1.y*v2.y
end
Module.dot = dot

return Module