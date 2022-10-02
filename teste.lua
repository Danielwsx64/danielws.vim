-- local line = string.format("tmux %s", command)
--
-- if target_pane then
-- 	line = string.format("%s -t%s", line, target_pane)
-- end
--
-- return io.popen(line):lines()
-- local Job = require("plenary.job")
--
-- local job = Job:new({ "tac", "/home/daniel/.zshistory" })
--
-- job:sync()
--
--
-- print(vim.inspect(job:result()))
local pattern = "([%w%.%-_]*)/([%w%.%-_]*)%.git$"

local user, repo = string.match("git@github.com:Danielwsx64/danielws.vim.git", pattern)
local user1, repo1 = string.match("https://github.com/pwntester/octo.nvim.git", pattern)

print(user)
print(repo)
print(user1)
print(repo1)
