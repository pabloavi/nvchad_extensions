local function snap_create()
   local utils = require "nvchad"
   local git = require 'nvchad.utils.git'
   local misc = require 'nvchad.utils.misc'
   local defaults = require 'nvchad.utils.config'
   local prompts = require 'nvchad.utils.prompts'
   local echo = utils.echo
   local config_stash_name = defaults.snaps.base_config_stash_name .. os.date("%Y-%m-%d_%H:%M:%S_%z")
   local current_branch_name = git.get_current_branch_name()

   -- return if we are already on a snapshot branch
   if current_branch_name:match(defaults.snaps.base_snap_branch_name .. "(.+)" .. "$") then
      echo(misc.list_text_replace(prompts.already_on_snapshot_branch, "<SNAP_NAME>",
         current_branch_name))
      return
   end

   -- check if we are on the correct update branch, if not, switch to it
   if not git.checkout_branch(git.update_branch) then
      return
   end

   -- get the name of the snap
   echo(prompts.snapshot_enter_name)
   local name = string.lower(vim.fn.input("-> "));

   misc.print_padding("\n", 2)

   if name == "a" then
      return
   end

   local branch_name = defaults.snaps.base_snap_branch_name .. misc.replace_whitespaces(name)

   -- create a backup of the current custom dir in the stash if it exists
   if git.add('"' .. defaults.custom.config_dir .. '"', '-f') then
      echo(misc.list_text_replace(prompts.stashing_custom_dir, "<STASH_NAME>", config_stash_name))

      git.stash('store', '"$(git stash create ' .. defaults.custom.config_dir
         .. ')"', '-m ' .. config_stash_name)
      git.restore("--staged", defaults.custom.config_dir)
   end

   -- drop old config backup stash entries
   git.stash_action_for_entry_by_name('drop', defaults.snaps.base_config_stash_name, 4)

   -- check if the branch already exists
   while git.checkout_branch(branch_name, true) do

      echo(misc.list_text_replace(prompts.branch_already_exists, "<BRANCH_NAME>", branch_name))
      name = string.lower(vim.fn.input("-> "));

      misc.print_padding("\n", 2)

      if name == "o" then
         if not git.checkout_branch(git.update_branch) then return end
         if not git.stash("apply") then return end
         if not git.delete_branch(branch_name) then return end
         echo(misc.list_text_replace(prompts.branch_deleted, "<BRANCH_NAME>", branch_name))
         break
      elseif name == "a" then
         if not git.checkout_branch(git.update_branch) then return end

         echo(misc.list_text_replace(prompts.switched_to_update_branch, "<UPDATE_BRANCH>",
            git.update_branch))

         if not git.stash("pop") then return end
         return
      else
         branch_name = defaults.snaps.base_snap_branch_name .. misc.replace_whitespaces(name)
         if not git.checkout_branch(git.update_branch) then return end
         if not git.stash("apply") then return end
      end
   end

   echo(misc.list_text_replace(prompts.snapshot_creating_branch, "<BRANCH_NAME>", branch_name))

   -- create a packer snapshot using "PackerSnapshot"
   vim.cmd("PackerSnapshot " .. branch_name)

   -- create and checkout snap branch
   if not git.create_branch(branch_name) then
      git.stash("drop")
      return
   end

   -- add packer snapshot to chadrc override
   local override_config = {
      plugins = {
         override = {
            ["wbthomason/packer.nvim"] = { snapshot = branch_name }
         }
      }
   }

   override_config = vim.tbl_deep_extend("force", git.current_config, override_config)

   -- set the packer snapshot for this nvchad snap
   utils.write_data('return M', 'M.plugins.override = {\n'
      .. misc.table_to_string(override_config.plugins.override) .. '\n}\n\nreturn M')

   if not git.add('"' .. defaults.custom.config_dir .. '"', '-f') then
      return
   end

   if not git.create_commit("-m '" .. defaults.snaps.base_tmp_commit_message .. branch_name
      .. "'") then
      return
   end

   local success, author, email, time_zone = git.get_author_identity()

   if not success then
      return
   end

   local commit_msg = defaults.snaps.base_commit_message .. git.get_local_head()

   echo(misc.list_text_replace(prompts.snapshot_compressing_branch, "<BRANCH_NAME>", branch_name))

   -- squash commit history to save storage space and change commit ownership
   if not git.squash_commit_history(commit_msg, author, email, time_zone) then
      return
   end

   misc.print_padding("\n", 1)
   echo(misc.list_text_replace(prompts.snapshot_successfully_created, "<SNAP_NAME>", branch_name))

   -- -- return to the update branch
   if not git.checkout_branch(git.update_branch) then
      return
   end

   git.stash_action_for_entry_by_name('apply', defaults.snaps.base_config_stash_name, 0, 1)

   if not git.restore("--staged", defaults.custom.config_dir) then
      return
   end

   misc.print_padding("\n", 1)
   echo(misc.list_text_replace(prompts.snapshot_stay_or_return,
      { "<BRANCH_NAME>", "<UPDATE_BRANCH>" }, { branch_name, git.update_branch }))

   local stay_on_snap = string.lower(vim.fn.input("-> "));

   if stay_on_snap == "r" then
      return
   end

   if not git.checkout_branch(branch_name) then
      return
   end
end

return snap_create
