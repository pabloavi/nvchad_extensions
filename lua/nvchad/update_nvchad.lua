local function update()
   -- in all the comments below, config means user config
   local config_path = vim.fn.stdpath "config"
   local utils = require "nvchad"
   local echo = utils.echo
   local current_config = require("core.utils").load_config()
   local update_url = current_config.options.nvChad.update_url or "https://github.com/NvChad/NvChad"
   local update_branch = current_config.options.nvChad.update_branch or "main"
   local current_sha, backup_sha = "", ""
   local function restore_repo_state()
      -- on failing, restore to the last repo state, including untracked files
      vim.fn.system(
         "git -C "
            .. config_path
            .. " reset --hard "
            .. current_sha
            .. " ; git -C "
            .. config_path
            .. " cherry-pick -n "
            .. backup_sha
            .. " ; git reset"
      )
   end

   -- save the current sha and check if config folder is a valid git directory
   local valid_git_dir = true
   current_sha = vim.fn.system("git -C " .. config_path .. " rev-parse HEAD")

   if vim.api.nvim_get_vvar "shell_error" == 0 then
      vim.fn.system("git -C " .. config_path .. " commit -a -m 'tmp'")
      backup_sha = vim.fn.system("git -C " .. config_path .. " rev-parse HEAD")
      if vim.api.nvim_get_vvar "shell_error" ~= 0 then
         valid_git_dir = false
      end
   else
      valid_git_dir = false
   end

   if not valid_git_dir then
      restore_repo_state()
      echo { { "Error: " .. config_path .. " is not a git directory.\n" .. current_sha .. backup_sha, "ErrorMsg" } }
      return
   end

   -- ask the user for confirmation to update because we are going to run git reset --hard
   echo { { "Url: ", "Title" }, { update_url } }
   echo { { "Branch: ", "Title" }, { update_branch } }
   if backup_sha ~= current_sha then
      echo {
         { "\nWarning\n  Modification to repo files detected.\n\n  Updater will run", "WarningMsg" },
         { " git reset --hard " },
         {
            "in config folder, so changes to existing repo files except ",
            "WarningMsg",
         },

         { "lua/custom folder" },
         { " will be lost!\n", "WarningMsg" },
      }
   else
      echo { { "\nNo conflicting changes found, ready to update.", "Title" } }
   end
   echo { { "\nUpdate NvChad ? [y/N]", "WarningMsg" } }

   local ans = string.lower(vim.fn.input "-> ") == "y"
   utils.clear_cmdline()
   if not ans then
      restore_repo_state()
      echo { { "Update cancelled!", "Title" } }
      return
   end

   -- function that will executed when git commands are done
   local function update_exit(_, code)
      -- close the terminal buffer only if update was success, as in case of error, we need the error message
      if code == 0 then
         vim.cmd "bd!"
         echo { { "NvChad succesfully updated.\n", "String" } }
      else
         restore_repo_state()
         echo { { "Error: NvChad Update failed.\n", "ErrorMsg" } }
         echo { { "Local changes were restored." } }
      end
   end

   -- reset in case config was modified
   vim.fn.system("git -C " .. config_path .. " reset --hard " .. current_sha)
   -- use --rebase, to not mess up if the local repo is outdated
   local update_script = table.concat({
      "git pull --set-upstream",
      update_url,
      update_branch,
      "--rebase",
   }, " ")

   -- open a new buffer
   vim.cmd "new"
   -- finally open the pseudo terminal buffer
   vim.fn.termopen(update_script, {
      -- change dir to config path so we don't need to move in script
      cwd = config_path,
      on_exit = update_exit,
   })
end

return update
