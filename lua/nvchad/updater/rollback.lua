local function rollback()
   -- in all the comments below, config means user config
   local utils = require "nvchad"
   local git = require 'nvchad.updater.utils.git'
   local misc = require 'nvchad.updater.utils.misc'
   local prompts = require 'nvchad.updater.utils.prompts'
   local echo = utils.echo

   -- local valid_git_dir = git.validate_dir()
   --
   -- -- return if the directory is not a valid git directory
   -- if not valid_git_dir then
   --    return
   -- end

   echo({ { "Rolling back to previous commit..." } })
end

return rollback
