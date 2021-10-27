function class(protoObj)
	local Class = {}
	Class.__index = Class
	local mt = {}

	function mt.__call(Class, ...)
		local obj = {}

		for key, value in pairs(protoObj or {}) do
			obj[key] = value
		end

		setmetatable(obj, Class)

		if obj.init then
			obj:init(...)
		end

		return obj
	end

	setmetatable(Class, mt)

	return Class
end

return class
