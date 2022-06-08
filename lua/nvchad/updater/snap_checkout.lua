local function snap_checkout()
   -- in all the comments below, config means user config
   local utils = require "nvchad"
   local git = require 'nvchad.updater.utils.git'
   local misc = require 'nvchad.updater.utils.misc'
   local prompts = require 'nvchad.updater.utils.prompts'
   local echo = utils.echo
   local current_branch_name = git.get_current_branch_name()

   -- return if we are already on a snapshot branch
   -- if current_branch_name:match(base_snap_branch_name .. "(.+)" .. "$") then
   --    echo(misc.list_text_replace(prompts.already_on_snapshot_branch, "<SNAP_NAME>",
   --       current_branch_name))
   --    return
   -- end

   echo({ { "Checking out snapshot..." } })
end

return snap_checkout
