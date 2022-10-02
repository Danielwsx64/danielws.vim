local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local conf = require("telescope.config").values
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local pickers_config = require("danielws.pickers.config")

local tmux_runner = require("danielws.tmux_runner")

local Self = { _name = "ShellCommand", _icon = "" }

local function use_selected(prompt_bufnr)
	local current_picker = action_state.get_current_picker(prompt_bufnr)
	local selection = current_picker:get_selection()

	if selection and selection[1] then
		current_picker:set_prompt(selection[1])
	end
end

local function run_with_vtr(prompt_bufnr)
	local current_picker = action_state.get_current_picker(prompt_bufnr)
	local selection = current_picker:get_selection()

	if selection and selection[1] then
		tmux_runner.send_command(selection[1])

		actions.close(prompt_bufnr)
	end
end

local function run_from_prompt(prompt_bufnr)
	local current_picker = action_state.get_current_picker(prompt_bufnr)
	local command = current_picker:_get_prompt()

	if command ~= "" then
		tmux_runner.send_command(command)

		actions.close(prompt_bufnr)
	end
end

function Self.history(opts)
	opts = pickers_config.get_opts(opts)

	pickers.new(opts, {
		prompt_title = "Shell commands",
		prompt_prefix = "  ",
		results_title = "History",
		finder = finders.new_oneshot_job({ "tac", "/home/daniel/.zhistory" }, opts),
		sorter = conf.generic_sorter(opts),
		attach_mappings = function(_, map)
			map("i", "<c-l>", use_selected)
			map("i", "<c-p>", run_from_prompt)
			map("i", "<tab>", actions.move_selection_next)
			map("i", "<s-tab>", actions.move_selection_previous)

			actions.select_default:replace(run_with_vtr)
			actions.select_tab:replace(run_with_vtr)
			actions.select_vertical:replace(run_with_vtr)
			actions.select_horizontal:replace(run_with_vtr)

			return true
		end,
	}):find()
end

return Self
