local M = {}

M.custom = {
   config_dir = "lua/custom",
}

M.snaps = {
   base_snap_branch_name = "NvChad_Snapshot_",
   base_config_stash_name = "NvChad_Snapshot_Custom_Dir_Backup_",
   base_tmp_commit_message = "NvChad_Snapshot_tmp_commit_",
   base_commit_message = "NvChad_Snapshot_of_commit_",
}

return M
