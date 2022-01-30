-------------------------------------------------
--  Copyleft 2019-2022 Joe Koop                --
--  https://github.com/jkoop/better-bookmarks  --
-------------------------------------------------

local storage = minetest.get_mod_storage()
local betterBookmarks = {
	waypoints = {}
}

function betterBookmarks.removeWaypointIfPlayerIsClose()
	for playerName, waypointId in pairs(betterBookmarks.waypoints) do
		local player = minetest.get_player_by_name(playerName)

		if not player then
			betterBookmarks.waypoints[playerName] = nil
		else
			local waypoint = player:hud_get(waypointId)

			if player and waypoint then
				local playerPos = player:get_pos()
				local waypointPos = waypoint.world_pos

				if playerPos and waypointPos then
					local distance = vector.distance(playerPos, waypointPos)
					local record = betterBookmarks.getRecord(playerName .. '.' .. waypoint.name)
					local shouldRemove = distance < 5

					if record then
						shouldRemove = shouldRemove or minetest.pos_to_string(record.position) ~= minetest.pos_to_string(waypointPos)
					else
						shouldRemove = true
					end

					if shouldRemove then
						minetest.chat_send_player(playerName, "Removed waypoint for bookmark " .. waypoint.name)
						player:hud_remove(waypointId)
					end
				end
			end
		end
	end
end

function betterBookmarks.setRecord(longBookmarkName, playerName, position)
	if not (longBookmarkName and position) then
		return false
	end

	local record = betterBookmarks.getRecord(longBookmarkName) or {}
	record.position = position

	if not record.playerNames then
		record.playerNames = {}
	end

	record.playerNames[playerName] = true

	storage:set_string(longBookmarkName, minetest.serialize(record))

	if longBookmarkName ~= playerName .. ".-" then
		minetest.log("action", "[better_bookmarks] set bookmark " .. longBookmarkName .. " to " .. minetest.pos_to_string(position, 0))
	end

	return true
end

function betterBookmarks.getRecord(longBookmarkName)
	if not longBookmarkName then
		return false
	end

	return minetest.deserialize(storage:get_string(longBookmarkName)) or false
end

function betterBookmarks.delRecord(longBookmarkName)
	if not longBookmarkName then
		return false
	end

	local record = betterBookmarks.getRecord(longBookmarkName)

	if not record then
		return false
	else
		storage:set_string(longBookmarkName, '')
		return true
	end
end

function betterBookmarks.listRecords(playerName)
	local records = {}

	for longBookmarkName, record in pairs(storage:to_table()['fields']) do
		record = minetest.deserialize(record)

		if record.playerNames[playerName] then
			records[longBookmarkName] = record
		end
	end

	return records
end

function betterBookmarks.sendToBookmark(player, displayName, position)
	if not (player and displayName and position) then
		return false
	end

	if minetest.check_player_privs(player, "better_bookmarks_teleport") or minetest.check_player_privs(player, "teleport") then
		-- teleport to bookmark
		player:set_pos(position)
		return true, "Teleported to bookmark " .. displayName
	else
		-- show waypoint for bookmark
		if betterBookmarks.waypoints[player:get_player_name()] then
			player:hud_remove(betterBookmarks.waypoints[player:get_player_name()])
		end

		betterBookmarks.waypoints[player:get_player_name()] = player:hud_add({
			hud_elem_type = "waypoint",
			name = displayName,
			text = " blocks away",
			number = 0x00FF00, -- full green
			world_pos = position,
		})

		return true, "Now showing waypoint for bookmark " .. displayName
	end
end

function betterBookmarks.setBookmark(playerName, bookmarkName)
	if bookmarkName == "" then
		return false, "Bookmark name is required"
	end

	if string.find(bookmarkName, '%.') then -- string.find looks for patterns, not strings
		return false, 'Bookmark names cannot contain "."'
	end

	if bookmarkName == "-" then
		return false, 'Bookmark "-" is reserved for where you were when you last successfully ran /bm'
	end

	local player = minetest.get_player_by_name(playerName)

	-- player can't set bookmark if they're not in the world
	if not minetest.is_player(player) then
		return false, "You are not online"
	end

	local playerPosition = player:get_pos()

	if betterBookmarks.setRecord(playerName .. '.' .. bookmarkName, playerName, playerPosition) then
		return true, "Set bookmark " .. bookmarkName .. " to " .. minetest.pos_to_string(playerPosition, 0)
	else
		return false, "Couldn't set bookmark. This is a bug"
	end
