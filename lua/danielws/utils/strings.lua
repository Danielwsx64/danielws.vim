local Self = {}
local function str_scape(str)
	return "'" .. str .. "'"
end

function Self.shell_escape(str)
	return str_scape(string.gsub(str, "'", "'\\''"))
end

return Self
