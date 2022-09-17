local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local conf = require("telescope.config").values
local finders = require("telescope.finders")
local notify = require("danielws.utils.notify")
local pickers = require("telescope.pickers")
local themes = require("telescope.themes")

local Self = { _name = "CoAuthors", _icon = "" }

local function apply_co_authors(selection)
	local co_authors = {}

	for _, entry in ipairs(selection) do
		table.insert(co_authors, "Co-authored-by: " .. entry[1])
	end

	local position = vim.api.nvim_win_get_cursor(0)
	vim.api.nvim_buf_set_lines(0, position[1], position[1], false, co_authors)
end

local function attach_mappings(prompt_bufnr, _)
	actions.select_default:replace(function()
		local selection = action_state.get_current_picker(prompt_bufnr):get_multi_selection()

		actions.close(prompt_bufnr)

		apply_co_authors(selection)
	end)

	return true
end

function Self.co_authors(opts)
	opts = themes.get_ivy(opts or {})

	local results = {}
	local output = io.popen("git shortlog -sen")

	for line in output:lines() do
		local author, _ = line:gsub("^.*\t", "")
		table.insert(results, author)
	end

	if next(results) == nil then
		notify.warn("No authors found", Self)

		return
	end

	pickers.new(opts, {
		prompt_title = "Co-Authors:",
		finder = finders.new_table({ results = results }),
		sorter = conf.generic_sorter(opts),
		attach_mappings = attach_mappings,
	}):find()
end

return Self
