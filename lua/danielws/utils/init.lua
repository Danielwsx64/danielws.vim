local Self = { _name = "utils" }

function Self.trim(txt)
	return txt:gsub("^%s*", ""):gsub("%s*$", "")
end

return Self
