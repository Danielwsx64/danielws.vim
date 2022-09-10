local vim_utils = require("danielws.utils.vim")

local Self = {}

function Self.better_replace()
	local global_search = "%s"
	local command = ""

	local selected_search, start, finish = vim_utils.get_visual_selection({ join_with = "\n" })

	if selected_search then
		if start[1] == finish[1] then
			command = string.format(
				vim.api.nvim_replace_termcodes(":<C-u>%s/%s//cg<Left><Left><Left>", true, false, true),
				global_search,
				selected_search
			)
		else
			command = vim.api.nvim_replace_termcodes(":s///cg<Left><Left><Left>", true, false, true)
		end
	else
		command = string.format(
			vim.api.nvim_replace_termcodes(":%s/%s//cg<Left><Left><Left>", true, false, true),
			global_search,
			string.format("\\<%s\\>", vim.fn.expand("<cword>"))
		)
	end

	vim.api.nvim_feedkeys(command, "mi", false)
end

return Self
