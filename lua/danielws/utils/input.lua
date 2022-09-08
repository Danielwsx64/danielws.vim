local utils = require("danielws.utils")
local popup = require("plenary.popup")

local Self = { _windows = {}, _callbacks = {} }

local function get_border_win(winnr)
	return Self._windows[winnr].border_win
end

local function set_border_win(winnr, border_win)
	Self._windows[winnr] = { border_win = border_win }
end

local function execute_callback(winnr)
	if Self._callbacks[winnr] then
		Self._callbacks[winnr]()
	end
end

function Self._close(winnr)
	local border_win = get_border_win(winnr)

	local bufnr = vim.api.nvim_win_get_buf(winnr)

	vim.api.nvim_win_close(winnr, true)

	if vim.api.nvim_win_is_valid(border_win) then
		vim.api.nvim_win_close(border_win, true)
	end

	Self._windows[winnr] = {}

	if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
		vim.api.nvim_buf_delete(bufnr, { force = true })
	end
end

function Self._close_with_callback(winnr)
	execute_callback(winnr)
	Self._close(winnr)
end

-- opts
--   default: value to start prompt
--   callback: fn to run on exit/enter

function Self.popup_prompt(title, opts)
	opts = opts or {}

	local default = opts.default or ""
	local minwidth = string.len(title) > string.len(default) and string.len(title) + 8 or string.len(default) + 1

	local winnr, popup_ids = popup.create(default, {
		title = title,
		borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
		enter = true,
		wrap = true,
		padding = { 0, 0, 1, 0 },
		minwidth = minwidth,
	})

	set_border_win(winnr, popup_ids and popup_ids.border and popup_ids.border.win_id)

	if opts.callback then
		local bufnr = vim.api.nvim_win_get_buf(winnr)

		Self._callbacks[winnr] = function()
			local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]

			opts.callback(line and utils.trim(line))
		end

		local callback = '<ESC><CMD>lua require"danielws.utils.input"._close_with_callback(' .. winnr .. ")<CR>"
		local close = '<ESC><CMD>lua require"danielws.utils.input"._close(' .. winnr .. ")<CR>"

		vim.api.nvim_buf_set_keymap(bufnr, "n", "<CR>", callback, { noremap = true })
		vim.api.nvim_buf_set_keymap(bufnr, "i", "<CR>", callback, { noremap = true })

		vim.api.nvim_buf_set_keymap(bufnr, "n", "<ESC>", close, { noremap = true })
		vim.api.nvim_buf_set_keymap(bufnr, "n", "q", close, { noremap = true })
		vim.api.nvim_buf_set_keymap(bufnr, "n", "Q", close, { noremap = true })
	end

	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ESC>A", true, false, true), "n", false)
end

return Self
