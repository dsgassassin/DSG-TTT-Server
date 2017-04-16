include("sv_titles_mnsb.lua")

local function AddDirectory(directory)
   local files, folders = file.Find(directory.."/*", "GAME")
   
   for _, file_directory in pairs(folders) do
      if file_directory != ".svn" then 
         AddDirectory(directory.."/"..file_directory)
      end
   end
 
   for k, v in pairs(files) do
      resource.AddSingleFile(directory.."/"..v)
   end
end
 
 if (midnight_sb.config.map_source == "fastdl") then
   AddDirectory("materials/midnight-icons")
   resource.AddSingleFile("materials/midnight-thumbs/"..game.GetMap()..".png")
end