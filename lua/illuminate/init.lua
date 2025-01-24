local M = {}

function M.setup()

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
        print(vim.inspect(cursor_pos))
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
