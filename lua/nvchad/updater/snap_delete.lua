local function snap_delete()
   -- in all the comments below, config means user config
   local utils = require "nvchad"
   local git = require 'nvchad.utils.git'
   local misc = require 'nvchad.utils.misc'
   local prompts = require 'nvchad.utils.prompts'
   local echo = utils.echo


   echo({ { "Deleting a snapshot" } })
end

return snap_delete
