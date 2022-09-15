local notify = require("danielws.utils.notify")
local file = require("danielws.utils.file")
local input = require("danielws.utils.input")
local vim_utils = require("danielws.utils.vim")
local pipelize = require("danielws.elixir.pipelize")

local Self = { _name = "elixir", _icon = "", _current_win = nil }

local function is_test_module(file_path)
	local suffix = "Test"

	return string.sub(file_path, -string.len(suffix)) == suffix
end

local function get_module_name_and_path()
	local line = vim.fn.search("^.*defmodule", "bcn")

	if line ~= 0 then
		local line_content = vim.api.nvim_buf_get_lines(0, line - 1, -1, false)
		local module_name = string.match(line_content[1], "^%s*defmodule%s*([%w%.]+)%s*do")
		local path = Self.path_by_module_name(module_name)

		return module_name, path
	end

	return nil
end

local function add_defmodule(module_name)
	return string.format("'defmodule %s do'", module_name)
end

local function discover_correct_path_for_new_test(file_path)
	local test_path_prefix = ""
	local _, _, namespace_root = string.find(file_path, "^([%w_]+)[_test]?")

	local file_prefix = "test/" .. namespace_root:gsub("_test$", "")

	-- Must add / in search to avoid results as "test/remove_namespace_API/.."
	local ref = file.find_file(file_prefix .. "/")

	if ref then
		local _, _, ref_path_prefix = string.find(ref, string.format("^(.*)%s", file_prefix))
		test_path_prefix = ref_path_prefix
	end

	return test_path_prefix .. "test/" .. file_path
end

local function create_and_edit(path)
	if file.create(path) then
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

	local module_name, module_path = get_module_name_and_path()

	if not module_name then
		notify.warn("Current file isn't a module file", Self)

		return
	end

	if is_test_module(module_name) then
		if not file.find_and_edit(add_defmodule(module_name:gsub("Test$", ""))) then
			notify.warn(string.format("Couldn't find: [%s]", module_name), Self)
		end

		return
	end

	local test_module = string.format("%sTest", module_name)

	if not file.find_and_edit(add_defmodule(test_module)) then
		notify.debug(string.format("Couldn't find a test module: [%s]", test_module), Self)

		prompt_create_new_test_file(string.format("%s_test.exs", module_path))
	end
end

function Self.pipelize()
	local lines, start, finish, mode = vim_utils.get_visual_selection()

	local success, result = pcall(pipelize.into_pipe, lines)

	if not success then
		notify.err(string.format("Fail to pipelize:\n %s", vim.inspect(result)), Self)

		return
	end

	if mode == "V" then
		vim.api.nvim_buf_set_lines(0, start[1] - 1, finish[1], false, { result })
		return
	end

	vim.api.nvim_buf_set_text(0, start[1] - 1, start[2] - 1, finish[1] - 1, finish[2], { result })
end

return Self
