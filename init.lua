-- watershed 0.2.3 by paramat
-- For latest stable Minetest and back to 0.4.8
-- Depends default
-- License: code WTFPL

-- 0.2.3 clouds, cacti, ice, papyrus, dry shrubs
-- savanna with acacias, dry grass surface nodes and golden grass
-- arctan density gradient for floatlands and caves

-- Parameters

local YMIN = 6000 -- Approximate base of realm stone
local YMAX = 8000 -- Approximate top of atmosphere / mountains / floatlands
local TERCEN = 6960 -- Terrain 'centre'. Approximate average seabed level
local YWAT = 7024 -- Sea level
local CLOUDY = 7152 -- Cloud level

local TERSCA = 384 -- Vertical terrain scale
local XLSAMP = 0 -- Extra large scale height variation amplitude
local BASAMP = 0.3 -- Base terrain amplitude
local CANAMP = 0.7 -- Canyon terrain amplitude
local CANEXP = 1.33 -- Canyon shape exponent
local ATANAMP = 1.4 -- Arctan function amplitude. Controls size and number of floatlands / caves

local TSTONE = 0.02 -- Density threshold for stone
local TRIV = -0.017 -- Maximum densitybase threshold for river water
local TSAND = -0.02 -- Maximum densitybase threshold for sand
local FIST = 0 -- Fissure threshold at surface. Controls size of fissure entrances at surface
local FISEXP = 0.02 -- Fissure expansion rate under surface
local ORECHA = 1 / (7 * 7 * 7) -- Ore chance per stone node
local CLOUT = 0.5 -- Cloud threshold

local PINCHA = 47 -- Pine tree 1/x chance per node
local APTCHA = 47 -- Appletree
local FLOCHA = 36 -- Flower
local FOGCHA = 9 -- Forest grass
local GRACHA = 3 -- Grassland grasses
local JUTCHA = 16 -- Jungletree
local JUGCHA = 9 -- Junglegrass
local CACCHA = 841 -- Cactus
local DRYCHA = 169 -- Dry shrub
local PAPCHA = 3 -- Papyrus
local ACACHA = 841 -- Acacia tree
local GOGCHA = 3 -- Golden grass

-- 3D noise for rough terrain

local np_rough = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	seed = 593,
	octaves = 6,
	persist = 0.63
}

-- 3D noise for smooth terrain

local np_smooth = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	seed = 593,
	octaves = 6,
	persist = 0.4
}

-- 3D noise for fissures

local np_fissure = {
	offset = 0,
	scale = 1,
	spread = {x=256, y=512, z=256},
	seed = 20099,
	octaves = 5,
	persist = 0.5
}

-- 2D noise for base terrain / riverbed height / mountain ranges, terrain blend, river and river sand depth

local np_base = {
	offset = 0,
	scale = 1,
	spread = {x=4096, y=4096, z=4096},
	seed = 8890,
	octaves = 4,
	persist = 0.4
}

-- 2D noise for biomes

local np_biome = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	seed = -677772,
	octaves = 3,
	persist = 0.5
}

-- 2D noise for extra large scale height variation

local np_xlscale = {
	offset = 0,
	scale = 1,
	spread = {x=8192, y=8192, z=8192},
	seed = -72,
	octaves = 3,
	persist = 0.4
}

-- 2D noise for clouds

local np_cloud = {
	offset = 0,
	scale = 1,
	spread = {x=104, y=104, z=104},
	seed = 2113,
	octaves = 3,
	persist = 0.9
}

-- Stuff

watershed = {}

dofile(minetest.get_modpath("watershed").."/nodes.lua")
dofile(minetest.get_modpath("watershed").."/functions.lua")

-- On generated function

