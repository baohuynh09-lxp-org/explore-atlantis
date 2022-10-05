#!/bin/bash
echo "Enable SSH"
sudo defaults write /var/db/launchd.db/com.apple.launchd/overrides.plist com.apple.screensharing -dict Disabled -bool false
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist
if [ -d /Users/Shared/websockify ]; then
  echo "Setup was done"
else
  brew install nginx
  brew install certbot
  pip3 install numpy
  pushd /Users/Shared
  git clone https://github.com/novnc/websockify.git
  pushd websockify
  python3 setup.py install
  popd
  popd
fi
