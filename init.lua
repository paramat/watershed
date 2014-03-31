-- watershed 0.2.15 by paramat
-- For latest stable Minetest and back to 0.4.8
-- Depends default
-- License: code WTFPL

-- register bucket water lava
-- remove leaves from leafdecay, grass function
-- appleleaf mod node
-- TODO
-- magma rising at ridges
-- all tree heights vary
-- fog
-- singlenode option

-- Parameters

local YMIN = 5000 -- Approximate base of realm stone
local YMAX = 9000 -- Approximate top of atmosphere / mountains / floatlands
local TERCEN = 6856 -- Terrain 'centre', average seabed level
local YWAT = 7016 -- Sea level
local YCLOUD = 7144 -- Cloud level

local TERSCA = 512 -- Vertical terrain scale
local XLSAMP = 0.2 -- Extra large scale height variation amplitude
local BASAMP = 0.4 -- Base terrain amplitude
local CANAMP = 0.4 -- Canyon terrain amplitude
local CANEXP = 1.33 -- Canyon shape exponent
local ATANAMP = 1.1 -- Arctan function amplitude, smaller = more and larger floatlands above ridges

local TSTONE = 0.01 -- Density threshold for stone, depth of soil at TERCEN
local TRIV = -0.015 -- Maximum densitybase threshold for river water
local TSAND = -0.018 -- Maximum densitybase threshold for river sand
local FIST = 0 -- Fissure threshold at surface, controls size of fissure entrances at surface
local FISEXP = 0.02 -- Fissure expansion rate under surface
local ORETHI = 0.001 -- Ore seam thickness tuner
local ORET = 0.02 -- Ore threshold for seam
local TCLOUD = 0.5 -- Cloud threshold

local HITET = 0.4 -- High temperature threshold
local LOTET = -0.4 -- Low ..
local ICETET = -0.8 -- Ice ..
local HIHUT = 0.4 -- High humidity threshold
local MIDHUT = 0 -- Mid ..
local LOHUT = -0.4 -- Low ..
local CLOHUT = 0 -- Cloud humidity threshold
local DCLOHUT = 1 -- Dark cloud ..

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
	persist = 0.3
}

-- 3D noise for faults

local np_fault = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=1024, z=512},
	seed = 14440002,
	octaves = 6,
	persist = 0.5
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

-- 3D noise for temperature

local np_temp = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	seed = 9130,
	octaves = 2,
	persist = 0.5
}

-- 3D noise for humidity

local np_humid = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	seed = -55500,
	octaves = 2,
	persist = 0.5
}

-- 3D noise for ore seams

local np_ore = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=128, z=512},
	seed = -992221,
	octaves = 2,
	persist = 0.5
}

-- 3D noise for rock strata

