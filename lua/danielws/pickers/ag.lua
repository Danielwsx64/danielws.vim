local Job = require("plenary.job")
local conf = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local pickers_config = require("danielws.pickers.config")

local Self = { _name = "Ag", _icon = "" }

local MAX_PATH_LENGTH = 25

function Self.search(...)
	local ag_search = string.gsub(table.concat({ ... }, " "), "%A", function(c)
		return "\\" .. c
	end)

	Self.ag_pick({ ag_search = ag_search })
end

function Self.ag_pick(opts)
	local picker_opts = pickers_config.get_opts(opts)
	local results = Self.silver_search(opts.ag_search)

	local displayer = Self.displayer()

	pickers.new(picker_opts, {
		prompt_title = "Ag result:",
		finder = finders.new_table({
			results = results,
			entry_maker = function(entry)
				return {
					value = entry,
					ordinal = entry.path .. " " .. entry.content,
					display = Self.make_display_fn(displayer),
					filename = entry.path,
					path = vim.loop.fs_realpath(entry.path),
					lnum = entry.line_number,
				}
			end,
		}),
		previewer = conf.grep_previewer(picker_opts),
		sorter = conf.file_sorter(picker_opts),
	}):find()
end

function Self.silver_search(search)
	local results = {}
	local ag_command = Job:new({ command = "ag", args = { search } })

	ag_command:sync()

	for _, line in ipairs(ag_command:result()) do
		local line_components = vim.split(line, ":")

		local entry = {
			path = line_components[1],
			line_number = tonumber(line_components[2]),
			content = table.concat({ unpack(line_components, 3) }, ":"),
			path_length = string.len(line_components[1]),
		}

		table.insert(results, entry)
	end

	return results
end

function Self.make_display_fn(displayer)
	return function(entry)
		local path = entry.value.path_length <= MAX_PATH_LENGTH and entry.value.path
			or "…" .. string.sub(entry.value.path, -MAX_PATH_LENGTH + 2)

		return displayer({
			{ path, "TelescopeResultsVariable" },
			{ entry.value.content },
		})
	end
end

function Self.displayer()
	return entry_display.create({
		separator = " ",
		items = { { width = MAX_PATH_LENGTH }, { remaining = true } },
	})
end

return Self
