# outpath
# 忽略测试
# testZoomChange， 这个方法跟机器性能有关，有可能动画过慢，取值不对。
OUTPATH=$1
SCHEME=Whiteboard_Tests
device=`xcrun xctrace list devices 2>&1 | grep -oE 'iPad.*.*Simulator.*1[3-9].*[)]+' | head -1 | grep -oE 'iPad.+?)' | head -1`
xcodebuild \
  -workspace Example/Whiteboard.xcworkspace \
  -scheme $SCHEME \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,name=$device" \
  -skip-testing:$SCHEME/RoomTests/testZoomChange \
  test | xcbeautify > $OUTPATH
  PASSSTR='Tests Passed'
  TEST_TAIL=$(tail -n 1 $OUTPATH)
  ISPASS=$(echo $TEST_TAIL | grep "${PASSSTR}")
  if [[ "$ISPASS" != "" ]]
  then
    echo "TEST PASS"
  else
    echo "TEST FAIL SEE $OUTPATH"
    exit 1
  fi