local np_strata = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=128, z=512},
	seed = 92219,
	octaves = 2,
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
	spread = {x=207, y=207, z=207},
	seed = 2113,
	octaves = 4,
	persist = 0.7
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
	
	-- make all nodes air except ores and strata, for testing
	
	--local c_air = minetest.get_content_id("air")
	--local c_water = minetest.get_content_id("air")
	--local c_sand = minetest.get_content_id("air")
	--local c_desand = minetest.get_content_id("air")
	--local c_snowblock = minetest.get_content_id("air")
	--local c_ice = minetest.get_content_id("air")
	--local c_dirtsnow = minetest.get_content_id("air")
	--local c_jungrass = minetest.get_content_id("air")
	--local c_dryshrub = minetest.get_content_id("air")
	--local c_clay = minetest.get_content_id("air")
	
	--local c_wswater = minetest.get_content_id("air")
	--local c_wsstone = minetest.get_content_id("air")
	--local c_wsredstone = minetest.get_content_id("air")
	--local c_wsgrass = minetest.get_content_id("air")
	--local c_wsdrygrass = minetest.get_content_id("air")
	--local c_wsgoldgrass = minetest.get_content_id("air")
	--local c_wsdirt = minetest.get_content_id("air")
	--local c_wscloud = minetest.get_content_id("air")
	--local c_wsdarkcloud = minetest.get_content_id("air")
	--local c_wspermafrost = minetest.get_content_id("air")
	
	local c_air = minetest.get_content_id("air")
	local c_water = minetest.get_content_id("default:water_source")
	local c_sand = minetest.get_content_id("default:sand")
	local c_desand = minetest.get_content_id("default:desert_sand")
	local c_snowblock = minetest.get_content_id("default:snowblock")
	local c_ice = minetest.get_content_id("default:ice")
	local c_dirtsnow = minetest.get_content_id("default:dirt_with_snow")
	local c_jungrass = minetest.get_content_id("default:junglegrass")
	local c_dryshrub = minetest.get_content_id("default:dry_shrub")
	local c_danwhi = minetest.get_content_id("flowers:dandelion_white")
	local c_danyel = minetest.get_content_id("flowers:dandelion_yellow")
	local c_rose = minetest.get_content_id("flowers:rose")
	local c_tulip = minetest.get_content_id("flowers:tulip")
	local c_geranium = minetest.get_content_id("flowers:geranium")
	local c_viola = minetest.get_content_id("flowers:viola")
	local c_stodiam = minetest.get_content_id("default:stone_with_diamond")
	local c_mese = minetest.get_content_id("default:mese")
	local c_stogold = minetest.get_content_id("default:stone_with_gold")
	local c_stocopp = minetest.get_content_id("default:stone_with_copper")
	local c_stoiron = minetest.get_content_id("default:stone_with_iron")
	local c_stocoal = minetest.get_content_id("default:stone_with_coal")
	local c_sandstone = minetest.get_content_id("default:sandstone")
	local c_gravel = minetest.get_content_id("default:gravel")
	local c_clay = minetest.get_content_id("default:clay")
	local c_grass5 = minetest.get_content_id("default:grass_5")
	
	local c_wswater = minetest.get_content_id("watershed:water")
	local c_wsstone = minetest.get_content_id("watershed:stone")
	local c_wsredstone = minetest.get_content_id("watershed:redstone")
	local c_wsgrass = minetest.get_content_id("watershed:grass")
	local c_wsdrygrass = minetest.get_content_id("watershed:drygrass")
	local c_wsgoldgrass = minetest.get_content_id("watershed:goldengrass")
	local c_wsdirt = minetest.get_content_id("watershed:dirt")
	local c_wscloud = minetest.get_content_id("watershed:cloud")
	local c_wsdarkcloud = minetest.get_content_id("watershed:darkcloud")
	local c_wspermafrost = minetest.get_content_id("watershed:permafrost")
	local c_wslava = minetest.get_content_id("watershed:lava")
	
	local sidelen = x1 - x0 + 1
	local chulens = {x=sidelen, y=sidelen+2, z=sidelen}
	local minposxyz = {x=x0, y=y0-1, z=z0}
	local minposxz = {x=x0, y=z0}
	
	local nvals_rough = minetest.get_perlin_map(np_rough, chulens):get3dMap_flat(minposxyz)
	local nvals_smooth = minetest.get_perlin_map(np_smooth, chulens):get3dMap_flat(minposxyz)
	local nvals_fault = minetest.get_perlin_map(np_fault, chulens):get3dMap_flat(minposxyz)
	local nvals_fissure = minetest.get_perlin_map(np_fissure, chulens):get3dMap_flat(minposxyz)
	local nvals_temp = minetest.get_perlin_map(np_temp, chulens):get3dMap_flat(minposxyz)
	local nvals_humid = minetest.get_perlin_map(np_humid, chulens):get3dMap_flat(minposxyz)
	local nvals_ore = minetest.get_perlin_map(np_ore, chulens):get3dMap_flat(minposxyz)
	local nvals_strata = minetest.get_perlin_map(np_strata, chulens):get3dMap_flat(minposxyz)
	
	local nvals_base = minetest.get_perlin_map(np_base, chulens):get2dMap_flat(minposxz)
	local nvals_xlscale = minetest.get_perlin_map(np_xlscale, chulens):get2dMap_flat(minposxz)
	local nvals_cloud = minetest.get_perlin_map(np_cloud, chulens):get2dMap_flat(minposxz)
	
	local ungen = false -- ungenerated chunk below?
	if minetest.get_node({x=x0, y=y0-1, z=z0}).name == "ignore" then
		ungen = true
		print ("[watershed] ungen")
	end
	
	local nixyz = 1
	local nixz = 1
	local stable = {}
	local under = {}
	for z = z0, z1 do -- for each xy plane progressing northwards
		for y = y0 - 1, y1 + 1 do -- for each x row progressing upwards
			local vi = area:index(x0, y, z)
			local viu = area:index(x0, y-1, z)
			for x = x0, x1 do -- for each node do
				local si = x - x0 + 1
				local grad = math.atan((TERCEN - y) / TERSCA) * ATANAMP
				local n_base = nvals_base[nixz]
				local terblen = math.max(1 - math.abs(n_base), 0)
				local densitybase = (1 - math.abs(n_base)) * BASAMP + nvals_xlscale[nixz] * XLSAMP + grad
				local altprop = (y - YWAT) / (TERCEN + TERSCA - YWAT)
				local triv = TRIV * (1 - altprop * 1.1)
				local tsand = TSAND * (1 - altprop * 1.1)
				local tstone = TSTONE * (1 - math.atan(altprop) * 0.6) -- 1 to 0.05
				local density
				if nvals_fault[nixyz] >= 0 then
					density = densitybase
					+ math.abs(nvals_rough[nixyz] * terblen
					+ nvals_smooth[nixyz] * (1 - terblen)) ^ CANEXP * CANAMP
				else	
					density = densitybase
					+ math.abs(nvals_rough[nixyz] * terblen
					- nvals_smooth[nixyz] * (1 - terblen)) ^ CANEXP * CANAMP
				end
				local nofis = false
				if density >= 0 then -- if terrain set fissure flag
					if math.abs(nvals_fissure[nixyz]) > FIST + math.sqrt(density) * FISEXP then
						nofis = true
					end
				end
				
				if y == y0 - 1 then -- node layer below chunk
					if ungen then
						if density >= 0 then -- if node solid
							stable[si] = 2
						else
							stable[si] = 0
						end
					else
						local nodename = minetest.get_node({x=x,y=y,z=z}).name
						if nodename == "watershed:stone"
						or nodename == "watershed:redstone"
						or nodename == "watershed:dirt"
						or nodename == "watershed:permafrost"
						or nodename == "default:sandstone"
						or nodename == "default:sand"
						or nodename == "default:desert_sand"
						or nodename == "default:gravel" then
							stable[si] = 2
						else
							stable[si] = 0
						end
					end
				elseif y >= y0 and y <= y1 then -- chunk
					local n_temp = nvals_temp[nixyz] -- get raw temp and humid noise for use with node
					local n_humid = nvals_humid[nixyz]
					local biome = false -- select biome for node
					if n_temp < LOTET then
						if n_humid < MIDHUT then
							biome = 1 -- tundra
						else
							biome = 2 -- taiga
						end
					elseif n_temp > HITET then
						if n_humid < LOHUT then
							biome = 6 -- desert
						elseif n_humid > HIHUT then
							biome = 8 -- rainforest
						else
							biome = 7 -- savanna
						end
					else
						if n_humid < LOHUT then
							biome = 3 -- dry grassland
						elseif n_humid > HIHUT then
							biome = 5 -- deciduous forest
						else
							biome = 4 -- grassland
						end
					end
				
					if density >= tstone and nofis  -- stone cut by fissures
					or (density >= tstone and density < TSTONE * 3 and y <= YWAT) -- stone around water
					or (density >= tstone and density < TSTONE * 3 and densitybase >= triv ) then -- stone around river
						local densitystr = nvals_strata[nixyz] / 4 + (TERCEN - y) / TERSCA
						local densityper = densitystr - math.floor(densitystr) -- periodic strata 'density'
						if (densityper >= 0 and densityper <= 0.04) -- sandstone strata
						or (densityper >= 0.2 and densityper <= 0.23)
						or (densityper >= 0.45 and densityper <= 0.47)
						or (densityper >= 0.7 and densityper <= 0.73)
						or (densityper >= 0.75 and densityper <= 0.77)
						or (densityper >= 0.84 and densityper <= 0.87)
						or (densityper >= 0.92 and densityper <= 0.95) then
							data[vi] = c_sandstone
						elseif biome == 6 and density < TSTONE * 3 then -- desert stone
							data[vi] = c_wsredstone
						elseif math.abs(nvals_ore[nixyz]) < ORET then -- if seam
							if densityper >= 0.9 and densityper <= 0.9 + ORETHI
							and math.random(23) == 2 then
								data[vi] = c_stodiam
							elseif densityper >= 0.8 and densityper <= 0.8 + ORETHI
							and math.random(17) == 2 then
								data[vi] = c_stogold
							elseif densityper >= 0.6 and densityper <= 0.6 + ORETHI * 4 then
								data[vi] = c_stocoal
							elseif densityper >= 0.5 and densityper <= 0.5 + ORETHI * 4 then
								data[vi] = c_gravel
							elseif densityper >= 0.4 and densityper <= 0.4 + ORETHI * 2
							and math.random(3) == 2 then
								data[vi] = c_stoiron
							elseif densityper >= 0.3 and densityper <= 0.3 + ORETHI * 2
							and math.random(5) == 2 then
								data[vi] = c_stocopp
							elseif densityper >= 0.1 and densityper <= 0.1 + ORETHI
							and math.random(19) == 2 then
								data[vi] = c_mese
							else
								data[vi] = c_wsstone
							end
						else
							data[vi] = c_wsstone
						end
						stable[si] = stable[si] + 1
						under[si] = 0
					elseif density >= 0 and density < tstone and stable[si] >= 2 then -- fine materials
						if y == YWAT - 2 and math.abs(n_temp) < 0.05 then -- clay
							data[vi] = c_clay
						elseif densitybase >= tsand + math.random() * 0.003 -- river / seabed sand not cut by fissures
						or y <= YWAT + 1 + math.random(2) then
							data[vi] = c_sand
						elseif nofis then -- fine materials cut by fissures
							if biome == 6 then
								data[vi] = c_desand
								under[si] = 6 -- desert
							elseif biome == 7 then
								data[vi] = c_wsdirt
								under[si] = 7 -- savanna
							elseif biome == 8 then
								data[vi] = c_wsdirt
								under[si] = 8 -- rainforest
							elseif biome == 3 then
								data[vi] = c_wsdirt
								under[si] = 3 -- dry grassland
							elseif biome == 4 then
								data[vi] = c_wsdirt
								under[si] = 4 -- grassland
							elseif biome == 5 then
								data[vi] = c_wsdirt
								under[si] = 5 -- forest
							elseif biome == 1 then
								data[vi] = c_wspermafrost
								under[si] = 1 -- tundra
							elseif biome == 2 then
								data[vi] = c_wsdirt
								under[si] = 2 -- taiga
							end
						else -- fissure
							stable[si] = 0
							under[si] = 0
						end
					elseif y <= YWAT and density < tstone then -- sea water, not in fissures
						if y == YWAT and n_temp < ICETET then
							data[vi] = c_ice
						else
							data[vi] = c_water
							if y == YWAT and biome >= 6 and stable[si] >= 1
							and math.random(PAPCHA) == 2 then -- papyrus in desert and rainforest
								watershed_papyrus(x, y, z, area, data)
							end
						end
						stable[si] = 0
						under[si] = 0
					elseif densitybase >= triv and density < tstone then -- river water, not in fissures
						if n_temp < ICETET then
							data[vi] = c_ice
						else
							data[vi] = c_wswater
						end
						stable[si] = 0
						under[si] = 0
					elseif y == YCLOUD then -- clouds
						local xrq = 16 * math.floor((x - x0) / 16) -- quantise to 16x16 lattice
						local zrq = 16 * math.floor((z - z0) / 16)
						local qixz = zrq * 80 + xrq + 1 -- quantised index
						if nvals_cloud[qixz] > TCLOUD then
							local yrq = 16 * math.floor((y - y0) / 16)
							local qixyz = zrq * 6400 + yrq * 80 + xrq + 1
							if nvals_humid[qixyz] > DCLOHUT then
								data[vi] = c_wsdarkcloud
							elseif nvals_humid[qixyz] > CLOHUT then
								data[vi] = c_wscloud
							end
						end
						stable[si] = 0
						under[si] = 0
					else -- possible above surface air node
						if y >= YWAT and under[si] ~= 0 then
							local fnoise = nvals_fissure[nixyz]
							if under[si] == 1 then
								if math.random(121) == 2 then
									data[viu] = c_dirtsnow
								elseif math.random(121) == 2 then
									data[viu] = c_ice
								else
									data[viu] = c_wsdrygrass
									if math.random(DRYCHA) == 2 then
										data[vi] = c_dryshrub
									end
								end
							elseif under[si] == 2 then
								if n_humid > HIHUT and math.random(PINCHA) == 2 then
									watershed_pinetree(x, y, z, area, data)
								else
									data[viu] = c_dirtsnow
									data[vi] = c_snowblock
								end
							elseif under[si] == 5 then
								if math.random(APTCHA) == 2 then
									watershed_appletree(x, y, z, area, data)
								else
									data[viu] = c_wsgrass
									if math.random(FLOCHA) == 2 then
										data[viu] = c_wsgrass
										watershed_flower(data, vi, fnoise)
									elseif math.random(FOGCHA) == 2 then
										data[viu] = c_wsgrass
										data[vi] = c_grass5
									end
								end
							elseif under[si] == 3 then
								data[viu] = c_wsdrygrass
								if math.random(GRACHA) == 2 then
									if math.random(5) == 2 then
										data[vi] = c_wsgoldgrass
									else
										data[vi] = c_dryshrub
									end
								end
							elseif under[si] == 4 then
								data[viu] = c_wsgrass
								if math.random(FLOCHA) == 2 then
									watershed_flower(data, vi, fnoise)
								elseif math.random(GRACHA) == 2 then
										data[vi] = c_grass5
								end
							elseif under[si] == 8 then
								if math.random(JUTCHA) == 2 then
									watershed_jungletree(x, y, z, area, data)
								else
									data[viu] = c_wsgrass
									if math.random(JUGCHA) == 2 then
										data[vi] = c_jungrass
									end
								end
							elseif under[si] == 7 then
								if math.random(ACACHA) == 2 then
									watershed_acaciatree(x, y, z, area, data)
								else
									data[viu] = c_wsdrygrass
									if math.random(GOGCHA) == 2 then
										data[vi] = c_wsgoldgrass
									end
								end
							elseif under[si] == 6 and n_temp < HITET + 0.1 then
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
				elseif y == y1 + 1 then -- plane of nodes above chunk
					if density < 0 and y >= YWAT + 1 and under[si] ~= 0 then -- if air above fine materials
						if under[si] == 1 then -- add surface nodes to chunk top layer
							if math.random(121) == 2 then
								data[viu] = c_dirtsnow
							elseif math.random(121) == 2 then
								data[viu] = c_ice
							else
								data[viu] = c_wsdrygrass
							end
						elseif under[si] == 2 then
							data[viu] = c_dirtsnow
						elseif under[si] == 5 then
							data[viu] = c_wsgrass
						elseif under[si] == 3 then
							data[viu] = c_wsdrygrass
						elseif under[si] == 4 then
							data[viu] = c_wsgrass
						elseif under[si] == 8 then
							data[viu] = c_wsgrass
						elseif under[si] == 7 then
							data[viu] = c_wsdrygrass
						end
					end
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