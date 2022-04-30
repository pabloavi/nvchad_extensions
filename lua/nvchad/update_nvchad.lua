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

  -- check for breaking changes in the current branch
  local function check_for_breaking_changes_and_continue()
    local keywords = { 'break', 'fix', 'bug', 'merge', 'squash' }
    local remote_head = vim.fn.system("git -C " .. config_path .. " ls-remote --heads origin " .. update_branch):match("(%w*)")
    local current_head = vim.fn.system("git -C " .. config_path .. " rev-parse HEAD"):match("(%w*)")
    local human_readable = {"have", "has", "commits", "commit", "changes", "change"}
    local breaking_changes = {}

    -- if the remote HEAD is equal to the current HEAD we are already up to date
    if remote_head == current_head then
      echo { { "You are already up to date with ", "String"}, {  "".. update_branch .. "" },
        { ". There is nothing to do!", "String" } }
      return false
    end

    echo { { "Fetching changes from remote..", "String" } }

    -- fetch remote silently
    vim.fn.system("git -C " .. config_path ..
    " fetch --quiet --prune --no-tags --no-recurse-submodules origin " .. update_branch)

    echo { { "Analyzing commits...", "String" } }

    -- get all new commits
    local new_commits = vim.fn.system(
      "git -C " .. config_path ..
      " log --oneline --no-merges --decorate --date=short --pretty='format:%ad: %h %s' " ..
      current_head .. ".." .. remote_head
    )

    -- if we did not receive any new commits, we encountered an error
    if new_commits == "" then
        echo { { "\nSomething went wrong. No new commits were received even though the remote's HEAD differs from the " ..
          "currently checked out HEAD. Would you still like to continue with the update? [y/N]", "WarningMsg" } }
        local continue = string.lower(vim.fn.input("-> ")) == "y"
      if continue then
        utils.clear_cmdline()
        echo { { "\n\nUpdating...\n\n", "String" } }
        return true
      else
        utils.clear_cmdline()
        echo { { "\n\nUpdate cancelled!", "Title" } }
        restore_repo_state()
        return false
      end
    end

    -- check if there are any breaking changes
    local new_commits_list = vim.fn.split(new_commits, "\n")
    breaking_changes = vim.tbl_filter(function(line)
      for _, keyword in ipairs(keywords) do
        -- normalize commit messages
        local normalized_line = string.lower(line)
        -- check if the commit message contains any of the breaking change keywords
        if vim.fn.stridx(normalized_line, keyword) > 0 then
          return true
        end
      end
      return false
    end, new_commits_list)

    -- create human redable wording
    local human_readable_have = #breaking_changes > 1 and human_readable[1] or human_readable[2]
    local human_readable_commits = #breaking_changes > 1 and human_readable[3] or human_readable[4]
    local human_readable_change = #breaking_changes > 1 and human_readable[5] or human_readable[6]

    echo { { "\nThere ", "Title" }, { human_readable_have, "Title"}, { " been", "Title"},
      { " " .. #new_commits_list .. " " }, {"new ", "Title"}, { human_readable_commits, "Title" },
      {" since the last update.", "Title" } }

    -- if there are breaking changes, print a list of them
    if #breaking_changes > 0 then
      echo { { "\nFound", "Title"}, { " " .. #breaking_changes .. " "}, { "potentially breaking ", "Title"},
        { human_readable_change, "Title" }, { ":\n", "Title" } }
      for _, line in ipairs(breaking_changes) do
        -- split line into date hash and message. Expected format: "yyyy-mm-dd: hash message"
        local commit_date, commit_hash, commit_message = line:match("(%d%d%d%d%-%d%d%-%d%d): (%w+)(.*)")
        echo { {"    "}, { commit_date }, {" "}, { commit_hash, "WarningMsg" }, { commit_message, "String" } }
      end
      -- ask the user if they would like to continue with the update
      echo { { "\nWould you still like to continue with the update? [y/N]", "WarningMsg" } }
      local continue = string.lower(vim.fn.input("-> ")) == "y"
      if continue then
        utils.clear_cmdline()
        echo { { "\n\nUpdating...\n\n", "String" } }
        return true
      else
        utils.clear_cmdline()
        echo { { "\n\nUpdate cancelled!", "Title" } }
        restore_repo_state()
        return false
      end
    else
      -- if there are no breaking changes, just update
      utils.clear_cmdline()
      echo { { "\n\nUpdating...\n\n", "String" } }
      return true
    end
  end

  if not check_for_breaking_changes_and_continue() then
    vim.cmd "bd!"
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
    echo { { "\nUpdate cancelled!", "Title" } }
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
