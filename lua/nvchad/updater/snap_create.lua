local function snap_create()
   -- in all the comments below, config means user config
   local utils = require "nvchad"
   local git = require 'nvchad.utils.git'
   local misc = require 'nvchad.utils.misc'
   local prompts = require 'nvchad.utils.prompts'
   local echo = utils.echo

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

   if not git.add('lua/custom', true) then
      return
   end

   local valid_git_dir = git.validate_dir()

   -- return if the directory is not a valid git directory
   if not valid_git_dir then
      return
   end

   -- normalize the name
   name = string.gsub(name, "%W", "_")
   name = string.gsub(name, " ", "_")

   local branch_name = "NvChad_Snapshot_" .. name

   echo(misc.list_text_replace(prompts.snapshot_creating_branch, "<BRANCH_NAME>", branch_name))

   -- create a packer snapshot using the vim command "PackerSnapshot"
   vim.cmd("PackerSnapshot " .. branch_name)

   -- create and checkout snap branch
   if not git.create_branch(branch_name) then
      return
   end

   -- set the packer snapshot for this nvchad snap
   utils.write_data("return M", 'M.plugins.override["wbthomason/packer.nvim"] = { snapshot = "'
      .. branch_name .. '" }\n\nreturn M')

   if not git.add('lua/custom', true) then
      return
   end

   valid_git_dir = git.validate_dir()

   -- return if the directory is not a valid git directory
   if not valid_git_dir then
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

   if not git.reset(1, "--soft") then
      return
   end

   if not git.restore("--staged .") then
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
