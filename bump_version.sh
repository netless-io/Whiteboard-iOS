set -exo pipefail

len() {
  echo ${#1}
}

NEWVERSION=$1
VERSIONLENGTH=$(len $NEWVERSION)
OLDTAG=$(git describe --tags --abbrev=0)
echo 'input version is' $NEWVERSION
echo 'old Version is' $OLDTAG
if [ '0' = $VERSIONLENGTH ]; then
echo 'empty version, please try again'
exit 0
elif [ $OLDTAG = $NEWVERSION ]; then
echo 'version exist, please try again'
exit 0
else echo 'version enable'
fi

echo 'update local build'
./update_web_resource
echo 'Add resource to git'
git add .
echo 'commit resource'
git commit -m 'Update bridge resource'
echo 'Update spm headers'
cd ./Whiteboard/Classes/include
sh cpScript.sh
echo 'Add new headers to git'
git add .
echo 'commit headers'
git commit -m 'Update spm headers'
cd ....
echo 'star bump version to' $NEWVERSION
sed -i '' 's/'$OLDTAG'/'$NEWVERSION'/g' Whiteboard.podspec
echo 'update version text in podspec'
sed -i '' 's/'$OLDTAG'/'$NEWVERSION'/g' Whiteboard/Classes/SDK/WhiteSDK.m
echo 'update version text in WhiteSDK.m'
git add Whiteboard.podspec
git add Whiteboard/Classes/SDK/WhiteSDK.m
git commit -m 'Bump version to '$NEWVERSION''
echo 'git commit'
#git tag $NEWVERSION
#echo 'add tag to git'
git push origin
echo 'push commit to origin'
#git push origin --tags
#echo 'push tags to origin'
#echo 'begin push to trunk'
#pod trunk push Whiteboard.podspec --allow-warnings
#echo 'successfully'

