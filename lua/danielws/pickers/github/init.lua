local Job = require("plenary.job")

-- local action_state = require("telescope.actions.state")
-- local actions = require("telescope.actions")
local entry_display = require("telescope.pickers.entry_display")
local conf = require("telescope.config").values
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local pickers_config = require("danielws.pickers.config")
local previewers = require("telescope.previewers")
local previewers_utils = require("telescope.previewers.utils")

local Self = { _name = "GitHub", _icon = "", pull_requests = {} }

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

	local results = {}
	local branch_size = 0
	local id_size = 0

	Self.pull_requests = {}

	for _, pr in ipairs(Job:new({ command = "gh", args = { "pr", "list" } }):sync()) do
		local fields = vim.split(pr, "\t")

		table.insert(results, {
			id = fields[1],
			title = fields[2],
			branch = fields[3],
			status = fields[4],
			datetime = fields[5],
		})

		if #fields[3] > branch_size then
			branch_size = #fields[3]
		end

		if #fields[1] > id_size then
			id_size = #fields[1]
		end
	end

	local displayer = Self.displayer(id_size, branch_size)

	pickers.new(opts, {
		prompt_title = project_name,
		prompt_prefix = " ",
		results_title = "Pull Requests",
		previewer = Self.previewer(),
		finder = finders.new_table({
			results = results,
			entry_maker = function(entry)
				return {
					value = entry,
					ordinal = entry.id .. entry.title .. entry.branch,
					display = Self.make_display_fn(displayer),
				}
			end,
		}),
		sorter = conf.generic_sorter(opts),
	}):find()
end

function Self.make_display_fn(displayer)
	return function(entry)
		local pr = entry.value
		local status_highlight = ({
			["OPEN"] = "TelescopeResultsFunction",
			["DRAFT"] = "TelescopeResultsBorder",
			["CLOSED"] = "TelescopeResultsOperator",
			["MERGED"] = "TelescopeResultsVariable",
		})[pr.status]

		local line = string.format("%s %s", pr.title, pr.datetime)

		return displayer({
			{ "", status_highlight },
			{ string.sub(pr.status or "", 1, 1), status_highlight },
			{ "#" .. pr.id, "TelescopeResultsNumber" },
			{ " " .. pr.branch, "TelescopeResultsConstant" },
			{
				line,
				function()
					local time_start = #pr.title + 1
					local time_end = time_start + #pr.datetime

					return {
						{ { time_start, time_end }, "TelescopeResultsComment" },
					}
				end,
			},
		})
	end
end

function Self.displayer(id_size, branch_size)
	return entry_display.create({
		separator = " ",
		items = {
			{ width = 2 }, -- icon
			{ width = 2 }, -- status
			{ width = id_size + 2 }, -- id/number
			{ width = branch_size + 2 }, -- branch
			{ remaining = true },
		},
	})
end

function Self.pr_key(entry)
	return entry.id .. "/" .. entry.title
end

function Self.previewer()
	return previewers.new_buffer_previewer({
		title = "Pull Request Preview",
		get_buffer_by_name = function(_, entry)
			return Self.pr_key(entry.value)
		end,

		define_preview = function(self, entry, _)
			previewers_utils.job_maker({ "gh", "pr", "view", entry.value.id }, self.state.bufnr, {
				value = Self.pr_key(entry.value),
				bufname = self.state.bufname,
			})

			previewers_utils.highlighter(self.state.bufnr, "markdown")
		end,
	})
end

Self.pr_list()

return Self
