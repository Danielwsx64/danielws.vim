local notify = require("danielws.utils.notify")

local Self = { _name = "utils.file", _icon = "" }

function Self.create(path)
	local ok, file = pcall(vim.loop.fs_open, path, "w", 420)

	if not ok or file == nil then
		notify.err("Couldn't create file " .. path, Self)

		return false
	end

	vim.loop.fs_close(file)

	notify.info("Created " .. path, Self)
	return true
end

local function remove_namespace(path)
	local result = path:gsub("^[%w_]+/", "")
	return result
end

function Self.find_file(search)
	local result = io.popen("rg --files | rg  " .. search):read("l")
	return result
end

function Self.find(search)
	local result = io.popen("rg -l " .. search):read("l")
	return result
end

function Self.find_and_edit(search)
	local found = Self.find(search)

	if found then
		vim.cmd("edit " .. found)
		return true
	end

	return false
end

function Self.find_file_and_edit(search_path)
	local found = Self.find_file(search_path)

	if found then
		vim.cmd("edit " .. found)
		return true
	end

	return false
end

function Self.recursive_find_file_and_edit(search_path)
	local current_search = search_path
	local should_retry = true

	repeat
		local found = Self.find_file(current_search)

		if found then
			vim.cmd("edit " .. found)
			return true
		end

		if current_search:find("/") == nil then
			should_retry = false
		else
			current_search = remove_namespace(current_search)
		end

	until should_retry == false

	return false
end

return Self
