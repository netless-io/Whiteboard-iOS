# 先删除当前所有的头文件
find . -type f -name '*.h' | grep -v Private | xargs -I {} sh -c 'rm {}'
# 再复制新的头文件, 忽略fpa文件夹和ApplePencilDrawHandler
find .. -type f -name '*.h' | grep -v Private | grep fpa -v | grep ApplePencilDrawHandler -v | xargs -I {} sh -c 'ln -s {} $(basename {})'
# 有两个WhiteObject, 删掉自动覆盖的，拿Model目录下的内容
rm WhiteObject.h 
ln -s ../Model/WhiteObject.h WhiteObject.h
