local notify = require("danielws.utils.notify")
local file = require("danielws.utils.file")
local input = require("danielws.utils.input")

local Self = { name = "elixir", _current_win = nil }

local function is_test_file(file_path)
	local suffix = "test"

	return string.sub(file_path, -string.len(suffix)) == suffix
end

local function discover_path_by_defmodule()
	local line = vim.fn.search("^.*defmodule", "bcn")

	local path = nil
	local isModule = line ~= 0

	if isModule then
		local line_content = vim.api.nvim_buf_get_lines(0, line - 1, -1, false)
		path = Self.path_by_module_name(line_content[1]:gsub("defmodule", ""):gsub(" do", ""):gsub(" ", ""))
	end

	return path, isModule
end

local function discover_correct_path_for_new_test(file_path)
	local test_path_prefix = ""
	local _, _, namespace_root = string.find(file_path, "^([%w_]+)[_test]?")

	local file_prefix = "test/" .. namespace_root:gsub("_test$", "")

	-- Must add / in search to avoid results as "test/remove_namespace_API/.."
	local ref = file.find(file_prefix .. "/")

	if ref then
		local _, _, ref_path_prefix = string.find(ref, string.format("^(.*)%s", file_prefix))
		test_path_prefix = ref_path_prefix
	end

	return test_path_prefix .. "test/" .. file_path
end

local function create_and_edit(path)
	if file.create(path) then
		-- path = path:gsub("^" .. vim.fn.getcwd() .. "/", "")

		if Self._current_win then
			vim.api.nvim_set_current_win(Self._current_win)
		end

		vim.api.nvim_cmd({ cmd = "edit", args = { path } }, {})
	end
end

local function prompt_create_new_test_file(file_path)
	local path = discover_correct_path_for_new_test(file_path)

	local opt = vim.fn.confirm(string.format("Do you want to create %s?", path), "&Yes\n&No\n&Rename", 2)

	if opt == 1 then
		create_and_edit(path)
		return
	end

	if opt == 3 then
		path = vim.fn.getcwd() .. "/" .. path

		input.popup_prompt("Create new test file", { default = path, callback = create_and_edit })
	end
end

function Self.path_by_module_name(module)
	local result = module
		:gsub("(%u)(%l%w*)", function(a, b)
			return string.lower(a) .. b
		end)
		:gsub("(%l)(%u+)", function(low, up)
			return low .. "_" .. string.lower(up)
		end)
		:gsub("(%u+)(%l)", function(up, low)
			return string.lower(up) .. "_" .. low
		end)
		:gsub("(%u+)", function(up)
			return string.lower(up)
		end)
		:gsub("%.", "/")

	return result
end

function Self.module_name_by_path(file_name)
	local current_file = file_name or vim.fn.expand("%")

	if current_file and current_file ~= "" then
		local cut_at = string.find(current_file, "/lib/")
			or string.find(current_file, "test/")
			or string.find(current_file, "[%a_-]+.?e?x?s?$") - 5

		local mod_name = current_file
			:sub(cut_at + 5)
			:gsub(".ex$", "")
			:gsub(".exs$", "")
			:gsub("/", ".")
			:gsub("(%l)(%w*)", function(a, b)
				return string.upper(a) .. b
			end)
			:gsub("_", "")

		return mod_name
	end

	return "Module"
end

function Self.go_to_test()
	Self._current_win = vim.api.nvim_get_current_win()

	local path, isModule = discover_path_by_defmodule()

	if not isModule then
		notify.warn("Current file isn't a module file", Self)

		return
	end

	if is_test_file(path) then
		local implementation_path = path:gsub("_test$", "") .. ".ex"

		local result = file.recursive_find_and_edit(implementation_path)

		if not result then
			notify.warn(string.format("Couldn't find: [%s]", implementation_path), Self)
		end

		return
	end

	local test_path = path .. "_test.exs"

	if not file.recursive_find_and_edit(test_path) then
		notify.debug(string.format("Couldn't find a test file: [%s]", test_path), Self)

		prompt_create_new_test_file(test_path)
	end
end

return Self
