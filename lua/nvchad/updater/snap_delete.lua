local function snap_delete()
   local utils = require "nvchad"
   local git = require 'nvchad.utils.git'
   local misc = require 'nvchad.utils.misc'
   local defaults = require 'nvchad.utils.config'
   local prompts = require 'nvchad.utils.prompts'
   local echo = utils.echo
   local current_branch_name = git.get_current_branch_name()

   local snapshot_list = git.get_branch_list(function(branch)
      return branch:match(defaults.snaps.base_snap_branch_name)
   end)

   if #snapshot_list == 0 then
      echo({ { "No snapshots found." } })
      return
   end

   local snapshot_list_str = {}

   vim.list_extend(snapshot_list_str, { { "Select the snapshot(s) that you would like to delete:\n", "WarningMsg" } })

   for i, snapshot in ipairs(snapshot_list) do
      if snapshot:match(current_branch_name) then snapshot_list[i] = current_branch_name end
      vim.list_extend(snapshot_list_str, { { "    [" .. tostring(i) .. "] " }, { snapshot, "Title" },
         { (current_branch_name == snapshot_list[i] and " (currently in use)" or "") }, { "\n" } })
   end

   echo(snapshot_list_str)

   echo({ { "\nEnter the indices of the snapshots separated by space or [a]bort [<number_list>/A]:",
      "WarningMsg" } })

   local selection = string.lower(vim.fn.input("-> "))

   misc.print_padding("\n", 2)

   if selection == "a" then
      echo({ { "Aborted." } })
      return
   end

   local selection_list = vim.fn.split(selection, " ")

   if #selection_list == 0 then
      echo({ { "No snapshots selected." } })
      return
   end

   local processed = {}
   local invalid_selection_list = { { "Invalid inputs: ", "WarningMsg" } }
   local valid_selection_list = { { "The following snapshots have been successfully deleted: ", "WarningMsg" } }

   for _, input_str in ipairs(selection_list) do
      local number = tonumber(input_str)

      if not vim.tbl_contains(processed, input_str) then
         table.insert(processed, input_str)

         if type(number) ~= "number" or number < 1 or number > #snapshot_list or
             current_branch_name == snapshot_list[number] then

            if current_branch_name == snapshot_list[number] then
               echo({ { "Error: You cannot delete a snapshot that is currently in use!\n\n", "ErrorMsg" } })
            end
            vim.list_extend(invalid_selection_list, { { (#invalid_selection_list > 1 and ", "
                or "") .. input_str } })
         else
            if git.delete_branch(snapshot_list[number]) then
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
      echo({ { "No snapshots were deleted!", "WarningMsg" } })
      return
   end
end

return snap_delete
