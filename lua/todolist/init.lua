local vim = vim
local function setOptions()
	-- 设置一个fileType，避免使用其他file定义的syntax
	vim.bo.filetype = "TodoList"
	vim.bo.tabstop = 2
	vim.bo.shiftwidth = 2
	vim.bo.autoindent = false
end
local function configHighlight()
	vim.cmd([[
		execute("syntax match vimTodoListsDone '^\\s*󰄲.*'")
		execute("syntax match vimTodoListsNormal '^\\s*󰄱.*'")
		execute("syntax match vimTodoListsTitle '.*󱔲.*'")
		highlight VimTodoListDone guifg=#FFD700 guibg=NONE 
		highlight VimTodoListNormal guifg=red guibg=NONE 
		highlight VimTodoListTitle guifg=green guibg=NONE gui=bold
		highlight link vimTodoListsDone VimTodoListDone
		highlight link vimTodoListsNormal VimTodoListNormal
		highlight link vimTodoListsTitle VimTodoListTitle
	]])
end

function CreateNewItemBelow()
	vim.cmd("normal! o 󰄱 ")
	vim.cmd("startinsert!")
end
function CreateNewItemAbove()
	vim.cmd("normal! O 󰄱 ")
	vim.cmd("startinsert!")
end
function GoToPreviousItem()
	vim.cmd([[
		normal! 0
		silent! exec '?󰄱\|󰄲'
		noh
		normal! 03l
	]])
end
-- 1 done,2 undo,0 error
local function getItemState()
	local curLine = vim.fn.getline(".")
	if string.match(curLine, "^%s*󰄲.*") then
		return 1
	elseif string.match(curLine, "^%s*󰄱.*") then
		return 2
	else
		return 0
	end
end
local function getTitle()
	-- 获取当前是星期几，os.date("%w")返回值为0（星期日）到6（星期六）
	local currentWeekDay = os.date("%w")
	-- 计算当前日期距本周一的天数差异，周日特殊处理为差值为6天（即-6%7=1）
	local daysToMonday = (currentWeekDay - 1) % 7
	-- 计算本周一的时间戳
	local mondayTimeStamp = os.time() - (daysToMonday * 24 * 60 * 60)
	-- -- 获取本周一的日期
	local mondayDate = os.date("*t", mondayTimeStamp)
	local formattedMondayDate = string.format("%04d-%02d-%02d", mondayDate.year, mondayDate.month, mondayDate.day)
	return os.date("󱔲 " .. formattedMondayDate .. " 第%W周")
end
local function getDate()
	local weekDays = {
		["Sunday"] = "星期日",
		["Monday"] = "星期一",
		["Tuesday"] = "星期二",
		["Wednesday"] = "星期三",
		["Thursday"] = "星期四",
		["Friday"] = "星期五",
		["Saturday"] = "星期六",
	}

	-- 获取当前日期信息
	-- 根据当前日期信息中的“星期几”字段获取中文星期
	local englishWeekDay = os.date("%A")
	local chineseWeekDay = weekDays[englishWeekDay]

	-- 输出中文的星期几
	return os.date("[%Y-%m-%d " .. chineseWeekDay .. "]")
end
function CreateTitleAbove()
	vim.cmd("normal! O " .. getTitle())
end
function ToggleItem()
	local itemState = getItemState()
	if itemState == 0 then
		return
	end
	if itemState == 1 then
		-- 切到normal
		local curLine = vim.fn.getline(".")
		vim.fn.setline(".", vim.fn.substitute(curLine, "󰄲.*]", "󰄱", ""))
		-- 挪到最前面
		vim.cmd("m-" .. vim.fn.getcurpos()[2])
	elseif itemState == 2 then
		-- 切到done
		local curLine = vim.fn.getline(".")
		vim.fn.setline(".", vim.fn.substitute(curLine, "󰄱", "󰄲 " .. getDate(), ""))
		-- 挪到第一个DONE上
		local maxLineNum = vim.fn.getpos("$")[1]
		-- TODO
	end
	-- TODO
end
function GoToNextItem()
	vim.cmd([[
		normal! $
		silent! exec '/󰄱\|󰄲'
		noh
		normal! 03l
	]])
end
local function configKeyMap()
	vim.keymap.set("n", "o", ":lua CreateNewItemBelow()<cr>", { buffer = true, silent = true })
	vim.keymap.set("n", "O", ":lua CreateNewItemAbove()<cr>", { buffer = true, silent = true })
	vim.keymap.set("n", "j", ":lua GoToNextItem()<cr>", { buffer = true, silent = true })
	vim.keymap.set("n", "k", ":lua GoToPreviousItem()<cr>", { buffer = true, silent = true })
	vim.keymap.set("n", ";", ":lua ToggleItem()<cr>", { buffer = true, silent = true })
	vim.keymap.set("n", "t", ":lua CreateTitleAbove()<cr>", { buffer = true, silent = true })
end
local function init()
	setOptions()
	configHighlight()
	configKeyMap()
end

local M = {}
function M.setup()
	local augroup = vim.api.nvim_create_augroup("nvim_todo_list", { clear = true })

	vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
		group = augroup,
		pattern = "*.todo.md",
		callback = function()
			init()
		end,
	})
end
return M
