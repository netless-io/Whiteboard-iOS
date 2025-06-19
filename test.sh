# outpath
# 忽略测试: （这些测试在本地通过就可以)
# testZoomChange， 这个方法跟机器性能有关，有可能动画过慢，取值不对。
# testGetRoomMember, 这个方法在并发的时候会有错误
# WebCrashTest，模拟器上的memory 过大，无法crash
# PerformTest，只在有需要的时候才测试
OUTPATH=$1
SCHEME=Whiteboard_Tests
xcodebuild \
  -workspace Example/Whiteboard.xcworkspace \
  -scheme $SCHEME \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,name=iPadTest" \
  -skip-testing:$SCHEME/RoomTests/testZoomChange \
  -skip-testing:$SCHEME/RoomTests/testGetRoomMember \
  -skip-testing:$SCHEME/WebCrashTest \
  -skip-testing:$SCHEME/RoomPerformTest \
  test | xcbeautify > $OUTPATH

test_result=${PIPESTATUS[0]}
if [[ "$test_result" != "0" ]]
then
  echo "TEST FAIL SEE $OUTPATH"
  exit 1
fi