end

function betterBookmarks.goToBookmark(playerName, bookmarkName)
	if bookmarkName == "" then
		return false, "Bookmark name is required"
	end

	local record = betterBookmarks.getRecord(playerName .. '.' .. bookmarkName)
	local player = minetest.get_player_by_name(playerName)

	if record then
		betterBookmarks.setRecord(playerName .. '.-', playerName, player:get_pos())
		return betterBookmarks.sendToBookmark(player, bookmarkName, record.position)
	else
		return false, "Bookmark " .. bookmarkName .. " not found"
	end
end

function betterBookmarks.deleteBookmark(playerName, bookmarkName)
	if bookmarkName == "" then
		return false, "Bookmark name is required"
	end

	if bookmarkName == "-" then
		return false, 'Bookmark "-" is reserved for where you were when you last successfully ran /bm'
	end

	local success = betterBookmarks.delRecord(playerName .. '.' .. bookmarkName)

	if success then
		return true, "Removed bookmark " .. bookmarkName
	else
		return false, "Bookmark " .. bookmarkName .. " not found"
	end
end

function betterBookmarks.listBookmarks(playerName)
	local bookmarks = ''
	local records = betterBookmarks.listRecords(playerName)
	local player = minetest.get_player_by_name(playerName)

	for longBookmarkName, record in pairs(records) do
		local bookmarkName = longBookmarkName:match(playerName .. '.(.+)')

		if not player then
			bookmarks = bookmarks .. bookmarkName .. ' at ' .. minetest.pos_to_string(record.position, 0) .. '\n'
		else
			local distance = math.floor(vector.distance(player:get_pos(), record.position) + 0.5) -- round to nearest integer
			bookmarks = bookmarks .. bookmarkName .. ' at ' .. minetest.pos_to_string(record.position, 0) .. ', ' .. distance .. ' blocks away\n'
		end
	end

	if bookmarks == '' then
		return false, "You don't have any bookmarks"
	else
		return true, bookmarks
	end
end

minetest.register_chatcommand("bmset", {
	params = "<bookmark-name>",
	description = 'Set a bookmark to your current position. Bookmark names may not contain "."',
	func = betterBookmarks.setBookmark
})

minetest.register_chatcommand("bm", {
	params = "<bookmark-name>",
	description = 'Go to bookmark. "-" is where you were when you last successfully ran /bm',
	func = betterBookmarks.goToBookmark
})

minetest.register_chatcommand("bmdel", {
	params = "<bookmark-name>",
	description = "Delete a bookmark",
	func = betterBookmarks.deleteBookmark
})

minetest.register_chatcommand("bmls", {
	-- params = "",
	description = "List all your bookmarks",
	func = betterBookmarks.listBookmarks
})

minetest.register_globalstep(betterBookmarks.removeWaypointIfPlayerIsClose)

minetest.register_privilege("better_bookmarks_teleport", {
	description = "Teleport player to bookmark instead of showing waypoint",
	give_to_singleplayer = false, -- options, man
	give_to_admin = false,
})

-- migrate from old format --

local function migrateFromOldFormat()
	local GONETWORK = {}
	local gonfile = io.open(minetest.get_worldpath() .. '/bookmarks.dat', "r")

	if gonfile then
		local contents = gonfile:read()
		io.close(gonfile)

		if contents ~= nil then
			local users = contents:split("}")

			for h,user in pairs(users) do
				local player, bookmarks = unpack(user:split("{"))
				GONETWORK[player] = {}
				local entries = bookmarks:split(")")

				for i,entry in pairs(entries) do
					local goname, coords = unpack(entry:split("("))
					local p = {}
					p.x, p.y, p.z = string.match(coords, "^([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)$")

					if p.x and p.y and p.z then
						GONETWORK[player][goname] = {x = tonumber(p.x),y= tonumber(p.y),z = tonumber(p.z)}
					end
				end
			end
		end
	end

	for playerName, bookmarks in pairs(GONETWORK) do
		for bookmarkName, position in pairs(bookmarks) do
			betterBookmarks.setRecord(playerName .. '.' .. bookmarkName, playerName, position)
		end
	end

	os.rename(minetest.get_worldpath() .. '/bookmarks.dat', minetest.get_worldpath() .. '/bookmarks.dat.' .. os.time() .. '.old')
end

migrateFromOldFormat();
