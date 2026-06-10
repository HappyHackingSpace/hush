cask "hush" do
  version "0.1.0"
  sha256 "REPLACE_WITH_DMG_SHA256"

  url "https://github.com/happyhackingspace/hush/releases/download/v#{version}/Hush.dmg"
  name "Hush"
  desc "Invisible, voice-following notch teleprompter for macOS"
  homepage "https://github.com/happyhackingspace/hush"

  depends_on macos: ">= :sonoma"

  app "Hush.app"

  zap trash: [
    "~/Library/Application Support/Hush",
    "~/Library/Preferences/com.happyhackingspace.hush.plist",
  ]
end
