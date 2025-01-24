local M = {}

function M.setup()
    vim.cmd("highlight g0t4Illuminate gui=underline")

    local ns_id = vim.api.nvim_create_namespace("g0t4_illuminate")
    local hl_group = "g0t4Illuminate"
    local word_chars = "[_%w]"

    local function get_word_bounds(line, cursor_col)
        -- %W == not %w ==> not alphanumeric chars
        -- TODO? treat _ as word char?
        -- find index of end of word after the cursor
        local start_index, end_index = line:find(word_chars .. "+", cursor_col)

        -- find index BEFORE cursor
        local text_before_cursor = line:sub(1, cursor_col)
        local rev_start_idx, rev_end_idx = text_before_cursor:reverse():find(word_chars .. "+")
        -- FYI shouldn't need start_idx b/c it s/b 1 always (always in a word, right?)
        -- what if I am on an = sign... currently underlines: "before = after"
        -- todo failure logic
        if rev_end_idx == nil then
            rev_end_idx = text_before_cursor:len()
        end
        local word_start_idx = cursor_col - rev_end_idx + 1 -- matched char is not word char so +1 to not include it
        -- print(text_before_cursor, " - ", start_index, end_index, " - ", rev_start_idx, rev_end_idx, " - ", word_start_idx)
        if start_index and end_index then
            -- SUPER CRAPPY so far... only works for success case
            return word_start_idx, end_index
        else
            print(
                "unexpected - b/c get_word_bounds - cursor_col is only on a word char so there should never be a failure to find both ways")
            -- FYI get_word_bounds is never called on a non-word char (as cursor col)... so I shouldn't ever have this branch hit
        end
        return nil, nil -- No word found
    end

    vim.cmd("autocmd CursorMoved * lua IlluminateCurrentWord()")
    function IlluminateCurrentWord()
        if vim.bo.filetype == "TelescopePrompt" then
            return
        end

        local current_buffer = 0
        -- clear extmarks first:
        vim.api.nvim_buf_clear_namespace(current_buffer, ns_id, 0, -1)

        -- FYI I REALLY ONLY GOT HAPPY PATH WORKING TO HIGHLIGHT WORD UNDER CURSOR
        local cursor_pos = vim.api.nvim_win_get_cursor(current_buffer)
        local line_0based = cursor_pos[1] - 1
        local col_0based = cursor_pos[2]
        local current_line_text = vim.api.nvim_get_current_line()

        -- *** if not on a word, then no highlights
        local current_char = current_line_text:sub(col_0based + 1, col_0based + 1)
        if not current_char:find(word_chars) then
            return
        end

        local start_idx, end_idx = get_word_bounds(current_line_text, col_0based + 1)
        if not end_idx then
            -- IIUC this can't happen b/c it would just be start_idx = end_idx (if all non-whitespace after cursor on the line, otherwise if there is more to the word it will be found (or even if end of line)
            print(
                "shouldn't happen - find failed to find non-word char from cursor position onward (shouldn't fail b/c cursor is a word char")
            -- could happen if I change pattern and don't get that updated everywhere consistenlty, i.e. too add _ as word char
            return
        end

        -- search rest of buffer for the same word
        local search_pattern = current_line_text:sub(start_idx, end_idx)

        local positions = {}                                  -- Store positions of matches
        local start_line = 0                                  -- TODO ONLY VISIBLE LINES
        local bufnr = bufnr or vim.api.nvim_get_current_buf() -- TODO pass buffer from event?
        local end_line = vim.api.nvim_buf_line_count(bufnr)
        -- Iterate through lines and find matches
        for line = start_line, end_line - 1 do
            local line_content = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1]
            if line_content then
                local start_col = 1
                while true do
                    -- Find the start and end positions of the exact match (4th arg => false == exact, true = pattern)
                    local s, e = line_content:find(search_pattern, start_col + 1, false)
                    if not s then break end
                    -- Add position to the list (row is 0-based, column is 0-based)
                    table.insert(positions, { line, s - 1 })
                    -- Add an extmark at the position
                    vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, s - 1, {
                        end_col = e,
                        hl_group = hl_group,
                    })
                    start_col = e -- Move past the current match
                end
            end
        end

        vim.api.nvim_buf_set_extmark(current_buffer, ns_id, line_0based, start_idx, {
            end_row = line_0based,
            end_col = end_idx,
            hl_group = hl_group,
        })
    end
