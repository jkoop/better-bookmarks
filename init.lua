-------------------------------------------------
--  Copyleft 2019-2022 Joe Koop                --
--  https://github.com/jkoop/better-bookmarks  --
-------------------------------------------------

-- using memory, not disk, during development
bookmarks = {}

local function writeBookmark(longBookmarkName, position)
	if not (longBookmarkName and position) then
		return false
	end

	-- set the bookmark
	bookmarks[longBookmarkName] = position

	minetest.log("action", "[better_bookmarks] set bookmark " .. longBookmarkName .. " to " .. minetest.pos_to_string(position, 0))

	return true
end

local function readBookmark(longBookmarkName)
	if not longBookmarkName then
		return false
	end

	return bookmarks[longBookmarkName] or false
end

local function setBookmark(playerName, bookmarkName)
	if bookmarkName == "" then
		return false, "Invalid usage, see /help bmset."
	end

	local player = minetest.get_player_by_name(playerName)

	-- player can't set bookmark if they're not in the world
	if not minetest.is_player(player) then
		return false, "You are not online."
	end

	local playerPosition = player.get_pos(player) -- <- that's anoying

	if writeBookmark(playerName .. '.' .. bookmarkName, playerPosition) then
		return true, "Bookmark set."
	else
		return false, "Couldn't set bookmark. This is a bug."
	end
end

local function goToBookmark(playerName, bookmarkName)
	if bookmarkName == "" then
		return false, "Invalid usage, see /help bm."
	end

	local player = minetest.get_player_by_name(playerName)

	local bookmarkPosition = readBookmark(playerName .. '.' .. bookmarkName)

	if bookmarkPosition then
		return true, minetest.pos_to_string(bookmarkPosition, 0)
	else
		return false, "Couldn't get bookmark."
	end
end

minetest.register_chatcommand("bmset", {
	params = "bookmark-name",
	description = "Set a bookmark",
	func = setBookmark
})

minetest.register_chatcommand("bm", {
	params = "bookmark-name",
	description = "Go to a bookmark",
	func = goToBookmark
})
