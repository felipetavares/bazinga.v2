		local box = {
			x = self.object.properties.x,
			y = self.object.properties.y,
			w = self.object.properties.w,
			h = self.object.properties.h
		}
		local o,l
		for l=1, #self.level.data.layers do
			if self.level.data.layers[l].active then
				for o=1, #self.level.data.layers[l].data do
					if self.level.data.layers[l].data[o] ~= self.object then
						--[=[if boxCollide(self.level.data.layers[l].data[o], box) then
							local dx1 = (self.object.properties.x+self.object.properties.w)-(self.level.data.layers[l].data[o].properties.x)
							local dx2 = (self.level.data.layers[l].data[o].properties.x+self.level.data.layers[l].data[o].properties.w)-(self.object.properties.x)
							local dy1 = (self.object.properties.y+self.object.properties.h)-(self.level.data.layers[l].data[o].properties.y)
							local dy2 = (self.level.data.layers[l].data[o].properties.y+self.level.data.layers[l].data[o].properties.h)-(self.object.properties.y)
							local dx,dy

							if dx1 > dx2 then
								dx = dx2
							else
								dx = dx1
							end

							if dy1 > dy2 then
								dy = dy2
							else
								dy = dy1
							end

							-- snap to border
							--[=[if math.abs(dx) < math.abs(dy) then
								self.object.properties.y = self.level.data.layers[l].data[o].properties.y
								if dx1 < dx2 then
									self.object.properties.x = self.level.data.layers[l].data[o].properties.x-self.object.properties.w
								else
									self.object.properties.x = self.level.data.layers[l].data[o].properties.x+self.level.data.layers[l].data[o].properties.w
								end
							else
								self.object.properties.x = self.level.data.layers[l].data[o].properties.x
								if dy1 < dy2 then
									self.object.properties.y = self.level.data.layers[l].data[o].properties.y-self.object.properties.h
								else
									self.object.properties.y = self.level.data.layers[l].data[o].properties.y+self.level.data.layers[l].data[o].properties.h
								end					
							end
							--]=]

							-- snap to internal border
							--[=[
							if math.abs(dx) < math.abs(dy) then																
								if dx1 < dx2 then
									if dx == dx1 then
										if dy1 < dy2 then
											self.object.properties.y = self.level.data.layers[l].data[o].properties.y
										else
											self.object.properties.y = self.level.data.layers[l].data[o].properties.y+self.level.data.layers[l].data[o].properties.h-self.object.properties.h
										end
									else
										if dy1 > dy2 then
											self.object.properties.y = self.level.data.layers[l].data[o].properties.y
										else
											self.object.properties.y = self.level.data.layers[l].data[o].properties.y+self.level.data.layers[l].data[o].properties.h-self.object.properties.h
										end
									end									

									self.object.properties.x = self.level.data.layers[l].data[o].properties.x-self.object.properties.w
								else
									if dx == dx2 then
										if dy1 < dy2 then
											self.object.properties.y = self.level.data.layers[l].data[o].properties.y
										else
											self.object.properties.y = self.level.data.layers[l].data[o].properties.y+self.level.data.layers[l].data[o].properties.h-self.object.properties.h
										end
									else
										if dy1 > dy2 then
											self.object.properties.y = self.level.data.layers[l].data[o].properties.y
										else
											self.object.properties.y = self.level.data.layers[l].data[o].properties.y+self.level.data.layers[l].data[o].properties.h-self.object.properties.h
										end
									end									

									self.object.properties.x = self.level.data.layers[l].data[o].properties.x+self.level.data.layers[l].data[o].properties.w
								end
							else
								if dy1 < dy2 then
									if dy == dy1 then
										if dx1 < dx2 then
											self.object.properties.x = self.level.data.layers[l].data[o].properties.x
										else
											self.object.properties.x = self.level.data.layers[l].data[o].properties.x+self.level.data.layers[l].data[o].properties.w-self.object.properties.w
										end
									else
										if dx1 > dx2 then
											self.object.properties.x = self.level.data.layers[l].data[o].properties.x
										else
											self.object.properties.x = self.level.data.layers[l].data[o].properties.x+self.level.data.layers[l].data[o].properties.w-self.object.properties.w
										end
									end									

									self.object.properties.y = self.level.data.layers[l].data[o].properties.y-self.object.properties.h
								else
									if dy == dy2 then
										if dx1 < dx2 then
											self.object.properties.x = self.level.data.layers[l].data[o].properties.x
										else
											self.object.properties.x = self.level.data.layers[l].data[o].properties.x+self.level.data.layers[l].data[o].properties.w-self.object.properties.w
										end
									else
										if dx1 > dx2 then
											self.object.properties.x = self.level.data.layers[l].data[o].properties.x
										else
											self.object.properties.x = self.level.data.laxers[l].data[o].properties.x+self.level.data.laxers[l].data[o].properties.w-self.object.properties.w
										end
									end									

									self.object.properties.y = self.level.data.layers[l].data[o].properties.y+self.level.data.layers[l].data[o].properties.h
								end					
							end
							--/=]

							break
						end
						--]=]
					end
				end
			end
		end