local vim = vim or {}
local Self = {}

local function path_without_extension(mod_line)
	local result = mod_line
		:gsub("defmodule", "")
		:gsub(" do", "")
		:gsub(" ", "")
		:gsub("(%u)(%w*)", function(a, b)
			return string.lower(a) .. b
		end)
		:gsub("(%u)", function(a)
			return "_" .. string.lower(a)
		end)
		:gsub("%.", "/")

	return result
end

local function is_a_test_file(file_path)
	local suffix = "test"

	return string.sub(file_path, -string.len(suffix)) == suffix
end

local function remove_namespace(path)
	local result = path:gsub("^[%w_]+/", "")
	return result
end

local function ripgrep(file_path)
	return io.popen("rg --files | rg  " .. file_path):read("l")
end

function Self.module_name_by_path(file_name)
	local file = file_name or vim.fn.expand("%")

	if file and file ~= "" then
		local cut_at = string.find(file, "/lib/")
			or string.find(file, "test/")
			or string.find(file, "[%a_-]+.?e?x?s?$") - 5

		local mod_name = file
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
	local line = vim.fn.search("^.*defmodule", "bcn")

	if line == 0 then
		print("Current file is not a module file")
		return
	end

	local line_content = vim.api.nvim_buf_get_lines(0, line - 1, -1, false)

	local path = path_without_extension(line_content[1])

	if is_a_test_file(path) then
		print("Current file is a test file")
		return
	end

	local expected_test_path = path .. "_test.exs"
	local attempts = 0

	repeat
		if attempts > 0 then
			expected_test_path = remove_namespace(expected_test_path)
		end

		local test_file = ripgrep(expected_test_path)

		if test_file then
			vim.cmd("edit " .. test_file)
			return
		end

		attempts = attempts + 1
	until expected_test_path:find("/") == nil

	print("Could not find a test file: " .. expected_test_path)
end

return Self
