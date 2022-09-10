local vim_utils = require("danielws.utils.vim")

local Self = {}

function Self.better_search()
	if vim_utils.is_visual_mode() then
		local search = vim_utils.get_visual_selection({ join_with = "\n" })

		vim.fn.setreg("/", search)
	else
		vim.fn.setreg("/", string.format("\\<%s\\>", vim.fn.expand("<cword>")))
	end

	vim.cmd("set hls")
end

return Self
