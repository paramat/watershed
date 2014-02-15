-- watershed 0.1.0 by paramat
-- For latest stable Minetest and back to 0.4.8
-- Depends default
-- License: code WTFPL

-- Parameters

local YMIN = 6000
local YMAX = 8000
local TERCEN = 7000 -- Terrain centre
local YWAT = 7256 -- Sea level
local TERSCA = 512 -- Vertical terrain scale
local TSTONE = 0.02 -- Density threshold for stone
local RINAMP = 0.5 -- Ridge noise amplitude
local RIDEXP = 1.2 -- Ridge exponent, controls sharpness of ridges
local TRIV = -0.08 -- Ridge density threshold for river water at sea level
local TEREXP = 0.8 -- Terrain exponent, controls shape of river canyons
local TERAMP = 0.5 -- Terrain amplitude relative to ridge

-- 3D noise for rough terrain

local np_terrough = {
	offset = 0,
	scale = 1,
	spread = {x=414, y=414, z=414},
	seed = 5900033,
	octaves = 6,
	persist = 0.6
}

-- 3D noise for smooth terrain

local np_terrsmoo = {
	offset = 0,
	scale = 1,
	spread = {x=414, y=414, z=414},
	seed = 5900033,
	octaves = 6,
	persist = 0.4
}

-- 3D noise for ridge noise

local np_terridge = {
	offset = 0,
	scale = 1,
	spread = {x=1024, y=1024, z=1024},
	seed = -4747,
	octaves = 3,
	persist = 0.4
}

-- 2D noise for ranges and terrain blend

local np_range = {
	offset = 0,
	scale = 1,
	spread = {x=2048, y=2048, z=2048}, -- spread is still stated with xyz values
	seed = -188900,
	octaves = 2,
	persist = 0.4
}

-- Stuff

watershed = {}

-- Nodes

minetest.register_node("watershed:stone", {
	description = "WS Stone",
	tiles = {"default_stone.png"},
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("watershed:water", {
	description = "WS Water Source",
	inventory_image = minetest.inventorycube("default_water.png"),
	drawtype = "liquid",
	tiles = {
		{name="default_water_source_animated.png", animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=2.0}}
	},
	alpha = WATER_ALPHA,
	paramtype = "light",
	is_ground_content = false,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	drop = "",
	drowning = 1,
	liquidtype = "source",
	liquid_alternative_flowing = "watershed:waterflow",
	liquid_alternative_source = "watershed:water",
	liquid_viscosity = WATER_VISC,
	liquid_renewable = false,
	liquid_range = 1,
	post_effect_color = {a=64, r=100, g=100, b=200},
	groups = {water=3, liquid=3, puts_out_fire=1},
})

minetest.register_node("watershed:waterflow", {
	description = "WS Flowing Water",
	inventory_image = minetest.inventorycube("default_water.png"),
	drawtype = "flowingliquid",
	tiles = {"default_water.png"},
	special_tiles = {
		{
			image="default_water_flowing_animated.png",
			backface_culling=false,
			animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=0.8}
		},
		{
			image="default_water_flowing_animated.png",
			backface_culling=true,
			animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=0.8}
		},
	},
	alpha = WATER_ALPHA,
	paramtype = "light",
	paramtype2 = "flowingliquid",
	is_ground_content = false,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	drop = "",
	drowning = 1,
	liquidtype = "flowing",
	liquid_alternative_flowing = "watershed:waterflow",
	liquid_alternative_source = "watershed:water",
	liquid_viscosity = WATER_VISC,
	liquid_renewable = false,
	liquid_range = 1,
	post_effect_color = {a=64, r=100, g=100, b=200},
	groups = {water=3, liquid=3, puts_out_fire=1, not_in_creative_inventory=1},
})

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
	local c_wsstone = minetest.get_content_id("watershed:stone")
	local c_sand = minetest.get_content_id("default:sand")
	local c_wswater = minetest.get_content_id("watershed:water")
	local c_water = minetest.get_content_id("default:water_source")
	
	local sidelen = x1 - x0 + 1
	local chulens = {x=sidelen, y=sidelen, z=sidelen}
	local minposxyz = {x=x0, y=y0, z=z0}
	local minposxz = {x=x0, y=z0}
	
	local nvals_terrough = minetest.get_perlin_map(np_terrough, chulens):get3dMap_flat(minposxyz)
	local nvals_terrsmoo = minetest.get_perlin_map(np_terrsmoo, chulens):get3dMap_flat(minposxyz)
	local nvals_terridge = minetest.get_perlin_map(np_terridge, chulens):get3dMap_flat(minposxyz)
	
	local nvals_range = minetest.get_perlin_map(np_range, chulens):get2dMap_flat(minposxz)
	
	local nixyz = 1
	local nixz = 1
	local stable = {}
	for z = z0, z1 do -- for each xy plane progressing northwards
		for x = x0, x1 do
			local si = x - x0 + 1
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
			for x = x0, x1 do -- for each node do
				local si = x - x0 + 1
				local ridge = 1 - math.abs(nvals_range[nixz]) ^ RIDEXP + nvals_terridge[nixyz] * RINAMP
				local grad = (TERCEN - y) / TERSCA
				local denridge = ridge + grad
				local terblen = math.max((1 - math.abs(nvals_range[nixz])), 0)
				local triv = TRIV * (1 - terblen)
				local density = ridge + grad
				+ math.abs(nvals_terrough[nixyz] * terblen + nvals_terrsmoo[nixyz] * (1 - terblen)) ^ TEREXP * TERAMP
				if density >= TSTONE then
					data[vi] = c_wsstone
					stable[si] = stable[si] + 1
				elseif density >= 0 and density < TSTONE and stable[si] >= 2 then
					data[vi] = c_sand
				elseif y <= YWAT then -- sea level water
					data[vi] = c_water
					stable[si] = 0
				elseif denridge >= triv then -- river water
					data[vi] = c_wswater
					stable[si] = 0
				else
					data[vi] = c_air
					stable[si] = 0
				end
				nixyz = nixyz + 1 -- increment 3D noise index
				nixz = nixz + 1 -- increment 2D noise index
				vi = vi + 1
			end
			nixz = nixz - 80 -- rewind 2D noise index by 80 nodes for next x row above
		end
		nixz = nixz + 80 -- fast-forward 2D noise index by 80 nodes for next northward xy plane
	end
	
	vm:set_data(data)
	vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map(data)
	local chugent = math.ceil((os.clock() - t1) * 1000)
	print ("[noise23] "..chugent.." ms")
end)