local function update()
  -- in all the comments below, config means user config
  local config_path = vim.fn.stdpath "config"
  local utils = require "nvchad"
  local echo = utils.echo
  local current_config = require("core.utils").load_config()
  local update_url = current_config.options.nvChad.update_url or "https://github.com/NvChad/NvChad"
  local update_branch = current_config.options.nvChad.update_branch or "main"
  local current_sha, backup_sha, remote_sha = "", "", ""
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

  -- get the current sha of the remote HEAD
  local function get_remote_head(branch)
    return vim.fn.system("git -C " .. config_path .. " ls-remote --heads origin " .. branch):match("(%w*)")
  end

  -- get the current sha of the local HEAD
  local function get_local_head()
    return vim.fn.system("git -C " .. config_path .. " rev-parse HEAD"):match("(%w*)")
  end

  -- save the current sha and check if config folder is a valid git directory
  local valid_git_dir = true
  current_sha = get_local_head()
  remote_sha = get_remote_head(update_branch)

  if vim.api.nvim_get_vvar "shell_error" == 0 then
    vim.fn.system("git -C " .. config_path .. " commit -a -m 'tmp'")
    backup_sha = get_local_head()
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

  -- create a dictionary of human readable strings
  local function get_human_readables(count)
    local human_readable_dict = {}
    human_readable_dict["have"] = count > 1 and "have" or "has"
    human_readable_dict["commits"] = count > 1 and "commits" or "commit"
    human_readable_dict["change"] = count > 1 and "changes" or "change"
    return human_readable_dict
  end

  -- get all commits between two points in the git history as a list of strings
  local function get_commit_list_by_hash_range(start_hash, end_hash)
    local commit_list_string = vim.fn.system(
      "git -C " .. config_path ..
      " log --oneline --no-merges --decorate --date=short --pretty='format:%ad: %h %s' " ..
      start_hash .. ".." .. end_hash)
    return vim.fn.split(commit_list_string, "\n") or nil
  end

  -- filter string list by keywords
  local function filter_commit_list(commit_list, keywords)
    return vim.tbl_filter(function(line)
      for _, keyword in ipairs(keywords) do
        -- normalize commit messages
        local normalized_line = string.lower(line)
        -- check if the commit message contains any of the breaking change keywords
        if vim.fn.stridx(normalized_line, keyword) > 0 then
          return true
        end
      end
      return false
    end, commit_list) or nil
  end

  -- prepare the string representation of a commit list and return a list of lists to use with echo
  local function prepare_commit_table(commit_list)
    local output = {}
    for _, line in ipairs(commit_list) do
      -- split line into date hash and message. Expected format: "yyyy-mm-dd: hash message"
      local commit_date, commit_hash, commit_message = line:match("(%d%d%d%d%-%d%d%-%d%d): (%w+)(.*)")
      -- merge commit messages into one output array to minimize echo calls
      vim.list_extend(output, { { "    " }, { commit_date }, { " " }, { commit_hash, "WarningMsg" },
        { commit_message, "String" }, { "\n" } })
    end
    return output
  end

  -- check for breaking changes in the current branch
  local function check_for_breaking_changes_and_continue(current_head, remote_head)
    local breaking_change_keywords = { "breaking_change" }
    local breaking_changes = {}

    -- if the remote HEAD is equal to the current HEAD we are already up to date
    if remote_head == current_head then
      echo { { "You are already up to date with ", "String" }, { "" .. update_branch .. "" },
        { ". There is nothing to do!", "String" } }
      return false
    end

    echo { { "Fetching new changes from remote..", "String" } }

    -- fetch remote silently
    vim.fn.system("git -C " .. config_path ..
    " fetch --quiet --prune --no-tags --no-recurse-submodules origin " .. update_branch)

    echo { { "Analyzing commits...", "String" } }

    -- get all new commits
    local new_commit_list = get_commit_list_by_hash_range(current_head, remote_head)

    -- if we did not receive any new commits, we encountered an error
    if new_commit_list == nil then
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
    breaking_changes = filter_commit_list(new_commit_list, breaking_change_keywords)

    -- get human redable wording
    local hr = get_human_readables(#new_commit_list)

    echo { { "\nThere ", "Title" }, { hr["have"], "Title" }, { " been", "Title" },
      { " " .. #new_commit_list .. " " }, { "new ", "Title" }, { hr["commits"], "Title" },
      { " since the last update.\n\n", "Title" } }

    -- if there are breaking changes, print a list of them
    if #breaking_changes > 0 then
      local breaking_changes_message = { { "Found", "Title" }, { " " .. #breaking_changes .. " " }, { "potentially breaking ", "Title" },
        { hr["change"], "Title" }, { ":\n", "Title" } }
      vim.list_extend(breaking_changes_message, prepare_commit_table(breaking_changes))
      echo(breaking_changes_message)

      -- ask the user if they would like to continue with the update
      echo { { "\nWould you still like to continue with the update? [y/N]", "WarningMsg" } }
      local continue = string.lower(vim.fn.input("-> ")) == "y"
      if continue then
        utils.clear_cmdline()
        echo { { "\n\n", "String" } }
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
      return true
    end
  end

  if not check_for_breaking_changes_and_continue(current_sha, remote_sha) then
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
      local applied_commit_list = prepare_commit_table(get_commit_list_by_hash_range(current_sha, remote_sha))
      local summary = { { "Commits:\n", "Title" } }
      vim.list_extend(summary, applied_commit_list)
      vim.list_extend(summary, { { "\nNvChad succesfully updated.\n", "String" } })

      -- print the update summary
      vim.cmd "bd!"
      echo(summary)
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
