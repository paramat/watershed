function watershed_appletree(x, y, z, area, data)
	local c_tree = minetest.get_content_id("default:tree")
	local c_apple = minetest.get_content_id("default:apple")
	local c_wsappleaf = minetest.get_content_id("watershed:appleleaf")
	for j = -2, 4 do
		if j >= 1 then
			for i = -2, 2 do
			for k = -2, 2 do
				local vil = area:index(x + i, y + j + 1, z + k)
				if math.random(48) == 2 then
					data[vil] = c_apple
				elseif math.random(5) ~= 2 then
					data[vil] = c_wsappleaf
				end
			end
			end
		end
		local vit = area:index(x, y + j, z)
		data[vit] = c_tree
	end
end

function watershed_pinetree(x, y, z, area, data)
	local c_tree = minetest.get_content_id("default:tree")
	local c_wsneedles = minetest.get_content_id("watershed:needles")
	local c_snowblock = minetest.get_content_id("default:snowblock")
	for j = -4, 14 do
		if j == 3 or j == 6 or j == 9 or j == 12 then
			for i = -2, 2 do
			for k = -2, 2 do
				if math.abs(i) == 2 or math.abs(k) == 2 then
					if math.random(5) ~= 2 then
						local vil = area:index(x + i, y + j, z + k)
						data[vil] = c_wsneedles
						local vila = area:index(x + i, y + j + 1, z + k)
						data[vila] = c_snowblock
					end
				end
			end
			end
		elseif j == 4 or j == 7 or j == 10 then
			for i = -1, 1 do
			for k = -1, 1 do
				if not (i == 0 and j == 0) then
					if math.random(7) ~= 2 then
						local vil = area:index(x + i, y + j, z + k)
						data[vil] = c_wsneedles
						local vila = area:index(x + i, y + j + 1, z + k)
						data[vila] = c_snowblock
					end
				end
			end
			end
		elseif j == 13 then
			for i = -1, 1 do
			for k = -1, 1 do
				if not (i == 0 and j == 0) then
					if math.random(7) ~= 2 then
						local vil = area:index(x + i, y + j, z + k)
						data[vil] = c_wsneedles
						local vil = area:index(x + i, y + j + 1, z + k)
						data[vil] = c_wsneedles
						local vila = area:index(x + i, y + j + 2, z + k)
						data[vila] = c_snowblock
					end
				end
			end
			end
		end
		local vit = area:index(x, y + j, z)
		data[vit] = c_tree
	end
	local vil = area:index(x, y + 15, z)
	local vila = area:index(x, y + 16, z)
	local vilaa = area:index(x, y + 17, z)
	data[vil] = c_wsneedles
	data[vila] = c_wsneedles
	data[vilaa] = c_snowblock
end

function watershed_jungletree(x, y, z, area, data)
	local c_juntree = minetest.get_content_id("default:jungletree")
	local c_wsjunleaf = minetest.get_content_id("watershed:jungleleaf")
	local c_vine = minetest.get_content_id("watershed:vine")
	local top = math.random(17,23)
	local branch = math.floor(top * 0.6)
	for j = -5, top do
		if j == top or j == top - 1 or j == branch + 1 or j == branch + 2 then
			for i = -2, 2 do -- leaves
			for k = -2, 2 do
				local vi = area:index(x + i, y + j, z + k)
				if math.random(5) ~= 2 then
					data[vi] = c_wsjunleaf
				end
			end
			end
		elseif j <= -1 or j == top - 2 or j == branch then -- branches, roots
			for i = -1, 1 do
			for k = -1, 1 do
				if math.abs(i) + math.abs(k) == 2 then
					local vi = area:index(x + i, y + j, z + k)
					data[vi] = c_juntree
				end
			end
			end
		end
		if j >= 0 and j <= top - 3 then -- climbable nodes
			for i = -1, 1 do
			for k = -1, 1 do
				if math.abs(i) + math.abs(k) == 1 then
					local vi = area:index(x + i, y + j, z + k)
					data[vi] = c_vine
				end
			end
			end
		end
		if j >= -1 and j <= top - 3 then -- trunk
			local vi = area:index(x, y + j, z)
			data[vi] = c_juntree
		end
	end
end

function watershed_acaciatree(x, y, z, area, data)
	local c_tree = minetest.get_content_id("default:tree")
	local c_leaves = minetest.get_content_id("default:leaves")
	for j = -3, 6 do
		if j == 6 then
			for i = -4, 4 do
			for k = -4, 4 do
				if not (i == 0 or k == 0) then
					if math.random(5) ~= 2 then
						local vil = area:index(x + i, y + j, z + k)
						data[vil] = c_leaves
					end
				end
			end
			end
		elseif j == 5 then
			for i = -2, 2, 4 do
			for k = -2, 2, 4 do
				local vit = area:index(x + i, y + j, z + k)
				data[vit] = c_tree
			end
			end
		elseif j == 4 then
			for i = -1, 1 do
			for k = -1, 1 do
				if math.abs(i) + math.abs(k) == 2 then
					local vit = area:index(x + i, y + j, z + k)
					data[vit] = c_tree
				end
			end
			end
		else
			local vit = area:index(x, y + j, z)
			data[vit] = c_tree
		end
	end
end

function watershed_flower(data, vi, noise)
	local c_danwhi = minetest.get_content_id("flowers:dandelion_white")
	local c_danyel = minetest.get_content_id("flowers:dandelion_yellow")
	local c_rose = minetest.get_content_id("flowers:rose")
	local c_tulip = minetest.get_content_id("flowers:tulip")
	local c_geranium = minetest.get_content_id("flowers:geranium")
	local c_viola = minetest.get_content_id("flowers:viola")
	if noise > 0.8 then
		data[vi] = c_danwhi
	elseif noise > 0.4 then
		data[vi] = c_rose
	elseif noise > 0 then
		data[vi] = c_tulip
	elseif noise > -0.4 then
		data[vi] = c_danyel
	elseif noise > -0.8 then
		data[vi] = c_geranium
	else
		data[vi] = c_viola
	end
end

function watershed_cactus(x, y, z, area, data)
	local c_wscactus = minetest.get_content_id("watershed:cactus")
	for j = -2, 4 do
	for i = -2, 2 do
		if i == 0 or j == 2 or (j == 3 and math.abs(i) == 2) then
			local vic = area:index(x + i, y + j, z)
			data[vic] = c_wscactus
		end
	end
	end
end

function watershed_papyrus(x, y, z, area, data)
	local c_papyrus = minetest.get_content_id("default:papyrus")
	local ph = math.random(1, 4)
	for j = 1, ph do
		local vip = area:index(x, y + j, z)
		data[vip] = c_papyrus
	end
end

-- Register buckets, lava fuel

bucket.register_liquid(
	"watershed:water",
	"watershed:waterflow",
	"watershed:bucket_water",
	"bucket_water.png",
	"WS Water Bucket"
)

bucket.register_liquid(
	"watershed:lava",
	"watershed:lavaflow",
	"watershed:bucket_lava",
	"bucket_lava.png",
	"WS Lava Bucket"
)

minetest.register_craft({
	type = "fuel",
	recipe = "watershed:bucket_lava",
	burntime = 60,
	replacements = {{"watershed:bucket_lava", "bucket:bucket_empty"}},
})