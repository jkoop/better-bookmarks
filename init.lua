-------------------------------------------------
--  Copyleft 2019-2022 Joe Koop                --
--  https://github.com/jkoop/better-bookmarks  --
-------------------------------------------------

local storage = minetest.get_mod_storage()
local betterBookmarks = {}

function betterBookmarks.setRecord(longBookmarkName, playerName, position)
	if not (longBookmarkName and position) then
		return false
	end

	local record = betterBookmarks.getRecord(longBookmarkName) or {}
	record.position = minetest.string_to_pos(minetest.pos_to_string(position, 2)) -- round the position to 2 decimal places

	if not record.playerNames then
		record.playerNames = {}
	end

	record.playerNames[playerName] = true

	storage:set_string(longBookmarkName, minetest.serialize(record))

	minetest.log("action", "[better_bookmarks] set bookmark " .. longBookmarkName .. " to " .. minetest.pos_to_string(position, 0))
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

function betterBookmarks.setBookmark(playerName, bookmarkName)
	if bookmarkName == "" or string.find(bookmarkName, '%.') then -- string.find looks for patterns, not strings
		return false, "Invalid usage, see /help bmset."
	end

	local player = minetest.get_player_by_name(playerName)

	-- player can't set bookmark if they're not in the world
	if not minetest.is_player(player) then
		return false, "You are not online."
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
		return false, "Invalid usage, see /help bm"
	end

	local bookmarkPosition = betterBookmarks.getRecord(playerName .. '.' .. bookmarkName)
	local player = minetest.get_player_by_name(playerName)

	player:set_pos(bookmarkPosition.position)

	if bookmarkPosition then
		return true, "Teleported to bookmark " .. bookmarkName
	else
		return false, "Bookmark " .. bookmarkName .. " not found"
	end
end

function betterBookmarks.deleteBookmark(playerName, bookmarkName)
	if bookmarkName == "" then
		return false, "Invalid usage, see /help bmdel"
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

	for longBookmarkName, record in pairs(records) do
		local bookmarkName = longBookmarkName:match(playerName .. '.(.+)')
		bookmarks = bookmarks .. bookmarkName .. ' at ' .. minetest.pos_to_string(record.position, 0) .. '\n'
	end

	if bookmarks == '' then
		return false, "You don't have any bookmarks"
	else
		return true, bookmarks
	end
end

minetest.register_chatcommand("bmset", {
	params = "bookmark-name",
	description = "Set a bookmark. Bookmark names cannot contain '.'",
	func = betterBookmarks.setBookmark
})

minetest.register_chatcommand("bm", {
	params = "bookmark-name",
	description = "Go to a bookmark",
	func = betterBookmarks.goToBookmark
})

minetest.register_chatcommand("bmdel", {
	params = "bookmark-name",
	description = "Delete a bookmark",
	func = betterBookmarks.deleteBookmark
})

minetest.register_chatcommand("bmls", {
	-- params = "",
	description = "List all your bookmarks",
	func = betterBookmarks.listBookmarks
})
