-- watershed 0.3.12 by paramat
-- For latest stable Minetest and back to 0.4.8
-- Depends default bucket
-- License: code WTFPL, textures CC BY-SA
-- Red cobble texture CC BY-SA by brunob.santos

-- snowy iceberg only if humid enough
-- add rough alt, smooth alt noises for harmonic noise
-- persistence to 0.67 for rough noises
-- half scale of smooth noise for flatter lowlands
-- 1 less octave for smooth noise
-- fix sea ice in tundra at y = 47
-- removed snow from tundra
-- New icydirt surface node in tundra

-- Parameters

local YMIN = -33000 -- Approximate base of realm stone
local YMAX = 33000 -- Approximate top of atmosphere / mountains / floatlands
local TERCEN = -160 -- Terrain 'centre', average seabed level
local YWAT = 1 -- Sea surface y
local YSAV = 5 -- Average sandline y, dune grasses above this
local SAMP = 3 -- Sandline amplitude
local YCLOMIN = 207 -- Minimum height of mod clouds
local CLOUDS = true -- Mod clouds?

local TERSCA = 512 -- Vertical terrain scale
local XLSAMP = 0.2 -- Extra large scale height variation amplitude
local BASAMP = 0.4 -- Base terrain amplitude
local CANAMP = 0.4 -- Canyon terrain amplitude
local CANEXP = 1.33 -- Canyon shape exponent
local ATANAMP = 1.1 -- Arctan function amplitude, smaller = more and larger floatlands above ridges

local TSTONE = 0.02 -- Density threshold for stone, depth of soil at TERCEN
local TRIV = -0.02 -- Maximum densitybase threshold for river water
local TSAND = -0.025 -- Maximum densitybase threshold for river sand
local TLAVA = 2.3 -- Maximum densitybase threshold for lava, small because grad is non-linear
local FISEXP = 0.03 -- Fissure expansion rate under surface
local ORETHI = 0.002 -- Ore seam thickness tuner
local SEAMT = 0.2 -- Seam threshold, width of seams
local BERGDEP = 32 -- Maximum iceberg depth

local HITET = 0.35 -- High temperature threshold
local LOTET = -0.35 -- Low ..
local ICETET = -0.7 -- Ice ..
local HIHUT = 0.35 -- High humidity threshold
local LOHUT = -0.35 -- Low ..
local BLEND = 0.03 -- Biome blend randomness

local PINCHA = 36 -- Pine tree 1/x chance per node
local APTCHA = 36 -- Appletree
local FLOCHA = 36 -- Flower
local FOGCHA = 9 -- Forest grass
local GRACHA = 5 -- Grassland grasses
local JUTCHA = 16 -- Jungletree
local JUGCHA = 9 -- Junglegrass
local CACCHA = 841 -- Cactus
local DRYCHA = 169 -- Dry shrub
local PAPCHA = 2 -- Papyrus
local ACACHA = 841 -- Acacia tree
local GOGCHA = 5 -- Golden grass
local DUGCHA = 5 -- Dune grass

-- 3D noise for rough terrain

local np_rough = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	seed = 593,
	octaves = 6,
	persist = 0.67
}

-- 3D noise for smooth terrain

local np_smooth = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	seed = 593,
	octaves = 5,
	persist = 0.33
}

-- 3D noise for alt rough terrain

local np_roughalt = {
	offset = 0,
	scale = 1,
	spread = {x=414, y=414, z=414},
	seed = -9003,
	octaves = 6,
	persist = 0.67
}

-- 3D noise for alt smooth terrain

local np_smoothalt = {
	offset = 0,
	scale = 1,
	spread = {x=414, y=414, z=414},
	seed = -9003,
	octaves = 5,
	persist = 0.33
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
	octaves = 3,
	persist = 0.5
}

-- 3D noise for humidity

local np_humid = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	seed = -55500,
	octaves = 3,
	persist = 0.5
}

-- 3D noise for ore seam networks

local np_seam = {
	offset = 0,
	scale = 1,
	spread = {x=256, y=256, z=256},
	seed = -992221,
	octaves = 2,
	persist = 0.5
}

-- 3D noise for rock strata inclination

local np_strata = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	seed = 92219,
	octaves = 3,
	persist = 0.5
}

-- 2D noise for base terrain / riverbed height, terrain blend, river and river sand depth

