local Job = require("plenary.job")

local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local conf = require("telescope.config").values
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local pickers_config = require("danielws.pickers.config")

local Self = { _name = "GitHub", _icon = "" }

function Self.pr_list(opts)
	opts = pickers_config.get_opts(opts)

	local project_name = "Repository"

	local remote_url = Job:new({ command = "git", args = { "config", "remote.origin.url" } }):sync()

	if remote_url and remote_url[1] then
		local user, repo = string.match(remote_url[1], "([%w%.%-_]*)/([%w%.%-_]*)%.git$")

		if user and repo then
			project_name = user .. "/" .. repo
		end
	end

	pickers.new(opts, {
		prompt_title = project_name,
		prompt_prefix = "",
		results_title = "Pull Requests",
		finder = finders.new_oneshot_job({ "gh", "pr", "list" }, opts),
		sorter = conf.generic_sorter(opts),
	}):find()
end

Self.pr_list()

return Self
