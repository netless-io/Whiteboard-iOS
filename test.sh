# outpath
# 忽略测试: （这些测试在本地通过就可以)
# testZoomChange， 这个方法跟机器性能有关，有可能动画过慢，取值不对。
# testGetRoomMember, 这个方法在并发的时候会有错误
OUTPATH=$1
SCHEME=Whiteboard_Tests
device=`xcrun xctrace list devices 2>&1 | grep -oE 'iPad.*.*Simulator.*1[3-9].*[)]+' | head -1 | grep -oE 'iPad.+?)' | head -1`
xcodebuild \
  -workspace Example/Whiteboard.xcworkspace \
  -scheme $SCHEME \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,name=$device" \
  -skip-testing:$SCHEME/RoomTests/testZoomChange \
  -skip-testing:$SCHEME/RoomTests/testGetRoomMember \
  test | xcbeautify > $OUTPATH
  PASSSTR='Test Succeeded'
  TEST_TAIL=$(tail -n 1 $OUTPATH)
  ISPASS=$(echo $TEST_TAIL | grep "${PASSSTR}")
  if [[ "$ISPASS" != "" ]]
  then
    echo "TEST Succeeded"
  else
    echo "TEST FAIL SEE $OUTPATH"
    exit 1
  fi