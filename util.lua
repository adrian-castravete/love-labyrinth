local function pconstruct(...)
	local sformat = string.format
	local args = {...}

	local pself = function (a) return tostring(a) end
	local types = {
		userdata = function (a) return "<userdata '" .. tostring(a) .. "'>" end,
		string = function (a) return '"' .. a:gsub('"', '\\"') .. '"' end,
		number = pself,
		boolean = pself,
	}

	local function pwalk(thing, indent)
		local out = ""
		for i=1, indent do
			out = out .. " "
		end

		local ttype = type(thing)
		if ttype == "nil" then
			return "nil"
		end

		for t, fn in pairs(types) do
			if ttype == t then
				return fn(thing)
			end
		end

		if ttype ~= "table" then
			error("Unknown type: " .. ttype, 3)
		end

		local out = ""
		local nind = indent + 1

		if #thing > 0 then
			for i=1, #thing do
				for j=1, nind do
					out = out .. " "
				end
				out = out .. sformat("[%d] = %s,", i, pwalk(thing[i], nind)) .. "\n"
			end
		end

		for k, v in pairs(thing) do
			if type(k) ~= "number" or k < 1 or k > #thing then
				for i=1, nind do
					out = out .. " "
				end
				out = out .. sformat("[%s] = %s,", pwalk(k, nind), pwalk(v, nind)) .. "\n"
			end
		end

		for i=1, indent do
			out = out .. " "
		end

		return sformat("{ -- # = %d\n%s}", #thing, out)
	end

	local out = pwalk(args[1], 0)
	for i=2, #args do
		out = out .. "\t" .. pwalk(args[i], 0)
	end

	return out
end

local function pprint(...)
	print(pconstruct(...))
end

local function pcmap2(map, chars, substituteFn)
	if #map < 1 then return "" end

	local ch = " "
	local ln = "\n"
	if chars then
		if type(chars) == "table" then
			ch = chars[1]
			ln = chars[2] or ln
		else
			ch = chars
		end
	end

	local subFn = substituteFn or pconstruct
	local function line(l)
		local out = ""
		if #l < 1 then return "" end
		out = subFn(l[1])
		for i=2, #l do
			out = out .. ch .. subFn(l[i])
		end
		return out
	end

	local out = line(map[1])
	for i=2, #map do
		out = out .. ln .. line(map[i])
	end
	return out
end

local function pmap2(...)
	print(pcmap2(...))
end

return {
	pconstruct = pconstruct,
	pprint = pprint,
	pcmap2 = pcmap2,
	pmap2 = pmap2,
}