end

function M.learn()
    local ns_id = vim.api.nvim_create_namespace("line_highlight")

    vim.cmd("highlight MySuggestion gui=italic guifg=#DDD")
    vim.cmd("highlight MySuggestion2 guifg=#FF0000")
    vim.cmd("highlight MySuggestionSign guifg=#00FF00")
    vim.cmd("highlight MySuggestionNumberCol guifg=#0000FF")
    vim.cmd("highlight MySuggestionLine guibg=#ee9090")


    vim.cmd("autocmd CursorMoved * lua ShowSuggestion()")
    function ShowSuggestion()
        -- NOT IN help windows
        if vim.bo.filetype == "help"
            or vim.bo.filetype == "TelescopePrompt" then
            -- TODO OTHERS
            return
        end
        -- do return end -- stop temp


        local current_buffer = 0
        local cursor_pos = vim.api.nvim_win_get_cursor(current_buffer)
        -- wow, frustrating... cursor_pos has row/line (1 based), column (0 based)
        -- print(vim.inspect(cursor_pos))
        local show_text = "" .. vim.inspect(cursor_pos)
        local line_0based = cursor_pos[1] - 1
        local col_0based = cursor_pos[2]
        show_text = show_text .. " - " .. line_0based .. "," .. col_0based
        vim.api.nvim_buf_clear_namespace(current_buffer, ns_id, 0, -1)
        local col = 10 -- for overlay, this is the col to start
        -- todo check columns of current line
        local current_line_text = vim.api.nvim_get_current_line()
        local current_line_len = string.len(current_line_text)
        if current_line_len < col then
            col = current_line_len
        end

        vim.api.nvim_buf_set_extmark(current_buffer, ns_id, line_0based, col, {
            end_row = line_0based + 1,
            -- hl_group = "MySuggestion",
            virt_text = { { show_text, "MySuggestion" }, { "show more", "MySuggestion2" } },
            --
            -- additional line(s) to show (default below current line)
            virt_lines = { { { "another line below", "MySuggestion" } }, { { "yet anotha", "MySuggestion2" } } },
            -- virt_lines_above = true, -- default=false (below)
            -- virt_lines_leftcol  -- left most col?
            --
            -- sign_text = "d", -- show sign in gutter! (marks line(s) affected by extmark)
            sign_text = "", -- show sign in gutter! (marks line(s) affected by extmark)
            sign_hl_group = "MySuggestionSign",
            -- highlight for (line) number column - btw big signtext can overwrite this in my current config
            -- number_hl_group = "MySuggestionNumberCol",

            -- line_hl_group = "MySuggestionLine", -- highlight rest of line(s) affected
            --
            -- virt_text_pos = "eol", -- eol==default
            virt_text_pos = "overlay", -- over top of text, start at col(umn)
            -- virt_text_pos = "inline", -- in between text, start at col(umn)
            -- virt_text_pos = "right_align", -- like a right prompt
            --
            -- spell = false -- disable spell check in extmarks
            -- url = "http://google.com", -- make clickable link => seems to be for the line(s) affected not the extmarks.. FYI
        })
    end

    -- dont load others below
    return {}
    --
end

-- vim.cmd("highlight MyHighlightLine gui=underline guibg=#ee9090 guifg=#282828")
-- vim.cmd("autocmd CursorMoved * lua HighlightLine()")
-- function HighlightLine()
--     local line = vim.api.nvim_win_get_cursor(0)[1] - 1
--     vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
--     vim.api.nvim_buf_set_extmark(0, ns_id, line, 0, {
--         end_row = line + 1,
--         hl_group = "MyHighlightLine"
--     })
-- end


return M
