# 📜 README 📜
This is a simple script for your server. This is easy to use.

# ⚒️ INSALL ⚒️
- First you have to download a release of the script
- Then, open the config.lua and change the Strings/configs
- Import the SQL in your database by using the import.sql file

# ⚠️ REQUIREMENTS ⚠️
- This script require nothing

# 🤖 COMMANDS 🤖
- /jail <-- open the jail menu

# ⚙️ EXPORTS/EVENTS ⚙️
- Send a player in jail:
  ```lua
  local reason = "Freekill"
  local time = 600 --time in seconds
  local playerId = source --the server id of the player
  TriggerServerEvent('av_jailsystem:JailPlayer', playerId, time, reason)
  ```
- Unjail a player
  ```lua
  local id = playerId -- the id can be the PlayerServerId or the player license (ex b8b4b81e0bc79b2fb05bd12ba8479da07625a27b)
  TriggerServerEvent("av_jailsystem:unJail", id)
  ```

# ❤️ THANKS ❤️
- thank you to [Rvhhost](https://rvhhost.fr "The best hosting for everyone") for lending me a server <3
