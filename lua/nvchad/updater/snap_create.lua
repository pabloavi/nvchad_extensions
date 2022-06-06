local function snap_create()
   -- in all the comments below, config means user config
   local utils = require "nvchad"
   local git = require 'nvchad.utils.git'
   local misc = require 'nvchad.utils.misc'
   local prompts = require 'nvchad.utils.prompts'
   local echo = utils.echo
   local base_snap_branch_name = "NvChad_Snapshot_"
   local config_stash_name = "NvChad_Snapshot_Custom_Dir_Backup_" .. os.date("%Y-%m-%d_%H:%M:%S_%z")

   local function normalize_branch_name(branch_name)
      return branch_name:gsub("%W", "_"):gsub(" ", "_")
   end

   -- check if we are on the correct update branch, if not, switch to it
   if git.checkout_branch(git.update_branch) then
      echo(misc.list_text_replace(prompts.switched_to_update_branch, "<UPDATE_BRANCH>",
         git.update_branch))
   else
      return
   end

   -- get the name of the snap
   echo(prompts.snapshot_enter_name)
   local name = string.lower(vim.fn.input("-> "));

   misc.print_padding("\n", 2)

   if name == "a" then
      return
   end

   local branch_name = base_snap_branch_name .. normalize_branch_name(name)

   -- create a backup of the current custom dir in the stash if it exists
   if git.add('lua/custom', '-f') then
      echo(misc.list_text_replace(prompts.stashing_custom_dir, "<STASH_NAME>", config_stash_name))

      git.stash('store', '"$(git stash create lua/custom)"', '-m ' .. config_stash_name)
      git.restore("--staged", "lua/custom")
   end

   -- check if the branch already exists
   while git.checkout_branch(branch_name) do
      echo(misc.list_text_replace(prompts.branch_already_exists, "<BRANCH_NAME>", branch_name))
      name = string.lower(vim.fn.input("-> "));

      misc.print_padding("\n", 2)

      if name == "o" then
         if not git.checkout_branch(git.update_branch) then
            return
         end
         if not git.delete_branch(branch_name) then
            return
         end
         echo(misc.list_text_replace(prompts.branch_deleted, "<BRANCH_NAME>", branch_name))
         break
      elseif name == "a" then
         if not git.checkout_branch(git.update_branch) then
            return
         end
         echo(misc.list_text_replace(prompts.switched_to_update_branch, "<UPDATE_BRANCH>",
            git.update_branch))
         git.stash("drop")
         return
      end

      branch_name = base_snap_branch_name .. normalize_branch_name(name)
   end

   echo(misc.list_text_replace(prompts.snapshot_creating_branch, "<BRANCH_NAME>", branch_name))

   -- create a packer snapshot using "PackerSnapshot"
   -- vim.cmd("PackerSnapshot " .. branch_name)

   -- create and checkout snap branch
   if not git.create_branch(branch_name) then
      git.stash("drop")
      return
   end

   -- set the packer snapshot for this nvchad snap
   -- utils.write_data("return M", 'M.plugins.override["wbthomason/packer.nvim"] = { snapshot = "'
   --    .. branch_name .. '" }\n\nreturn M')

   if not git.add('lua/custom', '-f') then
      return
   end

   if not git.create_commit("-m 'NvChad_Snapshot_tmp_commit_" .. branch_name .. "'") then
      return
   end

   local success, author, email, time_zone = git.get_author_identity()

   if not success then
      return
   end

   local commit_msg = "NvChad_Snapshot_of_commit_" .. git.get_local_head()

   echo(misc.list_text_replace(prompts.snapshot_compressing_branch, "<BRANCH_NAME>", branch_name))

   -- squash commit history to save storage space and change commit ownership
   if not git.squash_commit_history(commit_msg, author, email, time_zone) then
      return
   end

   misc.print_padding("\n", 1)
   echo(misc.list_text_replace(prompts.snapshot_successfully_created, "<SNAP_NAME>", name))

   -- -- return to the update branch
   if not git.checkout_branch(git.update_branch) then
      return
   end

   local stash_index = git.get_stash_index(config_stash_name)

   if stash_index == -1 then stash_index = 0 end

   git.stash('apply', stash_index)

   if not git.restore("--staged", "lua/custom") then
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
