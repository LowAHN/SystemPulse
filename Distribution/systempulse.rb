cask "systempulse" do
  version "1.0.0"
  sha256 "PLACEHOLDER_SHA256"

  url "https://github.com/LowAHN/SystemPulse/releases/download/v#{version}/SystemPulse.dmg"
  name "SystemPulse"
  desc "Lightweight macOS menu bar system monitor"
  homepage "https://github.com/LowAHN/SystemPulse"

  depends_on macos: ">= :ventura"

  app "SystemPulse.app"

  zap trash: [
    "~/Library/Preferences/com.systempulse.app.plist",
  ]
end
