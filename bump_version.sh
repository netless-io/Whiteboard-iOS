set -exo pipefail

git_dirty() {
if [[ -n $(git diff --stat) ]]
then
 echo 1
else
 echo 0
fi
}

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

./update_web_resource
if [ $(git_dirty) = '1' ]
then
git add . && git commit -m 'Update bridge resource'
fi

echo 'Update spm headers'
cd ./Whiteboard/Classes/include
sh cpScript.sh
cd ../../..
if [ $(git_dirty) = '1' ]
then
git add . && git commit -m 'Update spm headers'
fi

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

