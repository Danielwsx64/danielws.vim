local Self = {}

function Self.get_marked_region(mark1, mark2)
	local mode = vim.fn.mode()

	if mode ~= "v" and mode ~= "V" and mode ~= "CTRL-V" then
		return nil
	end

	-- vim.cmd([[visual]])
	vim.fn.feedkeys(":", "nx")

	mark1 = mark1 or "'<"
	mark2 = mark2 or "'>"

	local _, start_row, start_col, _ = unpack(vim.fn.getpos(mark1))
	local _, end_row, end_col, _ = unpack(vim.fn.getpos(mark2))

	if start_row > end_row or (start_row == end_row and start_col > end_col) then
		start_row, end_row = end_row, start_row
		start_col, end_col = end_col, start_col
	end

	return { start_row, start_col }, { end_row, end_col }, mode
end

function Self.get_visual_selection(opts)
	local start, finish, mode = Self.get_marked_region()

	if not start then
		return nil
	end

	local join_with = opts and opts.join_with and opts.join_with or ""

	local lines = vim.fn.getline(start[1], finish[1])

	local n = 0
	for _ in pairs(lines) do
		n = n + 1
	end

	if n <= 0 then
		return nil
	end

	lines[n] = string.sub(lines[n], 1, finish[2])
	lines[1] = string.sub(lines[1], start[2])

	return table.concat(lines, join_with), start, finish, mode
end

function Self.is_visual_mode()
	local mode = vim.api.nvim_get_mode().mode

	return mode == "v" or mode == "V"
end

return Self
