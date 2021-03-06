include "config"
include "directory"
include "module"
include "tableutil"

animations = {}
animations.list = {}

function animations:init()
	message.setHandler("isAnyPlaying", function(_, loc, ...) if loc then return self:isAnyPlaying() end end)
	message.setHandler("play", function(_, loc, keyFrames) if loc then self:playOverride(keyFrames) end end)
	
	for i,v in pairs(config.animations or {}) do
		self:add(i,v)
	end
end

function animations:update(dt)
	if self.override then 
		if self.override.playing then
			self.override:update(dt)
		else
			self.override = nil
		end
	end

	for i,v in pairs(self.list) do
		self.list[i]:update(dt)
		if v.temporary and not v.playing then
			self.list[i] = nil
		end
	end
end

function animations:uninit()

end

function animations:add(name, keyFrames)
	if type(keyFrames) == "string" then keyFrames = root.assetJson(directory(keyFrames, config.directory or "/")) end
	if not keyFrames then return end
	self.list[name] = module("modules/animation.lua")
	self.list[name]:bindFireEvent(function(name) self:fireEvents(name) end)
	self.list[name]:load(keyFrames)
end

function animations:playOverride(keyFrames)
	if type(keyFrames) == "string" then keyFrames = root.assetJson(directory(keyFrames)) end
	if not keyFrames then return end
	self.override = module("modules/animation.lua")
	self.override:bindFireEvent(function(name) self:fireEvents(name) end)
	self.override:load(keyFrames)
	self.override:play()
end

function animations:isAnyPlaying()
	if self.override and self.override.playing then return true end

	for i,animation in pairs(self.list) do
		if animation.playing then
			return true
		end
	end
	return false
end

function animations:isPlaying(name)
	if self.list[name] then
		return self.list[name].playing
	end
	return false
end

function animations:play(name)
	if self.list[name] then
		self.list[name]:play()
		return true
	end
end

function animations:stop(name)
	if self.list[name] then
		self.list[name]:stop()
	end
end

function animations:stopAll()
	for i,v in pairs(self.list) do
		self.list[i]:stop()
	end
end

function animations:pause(name)
	if self.list[name] then
		self.list[name]:pause()
	end
end

function animations:transforms(animationOrder)
	local transforms = {}
	if self.override then
		return self.override:transforms()
	end
	if animationOrder then
		for _,name in pairs(animationOrder) do
			if self.list[name] and self.list[name].playing then
				transforms = table.vmerge(transforms, self.list[name]:transforms())
			end
		end
	else
		for name,v in pairs(self.list) do
			if v.playing then
				transforms = table.vmerge(transforms, v:transforms())
			end
		end
	end
	return transforms
end

animations._events = {}

function animations:addEvent(name, func)
	self._events[name] = func
end

function animations:fireEvents(name)
	if self._events[name] then
		self._events[name]()
	end
end