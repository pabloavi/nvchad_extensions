local M = {}

local chadterms = {
   horizontal = {},
   vertical = {},
   winsize = {vertical=.5, horizontal=.5}
}

local get_cmds = function(direction)
   local get_dims = function()
      local direction_switch = direction == "horizontal"
      local direction_func = direction_switch and vim.api.nvim_win_get_height or vim.api.nvim_win_get_width
      return math.floor(direction_func(0) * chadterms.winsize[direction])
   end
   local dims = {
      horizontal = get_dims(),
      vertical = get_dims(),
   }
   local cmds = {
      horizontal = {
         existing = "rightbelow vsplit",
         new = "botright " .. dims.horizontal .. " split",
         resize = "resize",
      },
      vertical = {
         existing = "rightbelow split",
         new = "botright " .. dims.vertical .. " vsplit",
         resize = "vertical resize",
      },
   }
   return cmds, dims
end

local function on_new_buf(opts)
   local bufs = vim.api.nvim_list_bufs()
   local term_buf_id = bufs[#bufs]
   vim.api.nvim_buf_set_var(term_buf_id, "term_type", opts.direction)
   vim.api.nvim_input "i" --term enter
   return term_buf_id
end

local function on_new_win()
   local wins = vim.api.nvim_list_wins()
   local term_win_id = wins[#wins]
   vim.api.nvim_set_current_win(term_win_id)
   return term_win_id
end
local function spawn(spawn_cmd, type, opts)
   vim.cmd(spawn_cmd)
   return type == "win" and on_new_win() or type == "buf" and on_new_buf(opts)
end

M.new_or_toggle = function(direction, size)
   local window_opts = size or chadterms.winsize[direction]
   local cmds = get_cmds(direction)

   local function new_term()
      local term_win_id = spawn(cmds[direction]["new"], "win")
      local term_buf_id = spawn("term", "buf", {direction=direction})
      chadterms[direction][1] = { win = term_win_id, buf = term_buf_id }
   end

   local function hide_term()
      local term_id = chadterms[direction][1]["win"]
      vim.api.nvim_set_current_win(term_id)
      vim.cmd "hide"
      --no update necessary, win will be invalid on hide
   end

   local function show_term()
      local term_buf_id = chadterms[direction][1]["buf"]
      local term_win_id = spawn(cmds[direction]["new"], "win")
      vim.api.nvim_set_current_buf(term_buf_id)
      vim.api.nvim_input "i" --term enter
      chadterms[direction][1] = { win = term_win_id, buf = term_buf_id }
   end

   local opened = chadterms[direction]
   if not opened or vim.tbl_isempty(opened) then
      new_term()
   elseif vim.api.nvim_win_is_valid(chadterms[direction][1]["win"]) then
      hide_term()
   elseif vim.api.nvim_buf_is_valid(chadterms[direction][1]["buf"]) then
      show_term()
   else
      new_term()
   end
end

local behavior_handler = function(behavior)
   if behavior.close_on_exit then
      vim.cmd "au TermClose * lua vim.api.nvim_input('<CR>')"
   end
   vim.cmd [[ au TermOpen term://* setlocal nonumber norelativenumber | setfiletype terminal ]]
end

local config_handler = function(config)
   behavior_handler(config["behavior"])
   chadterms.winsize["horizontal"] = config.window.split_ratio or .5
   chadterms.winsize["vertical"] = config.window.vsplit_ratio or .5
end

M.init = function()
   local config = require("core.utils").load_config().options.terminal
   config_handler(config)
end

return M
