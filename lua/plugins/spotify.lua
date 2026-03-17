local function artist_names(track)
  return table.concat(
    vim.tbl_map(function(artist)
      return artist.name
    end, track.artists or {}),
    ", "
  )
end

local function url_encode(value)
  return (value:gsub("([^%w%-_%.~])", function(char)
    return string.format("%%%02X", string.byte(char))
  end))
end

local function get_device_id()
  local response = require("spotify.api").call("/me/player/devices")
  local devices = response and response.devices or {}

  if #devices == 0 then
    vim.notify("Spotify: no devices found. Open Spotify first.", vim.log.levels.WARN)
    return nil
  end

  for _, device in ipairs(devices) do
    if device.is_active then
      return device.id
    end
  end

  return devices[1].id
end

local function append_query_param(endpoint, name, value)
  local separator = endpoint:find("?", 1, true) and "&" or "?"
  return string.format("%s%s%s=%s", endpoint, separator, name, value)
end

local function with_device(endpoint)
  local device_id = get_device_id()
  if not device_id then
    return nil
  end

  return append_query_param(endpoint, "device_id", device_id)
end

local function spotify_next()
  local endpoint = with_device("/me/player/next")
  if not endpoint then
    return
  end

  require("spotify.api").call(endpoint, "post")
  vim.notify("Spotify: skipped to the next track")
end

local function spotify_previous()
  local endpoint = with_device("/me/player/previous")
  if not endpoint then
    return
  end

  require("spotify.api").call(endpoint, "post")
  vim.notify("Spotify: moved to the previous track")
end

local function spotify_unpause()
  local endpoint = with_device("/me/player/play")
  if not endpoint then
    return
  end

  require("spotify.api").call(endpoint, "put")
  vim.notify("Spotify: resumed playback")
end

local function spotify_pause()
  local endpoint = with_device("/me/player/pause")
  if not endpoint then
    return
  end

  require("spotify.api").call(endpoint, "put")
  vim.notify("Spotify: paused playback")
end

local function search_tracks(query)
  local endpoint = string.format("/search?q=%s&type=track&limit=10", url_encode(query))
  local response = require("spotify.api").call(endpoint)

  if not response or not response.tracks then
    return {}
  end

  return response.tracks.items or {}
end

local function play_track(track)
  local endpoint = with_device("/me/player/play")
  if not endpoint then
    return
  end

  require("spotify.api").call(endpoint, "put", {
    uris = { track.uri },
  })

  vim.notify(string.format('Spotify: playing "%s" by %s', track.name, artist_names(track)))
end

local function queue_track(track)
  local endpoint = with_device(append_query_param("/me/player/queue", "uri", url_encode(track.uri)))
  if not endpoint then
    return
  end

  require("spotify.api").call(endpoint, "post")
  vim.notify(string.format('Spotify: queued "%s" by %s', track.name, artist_names(track)))
end

local function choose_track(query, on_choice)
  local trimmed_query = vim.trim(query or "")
  if trimmed_query == "" then
    return
  end

  local tracks = search_tracks(trimmed_query)
  if #tracks == 0 then
    vim.notify(string.format('Spotify: no tracks found for "%s"', trimmed_query), vim.log.levels.WARN)
    return
  end

  vim.ui.select(tracks, {
    prompt = "Choose Spotify track",
    format_item = function(track)
      return string.format("%s - %s (%s)", artist_names(track), track.name, track.album.name)
    end,
  }, function(choice)
    if choice then
      on_choice(choice)
    end
  end)
end

local function play_song(query)
  choose_track(query, play_track)
end

local function queue_song(query)
  choose_track(query, queue_track)
end

local function prompt_for_song(action)
  vim.ui.input({ prompt = "Spotify song: " }, function(input)
    if input and vim.trim(input) ~= "" then
      action(input)
    end
  end)
end

return {
  "ElijahBare/spotify.nvim-fixed",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("spotify").setup({
      client_id = "797f6a8126374489994e095f10781b5c",
      client_secret = "5c639ad31e37416d858f6e767cfaa87f",
    })

    vim.keymap.set("n", "<leader>mn", spotify_next, { desc = "Spotify next track" })
    vim.keymap.set("n", "<leader>mb", spotify_previous, { desc = "Spotify previous track" })
    vim.keymap.set("n", "<leader>mp", spotify_pause, { desc = "Spotify pause" })
    vim.keymap.set("n", "<leader>mu", spotify_unpause, { desc = "Spotify unpause" })
    vim.keymap.set("n", "<leader>ms", function()
      prompt_for_song(play_song)
    end, { desc = "Spotify search and play" })
    vim.keymap.set("n", "<leader>mq", function()
      prompt_for_song(queue_song)
    end, { desc = "Spotify search and queue" })

    vim.api.nvim_create_user_command("SpotifyNext", spotify_next, {
      desc = "Skip to the next Spotify track",
      force = true,
    })

    vim.api.nvim_create_user_command("SpotifyPrevious", spotify_previous, {
      desc = "Go to the previous Spotify track",
      force = true,
    })

    vim.api.nvim_create_user_command("SpotifyPause", spotify_pause, {
      desc = "Pause Spotify playback",
      force = true,
    })

    vim.api.nvim_create_user_command("SpotifyUnpause", spotify_unpause, {
      desc = "Start Spotify playback",
      force = true,
    })

    vim.api.nvim_create_user_command("SpotifyPlaySong", function(opts)
      if vim.trim(opts.args) == "" then
        prompt_for_song(play_song)
        return
      end

      play_song(opts.args)
    end, {
      desc = "Search for and play a Spotify song",
      force = true,
      nargs = "*",
    })

    vim.api.nvim_create_user_command("SpotifyQueueSong", function(opts)
      if vim.trim(opts.args) == "" then
        prompt_for_song(queue_song)
        return
      end

      queue_song(opts.args)
    end, {
      desc = "Search for and add a Spotify song to the queue",
      force = true,
      nargs = "*",
    })
  end,
}
