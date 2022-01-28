find .. -type f -name '*.h' | grep -v Private | xargs -I {} sh -c 'ln -s {} $(basename {})'
# 有两个WhiteObject, 删掉自动覆盖的，拿Model目录下的内容
rm WhiteObject.h 
ln -s ../Model/WhiteObject.h WhiteObject.h
