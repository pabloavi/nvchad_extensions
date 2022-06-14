local function snap_checkout()
   -- in all the comments below, config means user config
   local utils = require "nvchad"
   local git = require 'nvchad.utils.git'
   local misc = require 'nvchad.utils.misc'
   local defaults = require 'nvchad.utils.config'
   local prompts = require 'nvchad.utils.prompts'
   local echo = utils.echo
   local config_stash_name = defaults.snaps.base_config_stash_name .. os.date("%Y-%m-%d_%H:%M:%S_%z")
   local current_branch_name = git.get_current_branch_name()

   -- BETA DISCLAIMER: This feature is still in BETA. If you encounter any issues contact
   -- @LeonHeidelbach on GitHub by creating an issue in the main NvChad repo.
   echo(prompts.beta_disclaimer)
   misc.print_padding("\n", 1)

   local snapshot_list = git.get_branch_list(function(branch)
      return branch:match(defaults.snaps.base_snap_branch_name)
   end)

   if #snapshot_list == 0 then
      echo(prompts.no_snapshots_found)
      return
   end

   snapshot_list = vim.list_extend({ git.update_branch }, snapshot_list)

   local snapshot_list_str = {}

   vim.list_extend(snapshot_list_str, prompts.select_snapshot_to_checkout)

   for i, snapshot in ipairs(snapshot_list) do
      if snapshot:match("\\* " .. current_branch_name .. "$") then
         snapshot_list[i] = current_branch_name
      end

      vim.list_extend(snapshot_list_str,
         { { "    [" .. tostring(i) .. "] " }, { (snapshot == git.update_branch and "  " or "")
             .. snapshot, "Title" }, { (current_branch_name == snapshot_list[i] and
             " (currently in use)" or "") }, { "\n" } })
   end

   vim.list_extend(snapshot_list_str, prompts.select_snapshot_to_checkout_enter_index)

   echo(snapshot_list_str)

   local selection = vim.trim(string.lower(vim.fn.input("-> ")))

   misc.print_padding("\n", 2)

   if selection == "c" then
      echo(misc.list_text_replace(prompts.cancelled_action, "<ACTION>", "NvChadSnapshotCheckout"))
      return
   end

   local number = tonumber(selection)

   if type(number) ~= "number" or number < 1 or number > #snapshot_list then
      echo(prompts.invalid_input)
      return
   end

   local selected_is_update_branch = snapshot_list[number] == git.update_branch

   if snapshot_list[number] == current_branch_name then
      if selected_is_update_branch then
         echo(misc.list_text_replace(prompts.already_on_selected_update_branch,
            "<SNAP_NAME>", snapshot_list[number]))
      else
         echo(misc.list_text_replace(prompts.already_on_selected_snapshot_branch,
            "<SNAP_NAME>", snapshot_list[number]))
      end

      return
   end

   if current_branch_name == git.update_branch then
      -- make sure that chadrc.lua exists, if not create it as a copy of the example
      local result = misc.ensure_file_exists(defaults.custom.default_chadrc_path,
         misc.get_example_chadrc())

      if not result then
         echo(misc.list_text_replace(prompts.chadrc_file_not_created, "<FILE_PATH>",
            defaults.custom.default_chadrc_path))
         return false
      end

      -- create a backup of the current custom dir in the stash if it exists
      if git.add('"' .. defaults.custom.config_dir .. '"', '-f') then
         echo(misc.list_text_replace(prompts.stashing_custom_dir, "<STASH_NAME>",
            config_stash_name))

         git.stash('store', '"$(git stash create ' .. defaults.custom.config_dir
            .. ')"', '-m ' .. config_stash_name)
         git.restore("--staged", defaults.custom.config_dir)
      end

      -- drop old config backup stash entries
      git.stash_action_for_entry_by_name('drop', defaults.snaps.base_config_stash_name, 4)
   elseif current_branch_name:match(defaults.snaps.base_snap_branch_name) then
      git.commit("-a", "-m", defaults.snaps.base_custom_changes_commit_message
         .. os.date("%Y-%m-%d_%H:%M:%S_%z"))
   end

   if not git.checkout_branch(snapshot_list[number]) then
      return
   end

   if (selected_is_update_branch) then
      if git.stash("apply") then
         git.restore("--staged", defaults.custom.config_dir)
      else
         echo(misc.list_text_replace(prompts.applying_git_stash_failed, "<BRANCH_NAME>",
            snapshot_list[number]))
      end
   end

   misc.print_padding("\n", 1)
   echo(misc.list_text_replace(prompts.checkout_success, "<NEW_BRANCH_NAME>",
      snapshot_list[number]))
end

return snap_checkout
