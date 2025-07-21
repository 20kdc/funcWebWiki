local size1, size2 = 128, 128
for i = 1, size1 do
	f = io.open("wiki/chaff_" .. tostring(i) .. ".md", "w")
	for j = 1, size2 do
		f:write("Chaff chaff chaff chaff, chaff chaff chaff. <chaff/" .. tostring(math.random(size1)) .. ">. Chaff chaff chaff, chaff chaff chaff.\n\n")
	end
	f:close()
end
