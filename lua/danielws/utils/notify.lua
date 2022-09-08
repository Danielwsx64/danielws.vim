local Self = {}
local plugin_name = "danielws"

local function build_title(mod)
	if mod.name then
		return string.format("%s [%s]", plugin_name, mod.name)
	end

	return plugin_name
end

function Self.info(message, mod)
	vim.notify(message, "info", {
		title = build_title(mod),
	})
end

function Self.warn(message, mod)
	vim.notify(message, "warn", {
		title = build_title(mod),
	})
end

function Self.error(message, mod)
	vim.notify(message, "error", {
		title = build_title(mod),
	})
end

function Self.debug(message, mod)
	vim.notify(message, "debug", {
		title = build_title(mod),
	})
end

return Self
