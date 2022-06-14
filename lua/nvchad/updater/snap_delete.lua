local function snap_delete()
   local utils = require "nvchad"
   local git = require 'nvchad.utils.git'
   local misc = require 'nvchad.utils.misc'
   local defaults = require 'nvchad.utils.config'
   local prompts = require 'nvchad.utils.prompts'
   local echo = utils.echo
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

   local snapshot_list_str = {}

   vim.list_extend(snapshot_list_str, prompts.select_snapshot_to_delete)

   for i, snapshot in ipairs(snapshot_list) do
      if snapshot:match("\\* " .. current_branch_name .. "$") then
         snapshot_list[i] = current_branch_name
      end

      vim.list_extend(snapshot_list_str, { { "    [" .. tostring(i) .. "] " }, { snapshot,
         "Title" }, { (current_branch_name == snapshot_list[i] and " (currently in use)" or "") },
         { "\n" } })
   end

   vim.list_extend(snapshot_list_str, prompts.select_snapshot_to_delete_enter_index)

   echo(snapshot_list_str)

   local selection = vim.trim(string.lower(vim.fn.input("-> ")))

   misc.print_padding("\n", 2)

   if selection == "c" then
      echo(misc.list_text_replace(prompts.cancelled_action, "<ACTION>", "NvChadSnapshotDelete"))
      return
   end

   local selection_list = vim.fn.split(selection, " ")

   if #selection_list == 0 then
      echo(prompts.no_snapshots_selected)
      return
   end

   local processed = {}
   local invalid_selection_list = vim.deepcopy(prompts.invalid_inputs)
   local valid_selection_list = vim.deepcopy(prompts.snapshot_successfully_deleted)

   for _, input_str in ipairs(selection_list) do
      local number = tonumber(input_str)

      if input_str ~= "" and not vim.tbl_contains(processed, input_str) then
         table.insert(processed, input_str)

         if type(number) ~= "number" or number < 1 or number > #snapshot_list or
             current_branch_name == snapshot_list[number] then

            if current_branch_name == snapshot_list[number] then
               echo(prompts.cannot_delete_current_snapshot)
            end
            vim.list_extend(invalid_selection_list, { { (#invalid_selection_list > 1 and ", "
                or "") .. input_str } })
         else

            -- delete the snapshot
            if git.delete_branch(snapshot_list[number]) then

               -- delete the corresponding "PackerSnapshot"
               vim.cmd("PackerSnapshotDelete " .. snapshot_list[number])

               vim.list_extend(valid_selection_list,
                  { { (#valid_selection_list > 1 and ", " or "") .. "[" .. input_str .. "] " ..
                      snapshot_list[number] } })
            end
         end
      end
   end

   if #invalid_selection_list > 1 then
      echo(invalid_selection_list)
      misc.print_padding("\n", 1)
   end

   if #valid_selection_list > 1 then
      echo(valid_selection_list)
   else
      echo(prompts.no_snapshots_deleted)
      return
   end
end

return snap_delete
