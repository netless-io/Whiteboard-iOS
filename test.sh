device=`xcrun xctrace list devices 2>&1 | grep -oE 'iPad.*.*Simulator.*1[3-9].*[)]+' | head -1 | grep -oE 'iPad.+?)' | head -1`
xcodebuild \
  -workspace Example/Whiteboard.xcworkspace \
  -scheme Whiteboard_Tests \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPad Air (5th generation)' \
  test \
  | xcbeautify