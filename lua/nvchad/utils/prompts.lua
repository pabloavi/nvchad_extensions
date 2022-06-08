M = {}

M.add_failed = { { "Adding ", "WarningMsg" }, { " <FILE_PATH> " }, { " to the staging area failed!", "WarningMsg" } }

M.already_on_snapshot_branch = { { "You are already on a snapshot branch (", "WarningMsg" }, { "<SNAP_NAME>" }, { "). You cannot create a snapshot of a snapshot.", "WarningMsg" } }

M.analyzing_commits = { { "Analyzing commits...", "String" } }

M.analyzing_commits_done_breaking_changes = { { "Analyzing commits... Done", "String" } }

M.analyzing_commits_done_no_breaking_changes = { { "No breaking changes in commit list - Analyzed", "Title" } }

M.applied_commits = { { "Applied Commits:\n", "Title" } }

M.branch_already_exists = { { "A Snapshot with the name ", "WarningMsg" }, { "<BRANCH_NAME>" }, { " already exists! Would you like to [o]verwirte this snapshot, use another [<name>] or [a]bort? [<name>/o/A]", "WarningMsg" } }

M.branch_delete_failed = { { "Deleting branch ", "WarningMsg" }, { "<BRANCH_NAME>" }, { " failed!", "WarningMsg" } }

M.branch_deleted = { { "Branch ", "WarningMsg" }, { "<BRANCH_NAME>" }, { " deleted succesfully!\n", "WarningMsg" } }

M.breaking_changes_found = { { "\nFound", "Title" }, { " <BREAKING_CHANGES_COUNT> " }, { "potentially breaking ", "Title" }, { "<HR_CHANGE>", "Title" }, { ":\n", "Title" } }

M.checking_for_updates = { { "Checking for updates...", "String" } }

M.checkout = { { "\nChecking out branch ", "WarningMsg" }, { "<BRANCH_NAME>" } }

M.checkout_failed = { { "\nChecking out branch ", "WarningMsg" }, { "<NEW_BRANCH_NAME>" }, { " failed!", "WarningMsg" }, { " Current branch is: ", "WarningMsg" }, { "<OLD_BRANCH_NAME>" }, { ".", "WarningMsg" } }

M.clean_repo_dir_failed = { { "Error: Could not clean up the repo.", "ErrorMsg" } }

M.clean_repo_dir_success = { { "Cleanup successful!\n\n", "Title" } }

M.commit_summary_failed = { { "Could not create a commit summary.\n", "WarningMsg" } }

M.create_branch_failed = { { "Error: Could not create branch ", "WarningMsg" }, { "<BRANCH_NAME>" }, { "!", "WarningMsg" } }

M.create_commit_failed = { { "Error: Could not create commit.", "ErrorMsg" } }

M.stashing_custom_dir = { { "Stashing custom directory under: ", "WarningMsg" }, { "<STASH_NAME>" }, { ".\n\n", "WarningMsg" } }

M.delete_file_failed = { { "Error: Could not delete file ", "WarningMsg" }, { "<FILE_NAME>" }, { "!", "WarningMsg" } }

M.diverged_branches = { { "\nSomething went wrong. No new commits were received even though the remote's HEAD " .. "differs from the currently checked out HEAD.", "Title", }, { "\n\nWould you like to reset NvChad to the remote's HEAD? Local changes will be lost! " .. "[y/N]", "WarningMsg", } }

M.get_author_identity_failed = { { "Error: Could not get author identity.", "ErrorMsg" } }

M.get_initial_commit_hash_failed = { { "Error: Could not get initial commit hash.", "ErrorMsg" } }

M.modifications_detected = { { "Warning\n  Modification to repo files detected.\n\n  Updater will run", "WarningMsg" }, { " git reset --hard " }, { "in config folder, so changes to existing repo files except ", "WarningMsg" }, { "lua/custom folder" }, { " will be lost!\n", "WarningMsg" } }

M.modifications_detected_stash = { { "Local changes outside of the custom directory detected. " .. 'They have been stashed with "git stash"!\n', "WarningMsg", } }

M.modifications_detected_stash_restore_failed = { { "\nApplying stashed changes to the NvChad " .. 'directory failed, please resolve the conflicts manually and use "git stash pop" to ' .. 'restore or "git stash drop" to discard them!\n ', "WarningMsg", } }

