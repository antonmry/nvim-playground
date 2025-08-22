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

local function capture_highlighted_text()
	-- Get the visual selection using vim.fn.getpos to be more reliable
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")

	local start_line = start_pos[2]
	local start_col = start_pos[3]
	local end_line = end_pos[2]
	local end_col = end_pos[3]

	-- Check if we have a valid selection
	if start_line == 0 or end_line == 0 or (start_line == end_line and start_col == end_col) then
		return nil
	end

	-- Get the current buffer
	local current_buffer = vim.api.nvim_get_current_buf()
	local lines = {}

	-- Handle single line selection
	if start_line == end_line then
		local line_text = vim.api.nvim_buf_get_lines(current_buffer, start_line - 1, start_line, false)[1]
		if line_text then
			-- For single line, extract the selected portion
			line_text = string.sub(line_text, start_col, end_col)
			table.insert(lines, line_text)
		end
	else
		-- Handle multi-line selection
		for line_num = start_line, end_line do
			local line_text = vim.api.nvim_buf_get_lines(current_buffer, line_num - 1, line_num, false)[1]
			if line_text then
				if line_num == start_line then
					-- First line: from start_col to end
					line_text = string.sub(line_text, start_col)
				elseif line_num == end_line then
					-- Last line: from start to end_col
					line_text = string.sub(line_text, 1, end_col)
				end
				-- Middle lines: take entire line
				table.insert(lines, line_text)
			end
		end
	end

	return table.concat(lines, "\n")
end

local function capture_paragraph_text()
	local current_buffer = vim.api.nvim_get_current_buf()
	local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
	local start_line, end_line = cursor_line, cursor_line
	while start_line > 0 do
		local line = vim.api.nvim_buf_get_lines(current_buffer, start_line - 1, start_line, false)[1]
		if line == "" then
			break
		end
		start_line = start_line - 1
	end
	local total_lines = vim.api.nvim_buf_line_count(current_buffer)
	while end_line < total_lines do
		local line = vim.api.nvim_buf_get_lines(current_buffer, end_line, end_line + 1, false)[1]
		if line == "" then
			break
		end
		end_line = end_line + 1
	end
	local paragraph_lines = vim.api.nvim_buf_get_lines(current_buffer, start_line, end_line, false)
	local paragraph_text = table.concat(paragraph_lines, "\n")
	return paragraph_text
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
		vim.print(string.format("Sent to pane %s (%s)", next_pane.pane_id, next_pane.title))
	else
		vim.print("No next pane found in current tab")
	end
end

function M.send_highlighted_text()
	local hl = capture_highlighted_text()
	if hl and hl ~= "" then
		M.send(hl)
	else
		vim.print("No text highlighted or selection is empty")
	end
end

function M.send_paragraph_text()
	local para = capture_paragraph_text()
	M.send(para)
end

function M.send_highlighted_text_to_next_pane()
	local hl = capture_highlighted_text()
	if hl and hl ~= "" then
		M.send_to_next_pane(hl)
	else
		vim.print("No text highlighted or selection is empty")
	end
end

function M.send_paragraph_text_to_next_pane()
	local para = capture_paragraph_text()
	M.send_to_next_pane(para)
end

function M.send_highlighted_text_with_delay_ms(delay)
	local hl = capture_highlighted_text()
	M.send_delayed(hl, delay)
end

function M.send_paragraph_text_with_delay_ms(delay)
	local para = capture_paragraph_text()
	M.send_delayed(para, delay)
end

return M
