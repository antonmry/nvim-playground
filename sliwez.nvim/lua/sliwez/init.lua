local M = {}

M.__target_pane = ""

function M.setup(config)
	M.__target_pane = config.target_pane
end

function M.get_wezterm_pane()
	return vim.env.WEZTERM_PANE or ""
end

function M.get_current_pane_info()
	local result = vim.fn.systemlist("wezterm cli list --format=json")
	if vim.v.shell_error == 0 and #result > 0 then
		local json_str = table.concat(result, "\n")
		local ok, panes = pcall(vim.json.decode, json_str)
		if ok then
			local current_pane = M.get_wezterm_pane()
			for _, pane in ipairs(panes) do
				if tostring(pane.pane_id) == current_pane then
					return pane
				end
			end
		end
	end
	return nil
end

function M.get_next_pane_in_tab()
	local result = vim.fn.systemlist("wezterm cli list --format=json")
	if vim.v.shell_error == 0 and #result > 0 then
		local json_str = table.concat(result, "\n")
		local ok, all_panes = pcall(vim.json.decode, json_str)
		if ok then
			local current_pane_id = tonumber(M.get_wezterm_pane())
			local current_pane_info = nil

			-- First, find current pane info to get the tab_id
			for _, pane in ipairs(all_panes) do
				if pane.pane_id == current_pane_id then
					current_pane_info = pane
					break
				end
			end

			if not current_pane_info then
				return nil
			end

			-- Get all panes in the same tab, sorted by pane_id
			local tab_panes = {}
			for _, pane in ipairs(all_panes) do
				if pane.tab_id == current_pane_info.tab_id then
					table.insert(tab_panes, pane)
				end
			end

			-- Sort panes by pane_id to ensure consistent ordering
			table.sort(tab_panes, function(a, b)
				return a.pane_id < b.pane_id
			end)

			-- Find next pane (or wrap around to first if we're at the last)
			for i, pane in ipairs(tab_panes) do
				if pane.pane_id == current_pane_id then
					local next_index = (i % #tab_panes) + 1
					return tab_panes[next_index]
				end
			end
		end
	end
	return nil
end

function M.print_config()
	vim.print(string.format("pane: %s", M.__target_pane))
end

function M.configure_target_pane(pane)
	M.__target_pane = pane
end

local function capture_selected_or_current_lines()
	-- Check if we're currently in visual mode
	local mode = vim.api.nvim_get_mode()
	local current_buffer = vim.api.nvim_get_current_buf()

	if mode.mode == "v" or mode.mode == "V" or mode.mode == "\22" then -- \22 is visual block mode
		-- Visual mode: capture CURRENT selection using proper functions
		-- vim.fn.line("v") gives the line where visual selection started
		-- vim.fn.line(".") gives the current cursor line
		local start_line = vim.fn.line("v")
		local end_line = vim.fn.line(".")

		-- Ensure start_line <= end_line (selection might go backwards)
		if start_line > end_line then
			start_line, end_line = end_line, start_line
		end

		local lines = vim.api.nvim_buf_get_lines(current_buffer, start_line - 1, end_line, false)
		return table.concat(lines, "\n")
	else
		-- Not in visual mode: capture current line
		local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
		local line_text = vim.api.nvim_buf_get_lines(current_buffer, cursor_line - 1, cursor_line, false)[1]
		return line_text or ""
	end
end

local function sleep(milliseconds)
	vim.wait(milliseconds, function()
		return false
	end)
end

local function string_to_char_array(str)
	local char_array = {}
	for i = 1, #str do
		char_array[i] = str:sub(i, i)
	end
	return char_array
end

function M.send_delayed(text, delay)
	-- For wezterm, we simplify the escaping since send-text handles it better
	local arr = string_to_char_array(text)
	for _, char in ipairs(arr) do
		sleep(delay)
		local cmd = string.format('wezterm cli send-text --pane-id %s --no-paste "%s"', M.__target_pane, char)
		vim.fn.systemlist(cmd)
	end
	sleep(delay)
	local cmd = string.format('wezterm cli send-text --pane-id %s --no-paste "\n"', M.__target_pane)
	vim.fn.systemlist(cmd)
end

function M.send(text)
	-- Use wezterm cli send-text with automatic newline
	local cmd = string.format('wezterm cli send-text --pane-id %s --no-paste "%s\n"', M.__target_pane, text)
	vim.fn.systemlist(cmd)
end

function M.send_to_pane(text, pane_id)
	-- Send text to a specific pane ID
	local cmd = string.format('wezterm cli send-text --pane-id %s --no-paste "%s\n"', pane_id, text)
	vim.fn.systemlist(cmd)
end

function M.send_to_next_pane(text)
	-- Send text to the next pane in the current tab
	local next_pane = M.get_next_pane_in_tab()
	if next_pane then
		M.send_to_pane(text, next_pane.pane_id)
		-- vim.print(string.format("Sent to pane %s (%s)", next_pane.pane_id, next_pane.title))
	else
		vim.print("No next pane found in current tab")
	end
end

function M.send_lines()
	local lines = capture_selected_or_current_lines()
	if lines and lines ~= "" then
		M.send(lines)
	else
		vim.print("No lines to send")
	end
end

function M.send_lines_to_next_pane()
	local lines = capture_selected_or_current_lines()
	if lines and lines ~= "" then
		M.send_to_next_pane(lines)
	else
		vim.print("No lines to send")
	end
end

function M.send_lines_with_delay_ms(delay)
	local lines = capture_selected_or_current_lines()
	if lines and lines ~= "" then
		M.send_delayed(lines, delay)
	else
		vim.print("No lines to send")
	end
end

return M