M.modifications_detected_stash_restored = { { "Local changes have been restored succesfully.\n", "WarningMsg" } }

M.new_commits_summary = { { "There ", "Title" }, { "<HR_HAVE>", "Title" }, { " been", "Title" }, { " <HR_NEW_COMMIT_LIST> " }, { "new ", "Title" }, { "<HR_COMMITS>", "Title" }, { " since the last update:\n", "Title" } }

M.no_modifications_detected = { { "No conflicting changes outside of the custom folder, ready to update.", "Title" } }

M.not_a_git_dir = { { "Error: ", "ErrorMsg" }, { "<CONFIG_PATH>", "ErrorMsg" }, { " is not a valid git directory.\n", "ErrorMsg" } }

M.packer_sync = { { "Would you like to run ", "WarningMsg" }, { "PackerSync" }, { " after the update has completed?\n", "WarningMsg" }, { "Not running ", "WarningMsg" }, { "PackerSync" }, { " may break NvChad! ", "WarningMsg" }, { "[y/N]", "WarningMsg" } }

M.remote_head_changes_fetch_failed = { { "Error: Could not fetch remote changes.", "ErrorMsg" } }

M.remote_head_fetching_changes = { { "Fetching new changes from remote...", "String" } }

M.remote_head_sha_fetch_failed = { { "Error: Could not fetch remote HEAD sha.", "ErrorMsg" } }

M.remote_info = { { "Url: ", "Title" }, { "<UPDATE_URL>" }, { "\nBranch: ", "Title" }, { "<UPDATE_BRANCH>" }, { "\n\n" } }

M.removing_tmp_commit = { { "Removing tmp commit. This has not been removed properly after the " .. "last update. Cleaning up...\n\n", "WarningMsg", } }

M.reset_remote_head = { { "Resetting to remote HEAD...", "Title" } }

M.reset_remote_head_failed = { { "Error: Could not reset to remote HEAD.", "ErrorMsg" } }

M.reset_remote_head_success = { { "NvChad's HEAD has successfully been reset to ", "Title" }, { "<UPDATE_BRANCH>" }, { ".\n\n", "Title" } }

M.reset_remote_head_success_status = { { "Reset to remote HEAD successful!\n\n", "Title" }, { "<RESET_STATUS>", "String" }, { "\n", "String" } }

M.reset_failed = { { "Reset failed!", "WarningMsg" } }

M.restore_failed = { { "Restore failed!", "WarningMsg" } }

M.squash_failed = { { "Error: Could not squash commits.", "ErrorMsg" } }

M.update_cancelled = { { "Update cancelled!", "Title" } }

M.update_cancelled_up_to_date = { { "You are already up to date with ", "String" }, { "<UPDATE_BRANCH>" }, { ". There is nothing to do!", "String" } }

M.update_confirm = { { "\nUpdate NvChad? [y/N]", "WarningMsg" } }

M.update_continue = { { "\nWould you still like to continue with the update? [y/N]", "WarningMsg" } }

M.update_failed = { { "\nError: NvChad Update failed.", "ErrorMsg" } }

M.update_failed_changes_restored = { { "Error: NvChad Update failed.\n\n", "ErrorMsg" }, { "Local changes were restored." } }

M.update_success = { { "\nNvChad succesfully updated.\n", "String" } }

M.snapshot_successfully_created = { { "Snapshot ", "Title" }, { "<SNAP_NAME>" }, { " has been created successfully!", "Title" } }

M.snapshot_compressing_branch = { { "Compressing snapshot...", "WarningMsg" } }

M.snapshot_creating_branch = { { "Creating snapshot branch -> ", "WarningMsg" }, { "<BRANCH_NAME>" } }

M.snapshot_enter_name = { { "Enter the name of the snapshot you want to create or abort [<name>/A]:", "WarningMsg" } }

M.snapshot_stay_or_return = { { "Would you like to [u]se the snapshot branch (", "WarningMsg" }, { "<BRANCH_NAME>" }, { ") or [r]eturn to the update branch (", "WarningMsg" }, { "<UPDATE_BRANCH>" }, { ")? [u/R]", "WarningMsg" } }

M.stash_failed = { { "Error: Could not complete stash operation.", "ErrorMsg" } }

M.switched_to_update_branch = { { "Switched to update branch ", "Title" }, { "<UPDATE_BRANCH>" }, { ".", "Title" } }

return M
