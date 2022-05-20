local function change_theme(current_theme, new_theme)
   if current_theme == nil or new_theme == nil then
      print "Error: Provide current and new theme name"
      return false
   end

   if current_theme == new_theme then
      return
   end

   local file_fn = require("nvchad").file
   local file = vim.fn.stdpath "config" .. "/lua/custom/" .. "chadrc.lua"

   -- store in data variable
   local data = file_fn("r", file)

   -- check if data is false or nil and create a default file if it is
   if not data then
      file_fn("w", file, 'local M = {}\n\nM.ui = {\n   theme = "' .. new_theme .. '",\n}\n\nreturn M')
      data = file_fn("r", file)
   end

   -- if the file was still not created, then something went wrong
   if not data then
      print("Error: Could not create: " .. file .. ". Please create it manually to set a default "
         .. "theme. Look at the documentation for more info.")
      return false
   end

   -- escape characters which can be parsed as magic chars
   current_theme = current_theme:gsub("%p", "%%%0")
   new_theme = new_theme:gsub("%p", "%%%0")

   local find = "theme = .?" .. current_theme .. ".?"
   local replace = 'theme = "' .. new_theme .. '"'
   local content = string.gsub(data, find, replace)

   -- see if the find string exists in file
   if content == data then
      print("Error: Cannot change default theme with " .. new_theme .. ", edit " .. file .. " manually")
      return false
   else
      assert(file_fn("w", file, content))
   end
end

return change_theme
