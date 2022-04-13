#!/bin/sh

# Download
curl -o fpa.zip https://download.agora.io/sdk/release/AgoraFpaService_for_iOS_v1.0.0.zip
unzip fpa.zip

BUILD_SDK=15
IS_DYNAMIC=true

IPHONEOS_DIR=armv7_arm64
SIMULATOR_DIR=simulator_x86_64_arm64

mkdir $SIMULATOR_DIR
mkdir $IPHONEOS_DIR

function xcframeworkFrom {
    PATH=$1
    NAME=$2
    FILE_NAME=$(/usr/bin/basename $PATH)
    MIN=$(/usr/libexec/PlistBuddy -c "Print :MinimumOSVersion" $PATH/Info.plist)
    /bin/rm -rf $FILE_NAME

    #iPhone
    /bin/cp -rf $PATH $IPHONEOS_DIR/$FILE_NAME
    /usr/bin/lipo -remove x86_64 $IPHONEOS_DIR/$FILE_NAME/$NAME -o $IPHONEOS_DIR/$FILE_NAME/$NAME

    #simulator
    /bin/cp -rf $PATH $SIMULATOR_DIR/$FILE_NAME
    /usr/bin/lipo -thin arm64 $SIMULATOR_DIR/$FILE_NAME/$NAME -o $SIMULATOR_DIR/$FILE_NAME/$NAME-arm64
    /usr/bin/lipo -remove arm64 $SIMULATOR_DIR/$FILE_NAME/$NAME -o $SIMULATOR_DIR/$FILE_NAME/$NAME
    /usr/bin/lipo -remove armv7 $SIMULATOR_DIR/$FILE_NAME/$NAME -o $SIMULATOR_DIR/$FILE_NAME/$NAME-x86_64
    ./arm64-to-sim $SIMULATOR_DIR/$FILE_NAME/$NAME-arm64 $MIN $BUILD_SDK $IS_DYNAMIC
    /bin/rm $SIMULATOR_DIR/$FILE_NAME/$NAME
    /usr/bin/lipo -create $SIMULATOR_DIR/$FILE_NAME/$NAME-x86_64 $SIMULATOR_DIR/$FILE_NAME/$NAME-arm64 -o $SIMULATOR_DIR/$FILE_NAME/$NAME
    /bin/rm $SIMULATOR_DIR/$FILE_NAME/$NAME-x86_64
    /bin/rm $SIMULATOR_DIR/$FILE_NAME/$NAME-arm64

    #Info.Plist
    /usr/libexec/PlistBuddy -c "Add :CFBundleSupportedPlatforms:0 string iPhoneSimulator" $SIMULATOR_DIR/$FILE_NAME/Info.plist
    /usr/libexec/PlistBuddy -c "Delete :CFBundleSupportedPlatforms:1" $SIMULATOR_DIR/$FILE_NAME/Info.plist

    /usr/bin/xcodebuild -create-xcframework \
    -framework $IPHONEOS_DIR/$FILE_NAME \
    -framework $SIMULATOR_DIR/$FILE_NAME \
    -output ./Whiteboard/Vendor/$NAME.xcframework
}

/bin/rm -rf ./Whiteboard/Vendor/AgoraFPA.xcframework
/bin/rm -rf ./Whiteboard/Vendor/AgoraFpaProxyService.xcframework

xcframeworkFrom 'libs/ALL_ARCHITECTURE/AgoraFPA.framework' AgoraFPA
xcframeworkFrom 'libs/ALL_ARCHITECTURE/AgoraFpaProxyService.framework' AgoraFpaProxyService

/bin/rm -rf $IPHONEOS_DIR
/bin/rm -rf $SIMULATOR_DIR
/bin/rm -rf fpa.zip
/bin/rm -rf libs