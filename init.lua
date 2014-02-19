-- watershed 0.2.1 by paramat
-- For latest stable Minetest and back to 0.4.8
-- Depends default
-- License: code WTFPL

-- Parameters

local YMIN = 6000
local YMAX = 8000 -- Top of atmosphere / mountains / floatlands
local TERCEN = 7008 -- Terrain centre
local YWAT = 7104 -- Sea level
local TERSCA = 512 -- Vertical terrain scale
local XLSAMP = 0 -- Extra large scale height variation amplitude
local BASAMP = 0.3 -- Base terrain amplitude
local CANAMP = 0.7 -- Canyon terrain amplitude
local CANEXP = 1.33 -- Canyon shape exponent
local TSTONE = 0.015 -- Density threshold for stone
local TRIV = -0.027 -- Maximum densitybase threshold for river water
local TSAND = -0.03 -- Maximum densitybase threshold for sand

local PINCHA = 47
local APTCHA = 47
local FLOCHA = 36
local FOGCHA = 9
local GRACHA = 5
local JUTCHA = 16
local JUGCHA = 9

-- 3D noise for rough terrain

local np_rough = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	seed = 593,
	octaves = 6,
	persist = 0.63
}

-- 3D alt noise for rough terrain

local np_roughalt = {
	offset = 0,
	scale = 1,
	spread = {x=828, y=828, z=828},
	seed = -7,
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

-- 3D alt noise for smooth terrain

local np_smoothalt = {
	offset = 0,
	scale = 1,
	spread = {x=828, y=828, z=828},
	seed = -7,
	octaves = 6,
	persist = 0.4
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
	local c_dirtsnow = minetest.get_content_id("default:dirt_with_snow")
	local c_jungrass = minetest.get_content_id("default:junglegrass")
	
	local c_wswater = minetest.get_content_id("watershed:water")
	local c_wsstone = minetest.get_content_id("watershed:stone")
	local c_wsredstone = minetest.get_content_id("watershed:redstone")
	local c_wsgrass = minetest.get_content_id("watershed:grass")
	local c_wsdirt = minetest.get_content_id("watershed:dirt")
	
	local sidelen = x1 - x0 + 1
	local chulens = {x=sidelen, y=sidelen, z=sidelen}
	local minposxyz = {x=x0, y=y0, z=z0}
	local minposxz = {x=x0, y=z0}
	
	local nvals_rough = minetest.get_perlin_map(np_rough, chulens):get3dMap_flat(minposxyz)
	local nvals_smooth = minetest.get_perlin_map(np_smooth, chulens):get3dMap_flat(minposxyz)
	local nvals_roughalt = minetest.get_perlin_map(np_roughalt, chulens):get3dMap_flat(minposxyz)
	local nvals_smoothalt = minetest.get_perlin_map(np_smoothalt, chulens):get3dMap_flat(minposxyz)
	
	local nvals_base = minetest.get_perlin_map(np_base, chulens):get2dMap_flat(minposxz)
	local nvals_biome = minetest.get_perlin_map(np_biome, chulens):get2dMap_flat(minposxz)
	local nvals_xlscale = minetest.get_perlin_map(np_xlscale, chulens):get2dMap_flat(minposxz)
	
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
				local grad = (TERCEN - y) / TERSCA
				local n_base = nvals_base[nixz]
				local n_biome = nvals_biome[nixz]
				local terblen = 1 - math.abs(n_base)
				local densitybase = terblen * BASAMP + nvals_xlscale[nixz] * XLSAMP + grad
				local triv = TRIV * (1 - terblen * 1.1) -- 1.1 river disappears before ridge top
				local tsand = TSAND * (1 - terblen * 1.1)
				local tstone = TSTONE * (1 + grad * 1.5)
				local density = densitybase + math.abs(
					(nvals_rough[nixyz] + nvals_roughalt[nixyz]) / 2 * terblen
					+ (nvals_smooth[nixyz] + nvals_smoothalt[nixyz]) / 2 * (1 - terblen)
				) ^ CANEXP * CANAMP
				
				if density >= tstone then -- stone
					if n_biome > 0.7 then
						data[vi] = c_wsredstone
					else
						data[vi] = c_wsstone
					end
					stable[si] = stable[si] + 1
				elseif density >= 0 and density < tstone and stable[si] >= 2 then -- fine materials
					if densitybase >= tsand or y <= YWAT + 1 + math.random(2) then
						data[vi] = c_sand -- riverbed, seabed
					else
						if n_biome > 0.7 then
							data[vi] = c_desand
							under[si] = 5 -- desert
						elseif n_biome > 0.2 then
							data[vi] = c_wsdirt
							under[si] = 4 -- rainforest
						elseif n_biome > -0.2 then
							data[vi] = c_wsdirt
							under[si] = 3 -- grassland
						elseif n_biome > -0.7 then
							data[vi] = c_wsdirt
							under[si] = 2 -- forest
						else
							data[vi] = c_wsdirt
							under[si] = 1 -- taiga
						end
					end
				elseif y <= YWAT then -- sea level water
					data[vi] = c_water
					stable[si] = 0
					under[si] = 0
				elseif densitybase >= triv then -- river water
					data[vi] = c_wswater
					stable[si] = 0
					under[si] = 0
				else -- possible above surface air node
					if y >= YWAT and under[si] ~= 0 then
						if under[si] == 1 then
							if math.random(PINCHA) == 2 then
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