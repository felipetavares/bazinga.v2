-- Heap Sort implementation
-- Copyright (C) 2014 by Felipe Tavares
-- This is a very didatic and readable implementation
-- but this maybe changed in the future for a best
-- eficiency

local Module = {}

-- Basic heap functions
function r (heap, heapsize, node)
	local v = 2*node+1
	if v <= heapsize then
		return heap[v]
	else 
		return -1
	end
end

function l (heap, heapsize, node)
	local v = 2*node
	if v <= heapsize then
		return heap[v]
	else 
		return -1
	end
end

function rs (node)
	return 2*node+1
end

function ls (node)
	return 2*node
end

function p (node)
	return math.floor (node/2)
end

function defaultOrder (x, y)
	return x > y
end

-- Heapfy (sometimes called 'sink')
function heapHeapfy (heap, heapsize, root)
	local buffer
	local lc
	
	-- Picks the largest child
	if Module.order(r(heap, heapsize, root), l(heap, heapsize, root)) then
		lc = rs(root)
	else
		lc = ls(root)
	end

	-- If we do have children
	if lc <= heapsize then
		-- Compares the largest child to myself, if greater, swap
		if Module.order(heap[lc],heap[root]) then
			buffer = heap[root]
			heap[root] = heap[lc]
			heap[lc] = buffer
			
			heapHeapfy(heap, heapsize, lc)
		end
	end
end

-- Build Heap
function heapBuild (heap, heapsize)
	heapsize = #heap
	local i
	for i=math.floor(#heap/2),1,-1 do
		heapHeapfy(heap, heapsize, i)
	end
	return heapsize
end

-- Heapsort
function heapSort (array)
	local i,buffer, heapsize

	heapsize = heapBuild(array, heapsize)
	for i=#array,2,-1 do
		-- Swap Ai with A1
		buffer = array[i]
		array[i] = array[1]
		array[1] = buffer

		heapsize = heapsize - 1

		heapHeapfy(array, heapsize, 1)
	end
end

Module.sort = heapSort
Module.order = defaultOrder

return Module