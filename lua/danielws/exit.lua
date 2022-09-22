local notify = require("danielws.utils.notify")

local Self = { _name = "Exit", _icon = "" }

local function close_if_needed(_)
	return true
	-- if buf_info.listed == 0 or not (vim.api.nvim_buf_get_option(buf_info.bufnr, "modifiable")) then
	-- 	vim.api.nvim_buf_delete(buf_info.bufnr, {})
	-- end
end

function Self.close_session()
	vim.cmd("DeleteSession")
	vim.cmd("qa!")
end

function Self.quit_all()
	local has_changed_bufs = false

	for _, buf_info in ipairs(vim.fn.getbufinfo()) do
		if buf_info.changed == 0 then
			close_if_needed(buf_info)
		else
			has_changed_bufs = true
		end
	end

	if has_changed_bufs then
		if vim.fn.getbufinfo(vim.api.nvim_get_current_buf())[1].changed ~= 0 then
			vim.cmd("tabnew")
		end

		notify.warn("Unsaved opened buffers. Close then first.", Self)
		vim.cmd("Telescope danielws changed_buffers")
		return
	end

	vim.cmd("qa")
end

return Self