local np_base = {
	offset = 0,
	scale = 1,
	spread = {x=4096, y=4096, z=4096},
	seed = 8890,
	octaves = 4,
	persist = 0.33
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

-- 2D noise for magma surface

local np_magma = {
	offset = 0,
	scale = 1,
	spread = {x=128, y=128, z=128},
	seed = -13,
	octaves = 2,
	persist = 0.5
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
	-- voxelmanip stuff
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip") -- min, max points for emerged area/voxelarea
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax} -- voxelarea helper for indexes
	local data = vm:get_data() -- get flat array of voxelarea content ids
	-- content ids
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
	local c_obsidian = minetest.get_content_id("default:obsidian")
	
	local c_wsfreshwater = minetest.get_content_id("watershed:freshwater")
	local c_wsstone = minetest.get_content_id("watershed:stone")
	local c_wsredstone = minetest.get_content_id("watershed:redstone")
	local c_wsgrass = minetest.get_content_id("watershed:grass")
	local c_wsdrygrass = minetest.get_content_id("watershed:drygrass")
	local c_wsgoldengrass = minetest.get_content_id("watershed:goldengrass")
	local c_wsdirt = minetest.get_content_id("watershed:dirt")
	local c_wspermafrost = minetest.get_content_id("watershed:permafrost")
	local c_wslava = minetest.get_content_id("watershed:lava")
	local c_wsfreshice = minetest.get_content_id("watershed:freshice")
	local c_wscloud = minetest.get_content_id("watershed:cloud")
	local c_wsluxoreoff = minetest.get_content_id("watershed:luxoreoff")
	local c_wsicydirt = minetest.get_content_id("watershed:icydirt")
	-- perlinmap stuff
	local sidelen = x1 - x0 + 1 -- chunk sidelength
	local chulens = {x=sidelen, y=sidelen+2, z=sidelen} -- chunk dimensions, '+2' for overgeneration
	local minposxyz = {x=x0, y=y0-1, z=z0} -- 3D and 2D perlinmaps start from these co-ordinates, '-1' for overgeneration
	local minposxz = {x=x0, y=z0}
	-- 3D and 2D perlinmaps
	local nvals_rough = minetest.get_perlin_map(np_rough, chulens):get3dMap_flat(minposxyz)
	local nvals_smooth = minetest.get_perlin_map(np_smooth, chulens):get3dMap_flat(minposxyz)
	local nvals_roughalt = minetest.get_perlin_map(np_roughalt, chulens):get3dMap_flat(minposxyz)
	local nvals_smoothalt = minetest.get_perlin_map(np_smoothalt, chulens):get3dMap_flat(minposxyz)
	local nvals_fissure = minetest.get_perlin_map(np_fissure, chulens):get3dMap_flat(minposxyz)
	local nvals_temp = minetest.get_perlin_map(np_temp, chulens):get3dMap_flat(minposxyz)
	local nvals_humid = minetest.get_perlin_map(np_humid, chulens):get3dMap_flat(minposxyz)
	local nvals_seam = minetest.get_perlin_map(np_seam, chulens):get3dMap_flat(minposxyz)
	local nvals_strata = minetest.get_perlin_map(np_strata, chulens):get3dMap_flat(minposxyz)
	
	local nvals_base = minetest.get_perlin_map(np_base, chulens):get2dMap_flat(minposxz)
	local nvals_xlscale = minetest.get_perlin_map(np_xlscale, chulens):get2dMap_flat(minposxz)
	local nvals_magma = minetest.get_perlin_map(np_magma, chulens):get2dMap_flat(minposxz)
	
	local ungen = false -- ungenerated chunk below?
	if minetest.get_node({x=x0, y=y0-1, z=z0}).name == "ignore" then
		ungen = true
	end
	-- mapgen loop
	local nixyz = 1 -- 3D and 2D perlinmap indexes
	local nixz = 1
	local stable = {} -- stability table of true/false. is node supported from below by 2 stone or nodes on 2 stone?
	local under = {} -- biome table. biome number of previous fine material placed in column
	for z = z0, z1 do -- for each xy plane progressing northwards
		for y = y0 - 1, y1 + 1 do -- for each x row progressing upwards
			local vi = area:index(x0, y, z) -- voxelmanip index for first node in this x row
			local viu = area:index(x0, y-1, z) -- index for under node
			for x = x0, x1 do -- for each node do
				local si = x - x0 + 1 -- stable, under tables index
				-- noise values for node
				local n_rough = nvals_rough[nixyz]
				local n_smooth = nvals_smooth[nixyz]
				local n_roughalt = nvals_roughalt[nixyz]
				local n_smoothalt = nvals_smoothalt[nixyz]
				local n_fissure = nvals_fissure[nixyz]
				local n_temp = nvals_temp[nixyz]
				local n_humid = nvals_humid[nixyz]
				local n_seam = nvals_seam[nixyz]
				local n_strata = nvals_strata[nixyz]
				
				local n_base = nvals_base[nixz]
				local n_xlscale = nvals_xlscale[nixz]
				local n_magma = nvals_magma[nixz]
				-- get densitybase and density
				local grad = math.atan((TERCEN - y) / TERSCA) * ATANAMP -- vertical density gradient
				local densitybase = (1 - math.abs(n_base)) * BASAMP + n_xlscale * XLSAMP + grad -- base terrain
				local terblen = math.max(1 - math.abs(n_base), 0) -- canyon terrain blend of rough and smooth
				local density = densitybase + -- add canyon terrain
				math.abs((n_rough + n_roughalt) * 0.5 * terblen +
				(n_smooth + n_smoothalt) * 0.25 * (1 - terblen)) ^ CANEXP * CANAMP
				-- other values
				local triv = TRIV * (1 - terblen) -- river threshold
				local tsand = TSAND * (1 - terblen) -- sand threshold
				local tstone = TSTONE * (1 + grad * 0.5) -- stone threshold
				local tlava = TLAVA * (1 - n_magma ^ 4 * terblen ^ 16 * 0.5) -- lava threshold
				local ysand = YSAV + n_fissure * SAMP + math.random() * 2 -- sandline
				local bergdep = math.abs(n_seam) * BERGDEP -- iceberg depth
				
				local nofis = false -- set fissure bool
				if math.abs(n_fissure) > math.sqrt(density) * FISEXP then
					nofis = true
				end
				
				local biome = false -- select biome for node
				if n_temp < LOTET + (math.random() - 0.5) * BLEND then
					if n_humid < LOHUT + (math.random() - 0.5) * BLEND then
						biome = 1 -- tundra
					elseif n_humid > HIHUT + (math.random() - 0.5) * BLEND then
						biome = 3 -- taiga
					else
						biome = 2 -- snowy plains
					end
				elseif n_temp > HITET + (math.random() - 0.5) * BLEND then
					if n_humid < LOHUT + (math.random() - 0.5) * BLEND then
						biome = 7 -- desert
					elseif n_humid > HIHUT + (math.random() - 0.5) * BLEND then
						biome = 9 -- rainforest
					else
						biome = 8 -- savanna
					end
				else
					if n_humid < LOHUT then
						biome = 4 -- dry grassland
					elseif n_humid > HIHUT then
						biome = 6 -- deciduous forest
					else
						biome = 5 -- grassland
					end
				end
				
				-- overgeneration and in-chunk generation
				if y == y0 - 1 then -- node layer below chunk, initialise tables
					under[si] = 0 -- 0 to stop floating surface nodes bug
					if ungen then
						if nofis and density >= 0 then -- if node solid
							stable[si] = 2
						else
							stable[si] = 0
						end
					else -- scan top layer of chunk below
						local nodename = minetest.get_node({x=x,y=y,z=z}).name
						if nodename == "watershed:stone"
						or nodename == "watershed:redstone"
						or nodename == "watershed:dirt"
						or nodename == "watershed:permafrost"
						or nodename == "watershed:luxoreoff"
						or nodename == "default:sand"
						or nodename == "default:desert_sand"
						or nodename == "default:mese"
						or nodename == "default:stone_with_diamond"
						or nodename == "default:stone_with_gold"
						or nodename == "default:stone_with_copper"
						or nodename == "default:stone_with_iron"
						or nodename == "default:stone_with_coal"
						or nodename == "default:sandstone"
						or nodename == "default:gravel"
						or nodename == "default:clay"
						or nodename == "default:obsidian" then
							stable[si] = 2
						else
							stable[si] = 0
						end
					end
				elseif y >= y0 and y <= y1 then -- chunk
					-- add nodes and flora
					if densitybase >= tlava then -- lava
						if densitybase >= 0 then
							data[vi] = c_wslava
						end
						stable[si] = 0
						under[si] = 0
					elseif densitybase >= tlava - math.min(0.6 + density * 6, 0.6) and density < tstone then -- obsidian
						data[vi] = c_obsidian
						stable[si] = 1
						under[si] = 0
					elseif density >= tstone and nofis  -- stone cut by fissures
					or (density >= tstone and density < TSTONE * 2 and y <= YWAT) -- stone around water
					or (density >= tstone and density < TSTONE * 2 and densitybase >= triv ) then -- stone around river
						local densitystr = n_strata * 0.25 + (TERCEN - y) / TERSCA
						local densityper = densitystr - math.floor(densitystr) -- periodic strata 'density'
						if (densityper >= 0.05 and densityper <= 0.09) -- sandstone strata
						or (densityper >= 0.25 and densityper <= 0.28)
						or (densityper >= 0.45 and densityper <= 0.47)
						or (densityper >= 0.74 and densityper <= 0.76)
						or (densityper >= 0.77 and densityper <= 0.79)
						or (densityper >= 0.84 and densityper <= 0.87)
						or (densityper >= 0.95 and densityper <= 0.98) then
							data[vi] = c_sandstone
						elseif biome == 7 and density < TSTONE * 4 then -- desert stone as surface layer
							data[vi] = c_wsredstone
						elseif math.abs(n_seam) < SEAMT then
							if densityper >= 0 and densityper <= ORETHI * 4 then -- ore seams
								data[vi] = c_stocoal
							elseif densityper >= 0.3 and densityper <= 0.3 + ORETHI * 4 then
								data[vi] = c_stocoal
							elseif densityper >= 0.5 and densityper <= 0.5 + ORETHI * 4 then
								data[vi] = c_stocoal
							elseif densityper >= 0.8 and densityper <= 0.8 + ORETHI * 4 then
								data[vi] = c_stocoal
							elseif densityper >= 0.55 and densityper <= 0.55 + ORETHI * 2 then
								data[vi] = c_gravel
							elseif densityper >= 0.1 and densityper <= 0.1 + ORETHI * 2 then
								data[vi] = c_wsluxoreoff
							elseif densityper >= 0.2 and densityper <= 0.2 + ORETHI * 2
							and math.random(2) == 2 then
								data[vi] = c_stoiron
							elseif densityper >= 0.65 and densityper <= 0.65 + ORETHI * 2
							and math.random(2) == 2 then
								data[vi] = c_stoiron
							elseif densityper >= 0.4 and densityper <= 0.4 + ORETHI * 2
							and math.random(3) == 2 then
								data[vi] = c_stocopp
							elseif densityper >= 0.6 and densityper <= 0.6 + ORETHI
							and math.random(5) == 2 then
								data[vi] = c_stogold
							elseif densityper >= 0.7 and densityper <= 0.7 + ORETHI
							and math.random(7) == 2 then
								data[vi] = c_mese
							elseif densityper >= 0.9 and densityper <= 0.9 + ORETHI
							and math.random(11) == 2 then
								data[vi] = c_stodiam
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
						elseif y <= ysand then -- seabed/beach/dune sand not cut by fissures
							data[vi] = c_sand
							under[si] = 10 -- beach/dunes
						elseif densitybase >= tsand + math.random() * 0.003 then -- river sand not cut by fissures
							data[vi] = c_sand
							under[si] = 11 -- riverbank
						elseif nofis then -- fine materials cut by fissures
							if biome == 1 then
								data[vi] = c_wspermafrost
								under[si] = 1 -- tundra
							elseif biome == 2 then
								data[vi] = c_wsdirt
								under[si] = 2 -- snowy plains
							elseif biome == 3 then
								data[vi] = c_wsdirt
								under[si] = 3 -- taiga
							elseif biome == 4 then
								data[vi] = c_wsdirt
								under[si] = 4 -- dry grassland
							elseif biome == 5 then
								data[vi] = c_wsdirt
								under[si] = 5 -- grassland
							elseif biome == 6 then
								data[vi] = c_wsdirt
								under[si] = 6 -- forest
							elseif biome == 7 then
								data[vi] = c_desand
								under[si] = 7 -- desert
							elseif biome == 8 then
								data[vi] = c_wsdirt
								under[si] = 8 -- savanna
							elseif biome == 9 then
								data[vi] = c_wsdirt
								under[si] = 9 -- rainforest
							end
						else -- fissure
							stable[si] = 0
							under[si] = 0
						end
					elseif y >= YWAT - bergdep and y <= YWAT + bergdep / 8 and n_temp < ICETET -- iceberg
					and density < tstone and math.abs(n_fissure) > 0.01 then
						data[vi] = c_ice
						under[si] = 12
						stable[si] = 0
					elseif y <= YWAT and density < tstone then -- sea water
						data[vi] = c_water
						under[si] = 0
						stable[si] = 0
					elseif densitybase >= triv and density < tstone then -- river water not in fissures
						if n_temp < ICETET then
							data[vi] = c_wsfreshice
						else
							data[vi] = c_wsfreshwater
						end
						stable[si] = 0
						under[si] = 0
					elseif CLOUDS and y == y1 and y >= YCLOMIN then -- clouds
						local xrq = 16 * math.floor((x - x0) / 16) -- quantise to 16x16 lattice
						local zrq = 16 * math.floor((z - z0) / 16)
						local yrq = 79
						local qixyz = zrq * 6400 + yrq * 80 + xrq + 1 -- quantised 3D index
						if math.abs(nvals_fissure[qixyz]) < nvals_humid[qixyz] * 0.1 then
							data[vi] = c_wscloud
						end
						stable[si] = 0
						under[si] = 0
					else -- possible above surface air node
						if y > YWAT and under[si] ~= 0 then
							local fnoise = n_fissure -- noise for flower colours
							if under[si] == 1 then
								data[viu] = c_wsicydirt
								if math.random(DRYCHA) == 2 then
									data[vi] = c_dryshrub
								end
							elseif under[si] == 2 then
								data[viu] = c_dirtsnow
								data[vi] = c_snowblock
							elseif under[si] == 3 then
								if math.random(PINCHA) == 2 then
									watershed_pinetree(x, y, z, area, data)
								else
									data[viu] = c_dirtsnow
									data[vi] = c_snowblock
								end
							elseif under[si] == 4 then
								data[viu] = c_wsdrygrass
								if math.random(GRACHA) == 2 then
									if math.random(5) == 2 then
										data[vi] = c_wsgoldengrass
									else
										data[vi] = c_dryshrub
									end
								end
							elseif under[si] == 5 then
								data[viu] = c_wsgrass
								if math.random(FLOCHA) == 2 then
									watershed_flower(data, vi, fnoise)
								elseif math.random(GRACHA) == 2 then
										data[vi] = c_grass5
								end
							elseif under[si] == 6 then
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
							elseif under[si] == 7 and n_temp < HITET + 0.1 then
								if math.random(CACCHA) == 2 then
									watershed_cactus(x, y, z, area, data)
								elseif math.random(DRYCHA) == 2 then
									data[vi] = c_dryshrub
								end
							elseif under[si] == 8 then
								if math.random(ACACHA) == 2 then
									watershed_acaciatree(x, y, z, area, data)
								else
									data[viu] = c_wsdrygrass
									if math.random(GOGCHA) == 2 then
										data[vi] = c_wsgoldengrass
									end
								end
							elseif under[si] == 9 then
								if math.random(JUTCHA) == 2 then
									watershed_jungletree(x, y, z, area, data)
								else
									data[viu] = c_wsgrass
									if math.random(JUGCHA) == 2 then
										data[vi] = c_jungrass
									end
								end
							elseif under[si] == 10 then -- dunes
								if math.random(DUGCHA) == 2 and y > YSAV 
								and biome >= 4 then
									data[vi] = c_wsgoldengrass
								end
							elseif under[si] == 11 and n_temp > HITET then -- hot biome riverbank
								if math.random(PAPCHA) == 2 then
									watershed_papyrus(x, y, z, area, data)
								end
							elseif under[si] == 12 and n_humid > LOHUT then -- snowy iceberg
								data[vi] = c_snowblock
							end
						end
						stable[si] = 0
						under[si] = 0
					end
				elseif y == y1 + 1 then -- plane of nodes above chunk
					if density < 0 and y >= YWAT + 1 and under[si] ~= 0 then -- if air above fine materials
						if under[si] == 1 then -- add surface nodes to chunk top layer
							data[viu] = c_wsicydirt
						elseif under[si] == 2 then
							data[viu] = c_dirtsnow
						elseif under[si] == 3 then
							data[viu] = c_dirtsnow
						elseif under[si] == 4 then
							data[viu] = c_wsdrygrass
						elseif under[si] == 5 then
							data[viu] = c_wsgrass
						elseif under[si] == 6 then
							data[viu] = c_wsgrass
						elseif under[si] == 8 then
							data[viu] = c_wsdrygrass
						elseif under[si] == 9 then
							data[viu] = c_wsgrass
						end
					end
				end
				nixyz = nixyz + 1 -- increment perlinmap and voxelarea indexes along x row
				nixz = nixz + 1
				vi = vi + 1
				viu = viu + 1
			end
			nixz = nixz - 80
		end
		nixz = nixz + 80
	end
	-- voxelmanip stuff
	vm:set_data(data)
	vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map(data)
	
	local chugent = math.ceil((os.clock() - t1) * 1000) -- chunk generation time
	print ("[watershed] "..chugent.." ms")
end)