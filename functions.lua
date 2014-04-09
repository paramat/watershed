function watershed_appletree(x, y, z, area, data)
	local c_tree = minetest.get_content_id("default:tree")
	local c_apple = minetest.get_content_id("default:apple")
	local c_wsappleaf = minetest.get_content_id("watershed:appleleaf")
	for j = -2, 4 do
		if j == 2 or j == 3 then
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
		elseif j == 1 or j == 4 then
			for i = -1, 1 do
			for k = -1, 1 do
				if math.random(5) ~= 2 then
					local vil = area:index(x + i, y + j + 1, z + k)
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
					if math.random(7) ~= 2 then
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
					if math.random(11) ~= 2 then
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
					local vil = area:index(x + i, y + j, z + k)
					data[vil] = c_wsneedles
					local vila = area:index(x + i, y + j + 1, z + k)
					data[vila] = c_wsneedles
					local vilaa = area:index(x + i, y + j + 2, z + k)
					data[vilaa] = c_snowblock
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
	local c_wsaccleaf = minetest.get_content_id("watershed:acacialeaf")
	for j = -3, 6 do
		if j == 6 then
			for i = -4, 4 do
			for k = -4, 4 do
				if not (i == 0 or k == 0) then
					if math.random(7) ~= 2 then
						local vil = area:index(x + i, y + j, z + k)
						data[vil] = c_wsaccleaf
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
	"watershed:freshwater",
	"watershed:freshwaterflow",
	"watershed:bucket_freshwater",
	"watershed_bucketfreshwater.png",
	"WS Fresh Water Bucket"
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

-- Singlenode option

local SINODE = true

if SINODE then
	-- Set mapgen parameters

	minetest.register_on_mapgen_init(function(mgparams)
		minetest.set_mapgen_params({mgname="singlenode"})
	end)

	-- Spawn player

	function spawnplayer(player)
		local TERCEN = -160 -- Terrain 'centre', average seabed level
		local TERSCA = 512 -- Vertical terrain scale
		local ATANAMP = 1.2 -- Arctan function amplitude, smaller = more and larger floatlands above ridges
		local XLSAMP = 0.2 -- Extra large scale height variation amplitude
		local BASAMP = 0.4 -- Base terrain amplitude
		local CANAMP = 0.4 -- Canyon terrain amplitude
		local CANEXP = 1.33 -- Canyon shape exponent
		local xsp
		local ysp
		local zsp
		local np_rough = {
			offset = 0,
			scale = 1,
			spread = {x=512, y=512, z=512},
			seed = 593,
			octaves = 6,
			persist = 0.63
		}
		local np_smooth = {
			offset = 0,
			scale = 1,
			spread = {x=512, y=512, z=512},
			seed = 593,
			octaves = 6,
			persist = 0.3
		}
		local np_fault = {
			offset = 0,
			scale = 1,
			spread = {x=512, y=1024, z=512},
			seed = 14440002,
			octaves = 6,
			persist = 0.5
		}
		local np_base = {
			offset = 0,
			scale = 1,
			spread = {x=4096, y=4096, z=4096},
			seed = 8890,
			octaves = 4,
			persist = 0.4
		}
		local np_xlscale = {
			offset = 0,
			scale = 1,
			spread = {x=8192, y=8192, z=8192},
			seed = -72,
			octaves = 3,
			persist = 0.4
		}
		local np_temp = {
			offset = 0,
			scale = 1,
			spread = {x=512, y=512, z=512},
			seed = 9130,
			octaves = 2,
			persist = 0.5
		}
		local np_humid = {
			offset = 0,
			scale = 1,
			spread = {x=512, y=512, z=512},
			seed = -55500,
			octaves = 2,
			persist = 0.5
		}
		for chunk = 1, 32 do
			print ("[watershed] searching for spawn "..chunk)
			local x0 = 80 * math.random(-24, 24) - 32
			local z0 = 80 * math.random(-24, 24) - 32
			local y0 = -32
			local x1 = x0 + 79
			local z1 = z0 + 79
			local y1 = 47
	
			local sidelen = 80
			local chulens = {x=sidelen, y=sidelen, z=sidelen}
			local minposxyz = {x=x0, y=y0, z=z0}
			local minposxz = {x=x0, y=z0}

			local nvals_rough = minetest.get_perlin_map(np_rough, chulens):get3dMap_flat(minposxyz)
			local nvals_smooth = minetest.get_perlin_map(np_smooth, chulens):get3dMap_flat(minposxyz)
			local nvals_fault = minetest.get_perlin_map(np_fault, chulens):get3dMap_flat(minposxyz)
			local nvals_temp = minetest.get_perlin_map(np_temp, chulens):get3dMap_flat(minposxyz)
			local nvals_humid = minetest.get_perlin_map(np_humid, chulens):get3dMap_flat(minposxyz)

			local nvals_base = minetest.get_perlin_map(np_base, chulens):get2dMap_flat(minposxz)
			local nvals_xlscale = minetest.get_perlin_map(np_xlscale, chulens):get2dMap_flat(minposxz)
	
			local nixz = 1
			local nixyz = 1
			for z = z0, z1 do
				for y = y0, y1 do
					for x = x0, x1 do
						local grad = math.atan((TERCEN - y) / TERSCA) * ATANAMP
						local n_base = nvals_base[nixz]
						local densitybase = (1 - math.abs(n_base)) * BASAMP + nvals_xlscale[nixz] * XLSAMP + grad
						local terblen = math.max(1 - math.abs(n_base), 0)
						local n_temp = nvals_temp[nixyz]
						local n_humid = nvals_humid[nixyz]
						local density
						if nvals_fault[nixyz] >= 0 then
							density = densitybase
							+ math.abs(nvals_rough[nixyz] * terblen
							+ nvals_smooth[nixyz] * (1 - terblen)) ^ CANEXP * CANAMP * (1 + n_temp * 0.5)
						else	
							density = densitybase
							+ math.abs(nvals_rough[nixyz] * terblen
							+ nvals_smooth[nixyz] * (1 - terblen)) ^ CANEXP * CANAMP * (1 + n_humid * 0.5)
						end
						if y >= 1 and density > -0.01 and density < 0 then
							ysp = y + 1
							xsp = x
							zsp = z
							break
						end
						nixz = nixz + 1
						nixyz = nixyz + 1
					end
					if ysp then
						break
					end
					nixz = nixz - 80
				end
				if ysp then
					break
				end
				nixz = nixz + 80
			end
			if ysp then
				break
			end
		end
		print ("[watershed] spawn player ("..xsp.." "..ysp.." "..zsp..")")
		player:setpos({x=xsp, y=ysp, z=zsp})
	end

	minetest.register_on_newplayer(function(player)
		spawnplayer(player)
	end)

	minetest.register_on_respawnplayer(function(player)
		spawnplayer(player)
		return true
	end)
end