minetest.register_on_generated(function(minp, maxp, seed)
	if minp.y < YMIN or maxp.y > YMAX then
		return
	end

	local t1 = os.clock()
	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z
	
	print ("[watershed] chunk minp ("..x0.." "..y0.." "..z0..")")
	
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()
	
	local c_air = minetest.get_content_id("air")
	local c_water = minetest.get_content_id("default:water_source")
	local c_sand = minetest.get_content_id("default:sand")
	local c_desand = minetest.get_content_id("default:desert_sand")
	local c_snowblock = minetest.get_content_id("default:snowblock")
	local c_ice = minetest.get_content_id("default:ice")
	local c_dirtsnow = minetest.get_content_id("default:dirt_with_snow")
	local c_jungrass = minetest.get_content_id("default:junglegrass")
	local c_dryshrub = minetest.get_content_id("default:dry_shrub")
	local c_stodiam = minetest.get_content_id("default:stone_with_diamond")
	local c_stomese = minetest.get_content_id("default:stone_with_mese")
	local c_stogold = minetest.get_content_id("default:stone_with_gold")
	local c_stocopp = minetest.get_content_id("default:stone_with_copper")
	local c_stoiron = minetest.get_content_id("default:stone_with_iron")
	local c_stocoal = minetest.get_content_id("default:stone_with_coal")
	
	local c_wswater = minetest.get_content_id("watershed:water")
	local c_wsstone = minetest.get_content_id("watershed:stone")
	local c_wsredstone = minetest.get_content_id("watershed:redstone")
	local c_wsgrass = minetest.get_content_id("watershed:grass")
	local c_wsdrygrass = minetest.get_content_id("watershed:drygrass")
	local c_wsgoldgrass = minetest.get_content_id("watershed:goldengrass")
	local c_wsdirt = minetest.get_content_id("watershed:dirt")
	local c_wscloud = minetest.get_content_id("watershed:cloud")
	
	local sidelen = x1 - x0 + 1
	local chulens = {x=sidelen, y=sidelen, z=sidelen}
	local minposxyz = {x=x0, y=y0, z=z0}
	local minposxz = {x=x0, y=z0}
	
	local nvals_rough = minetest.get_perlin_map(np_rough, chulens):get3dMap_flat(minposxyz)
	local nvals_smooth = minetest.get_perlin_map(np_smooth, chulens):get3dMap_flat(minposxyz)
	local nvals_fissure = minetest.get_perlin_map(np_fissure, chulens):get3dMap_flat(minposxyz)
	
	local nvals_base = minetest.get_perlin_map(np_base, chulens):get2dMap_flat(minposxz)
	local nvals_biome = minetest.get_perlin_map(np_biome, chulens):get2dMap_flat(minposxz)
	local nvals_xlscale = minetest.get_perlin_map(np_xlscale, chulens):get2dMap_flat(minposxz)
	local nvals_cloud = minetest.get_perlin_map(np_cloud, chulens):get2dMap_flat(minposxz)
	
	local nixyz = 1
	local nixz = 1
	local stable = {}
	local under = {}
	for z = z0, z1 do -- for each xy plane progressing northwards
		for x = x0, x1 do
			local si = x - x0 + 1
			under[si] = 0
			local nodename = minetest.get_node({x=x,y=y0-1,z=z}).name
			if nodename == "air"
			or nodename == "default:water_source" then
				stable[si] = 0
			else
				stable[si] = 2
			end
		end
		for y = y0, y1 do -- for each x row progressing upwards
			local vi = area:index(x0, y, z)
			local viu = area:index(x0, y-1, z)
			for x = x0, x1 do -- for each node do
				local si = x - x0 + 1
				local grad = math.atan((TERCEN - y) / TERSCA) * ATANAMP
				local n_base = nvals_base[nixz]
				local n_biome = nvals_biome[nixz]
				local terblen = 1 - math.abs(n_base)
				local densitybase = terblen * BASAMP + nvals_xlscale[nixz] * XLSAMP + grad
				local triv = TRIV * (1 - terblen * 1.1) -- 1.1 river disappears before ridge top
				local tsand = TSAND * (1 - terblen * 1.1)
				local tstone = TSTONE * (1 + grad)
				local density = densitybase
				+ math.abs(nvals_rough[nixyz] * terblen + nvals_smooth[nixyz] * (1 - terblen)) ^ CANEXP * CANAMP
				
				local nofis = false
				if density >= 0 then -- if terrain set fissure flag
					if math.abs(nvals_fissure[nixyz]) > FIST + math.sqrt(density) * FISEXP then
						nofis = true
					end
				end
				
				if density >= tstone and nofis  -- stone cut by fissures
				or (density >= tstone and density < TSTONE * 3 and y <= YWAT) -- or stone layer around water
				or (density >= tstone and density < TSTONE * 3 and densitybase >= triv ) then -- or stone layer around river
					if n_biome > 0.8 then
						data[vi] = c_wsredstone
					elseif math.random() < ORECHA then
						local osel = math.random(34)
						if osel == 34 then
							data[vi] = c_stodiam
						elseif osel >= 31 then
							data[vi] = c_stomese
						elseif osel >= 28 then
							data[vi] = c_stogold
						elseif osel >= 19 then
							data[vi] = c_stocopp
						elseif osel >= 10 then
							data[vi] = c_stoiron
						else
							data[vi] = c_stocoal
						end
					else
						data[vi] = c_wsstone
					end
					stable[si] = stable[si] + 1
					under[si] = 0
				elseif density >= 0 and density < tstone and stable[si] >= 2 then -- fine materials
					if densitybase >= tsand or y <= YWAT + 1 + math.random(2) then -- river / seabed not cut by fissures
						data[vi] = c_sand
					elseif nofis then -- fine materials cut by fissures
						if n_biome > 0.8 then
							data[vi] = c_desand
							under[si] = 6 -- desert
						elseif n_biome > 0.4 then
							data[vi] = c_wsdirt
							under[si] = 5 -- savanna
						elseif n_biome > 0 then
							data[vi] = c_wsdirt
							under[si] = 4 -- rainforest
						elseif n_biome > -0.4 then
							data[vi] = c_wsdirt
							under[si] = 3 -- grassland
						elseif n_biome > -0.8 then
							data[vi] = c_wsdirt
							under[si] = 2 -- forest
						else
							data[vi] = c_wsdirt
							under[si] = 1 -- taiga
						end
					else -- fissure
						stable[si] = 0
						under[si] = 0
					end
				elseif y <= YWAT and density < tstone then -- sea water, not in fissures
					if y == YWAT and n_biome < -1 then
						data[vi] = c_ice
					else
						data[vi] = c_water
						if y == YWAT and n_biome > 0.2 and stable[si] >= 1
						and math.random(PAPCHA) == 2 then -- papyrus in desert and rainforest
							watershed_papyrus(x, y, z, area, data)
						end
					end
					stable[si] = 0
					under[si] = 0
				elseif densitybase >= triv and density < tstone then -- river water, not in fissures
					if n_biome < -1 then
						data[vi] = c_ice
					else
						data[vi] = c_wswater
					end
					stable[si] = 0
					under[si] = 0
				elseif y == CLOUDY then -- clouds
					local xrq = 16 * math.floor((x - x0) / 16)
					local zrq = 16 * math.floor((z - z0) / 16)
					local qixz = zrq * sidelen + xrq + 1
					if nvals_cloud[qixz] > CLOUT then
						data[vi] = c_wscloud
					end
					stable[si] = 0
					under[si] = 0
				else -- possible above surface air node
					if y >= YWAT and under[si] ~= 0 then
						if under[si] == 1 then
							if n_biome > -1 and math.random(PINCHA) == 2 then
								watershed_pinetree(x, y, z, area, data)
							else
								data[viu] = c_dirtsnow
								data[vi] = c_snowblock
							end
						elseif under[si] == 2 then
							if math.random(APTCHA) == 2 then
								watershed_appletree(x, y, z, area, data)
							else
								data[viu] = c_wsgrass
								if math.random(FLOCHA) == 2 then
									data[viu] = c_wsgrass
									watershed_flower(data, vi)
								elseif math.random(FOGCHA) == 2 then
									data[viu] = c_wsgrass
									watershed_grass(data, vi)
								end
							end
						elseif under[si] == 3 then
							data[viu] = c_wsgrass
							if math.random(GRACHA) == 2 then
								if math.random(3) == 2 then
									watershed_grass(data, vi)
								else
									data[vi] = c_jungrass
								end
							end
						elseif under[si] == 4 then
							if math.random(JUTCHA) == 2 then
								watershed_jungletree(x, y, z, area, data)
							else
								data[viu] = c_wsgrass
								if math.random(JUGCHA) == 2 then
									data[vi] = c_jungrass
								end
							end
						elseif under[si] == 5 then
							if math.random(ACACHA) == 2 then
								watershed_acaciatree(x, y, z, area, data)
							else
								data[viu] = c_wsdrygrass
								if math.random(GOGCHA) == 2 then
									data[vi] = c_wsgoldgrass
								end
							end
						elseif under[si] == 6 and n_biome < 1 then
							if math.random(CACCHA) == 2 then
								watershed_cactus(x, y, z, area, data)
							elseif math.random(DRYCHA) == 2 then
								data[vi] = c_dryshrub
							end
						end
					end
					stable[si] = 0
					under[si] = 0
				end
				nixyz = nixyz + 1
				nixz = nixz + 1
				vi = vi + 1
				viu = viu + 1
			end
			nixz = nixz - 80
		end
		nixz = nixz + 80
	end
	
	vm:set_data(data)
	vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map(data)
	local chugent = math.ceil((os.clock() - t1) * 1000)
	print ("[watershed] "..chugent.." ms")
end)