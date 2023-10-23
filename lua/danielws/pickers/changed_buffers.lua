local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local conf = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local pickers_config = require("danielws.pickers.config")
local previewers = require("telescope.previewers")
local utils = require("telescope.utils")

local Self = {}

-- TODO: this is not working properly
function Self.changed_buffers(opts)
	opts = pickers_config.get_opts(opts)

	local buffers = {}

	for _, buf_info in ipairs(vim.fn.getbufinfo()) do
		if buf_info.changed ~= 0 and vim.api.nvim_buf_get_option(buf_info.bufnr, "modifiable") then
			local flag = buf_info.bufnr == vim.fn.bufnr("") and "%"
				or (buf_info.bufnr == vim.fn.bufnr("#") and "#" or " ")

			local element = {
				bufnr = buf_info.bufnr,
				flag = flag,
				info = buf_info,
			}

			table.insert(buffers, element)
		end
	end

	local displayer = entry_display.create({
		separator = " | ",
		items = {
			{ width = 4 },
			{ width = 4 },
			{ remaining = true },
		},
	})

	local make_display = function(entry)
		local display_bufname = utils.transform_path(opts, entry.filename)

		return displayer({
			{ entry.bufnr, "TelescopeResultsNumber" },
			{ entry.indicator, "TelescopeResultsComment" },
			display_bufname .. ":" .. entry.lnum,
		})
	end

	local delete_buffer = function(prompt_bufnr)
		local current_picker = action_state.get_current_picker(prompt_bufnr)

		current_picker:delete_selection(function(entry)
			if vim.api.nvim_buf_is_valid(entry.bufnr) then
				vim.api.nvim_buf_delete(entry.bufnr, { force = true })
			end
		end)
	end

	local delete_all = function(prompt_bufnr)
		local current_picker = action_state.get_current_picker(prompt_bufnr)

		actions.close(prompt_bufnr)

		for _, entry in ipairs(current_picker.finder.results) do
			if vim.api.nvim_buf_is_valid(entry.bufnr) then
				vim.api.nvim_buf_delete(entry.bufnr, { force = true })
			end
		end
	end

	pickers.new(opts, {
		prompt_title = "Changed Buffers",
		finder = finders.new_table({
			results = buffers,
			entry_maker = function(entry)
				local bufname = entry.info.name == "" and "[No Name]" or entry.info.name
				local hidden = entry.info.hidden == 1 and "h" or "a"
				local readonly = vim.api.nvim_buf_get_option(entry.bufnr, "readonly") and "=" or " "
				local changed = entry.info.changed == 1 and "+" or " "
				local indicator = entry.flag .. hidden .. readonly .. changed
				local line_count = vim.api.nvim_buf_line_count(entry.bufnr)

				return {
					value = bufname,
					ordinal = entry.bufnr .. " : " .. bufname,
					display = make_display,
					bufnr = entry.bufnr,
					filename = bufname,
					lnum = entry.info.lnum ~= 0 and math.max(math.min(entry.info.lnum, line_count), 1) or 1,
					indicator = indicator,
				}
			end,
		}),
		previewer = previewers.new_buffer_previewer({
			title = "Preview changed buffer",
			define_preview = function(self, entry)
				if vim.api.nvim_buf_is_valid(entry.bufnr) and vim.api.nvim_buf_is_valid(self.state.bufnr) then
					local lines = vim.api.nvim_buf_get_lines(entry.bufnr, 0, -1, false)
					local filetype = vim.api.nvim_buf_get_option(entry.bufnr, "filetype")

					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
					vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", filetype)
				end
			end,
		}),
		sorter = conf.generic_sorter(opts),
		attach_mappings = function(_, map)
			map("i", "<c-d>", delete_buffer)
			map("i", "<c-a>", delete_all)

			return true
		end,
	}):find()
end

return Self
