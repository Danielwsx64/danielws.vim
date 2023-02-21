local notify = require("danielws.utils.notify")

local Self = { _name = "utils.file", _icon = "" }

local function file_exists(path)
	local _, error = vim.loop.fs_stat(path)
	return error == nil
end

local function is_folder(path)
	return string.match(path, "/$") and true or false
end

local function create_file(path)
	local ok, file = pcall(vim.loop.fs_open, path, "w", 420)

	if not ok or file == nil then
		notify.err("Couldn't create file " .. path, Self)

		return false
	end

	vim.loop.fs_close(file)

	notify.info("Created " .. path, Self)
	return true
end

local function create_folder(path)
	local success = vim.loop.fs_mkdir(path, 493)

	if not success then
		notify.err("Couldn't create folder " .. path, Self)

		return false
	end

	return true
end

function Self.create(path)
	local current_path = ""

	for value in string.gmatch(path, "[^/]+/?") do
		current_path = current_path .. value

		if not is_folder(current_path) then
			return create_file(current_path)
		end

		if not file_exists(current_path) then
			return create_folder(current_path)
		end
	end
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
