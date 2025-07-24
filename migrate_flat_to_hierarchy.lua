-- run on Redbean with -i -F migrate_to_new_layout.lua
-- unironically only doing this to make renamings easier while I still can
local total = {}
for name, kind, ino, off in assert(unix.opendir("wiki")) do
	if kind == unix.DT_REG and name:sub(1, 1) ~= "." then
		table.insert(total, name)
	end
end
-- alright, start moving files
for _, v in ipairs(total) do
	local newPath = "wiki/" .. v:gsub("_", "/")
	local newPathDir = path.dirname(newPath)
	unix.makedirs(newPathDir)
	unix.rename("wiki/" .. v, newPath)
end
print("done")
