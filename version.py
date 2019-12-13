import re, sys, fileinput

version = "{{version}}"
def readPodVersion(path):
    try:
        with open (path, "r", encoding="utf-8") as podspec:
            for row in podspec:
                if row.strip(" ").startswith("s.version"):
                    global version
                    version = row.replace(" ","")
                    version = re.findall(r'\'([\S\s]+)\'', version)[0]
            if version == '':
                print("复制失败")
                sys.exit(-1)
            else:
                print('新 version:{}'.format(version))
    except Exception as exception:
        print(exception)
        sys.exit(-1)

def syncReleasPod(replacePath):
    try:
        for line in fileinput.input(replacePath, backup='', inplace=True):
            if line.strip(" ").startswith("s.version"):
                old = line.replace(" ", "")
                old = re.findall(r'\'([\S\s]+)\'', old)[0]
                line = line.replace(old, version)
                sys.stderr.write("旧版本:{} 新版本:{}".format(old, version))
                print(line.rstrip())
            else:
                print(line.rstrip())
    except Exception as e:
        sys.stderr.write(e)
        sys.exit(-1)

def syncSDKVersion(replacePath, check=True):
    try:
        i = 1
        versionNum = 0
        same = False
        for line in fileinput.input(replacePath, backup='', inplace=True):
            if line.strip().endswith("version"):
                print(line.rstrip())
                versionNum = i
            elif versionNum != 0 and i == versionNum + 2:
                old = line.rstrip().replace(" ", "")
                matches = re.findall(r"\@\"([^\"]+)", old)
                if len(matches) == 0:
                    sys.stderr.write("正则提取失败")
                else:
                    old = matches[0]

                if check:
                    same = old == version
                else:
                    line = line.replace(old, version)

                sys.stderr.write("旧版本:{} 新版本:{}\n".format(old, version))
                print(line.rstrip())
            else:
                print(line.rstrip())
            i += 1
        if check and not same:
            sys.stderr.write("版本校验失败")
            sys.exit(-1)
    except Exception as e:
        sys.stderr.write(e)
        sys.exit(-1)

def main(argv):
    print(argv)
    print(version)
    # 默认同步
    if len(argv) == 1:
        syncSDKVersion("./WhiteSDK/Classes/WhiteSDK.m", False)
    elif argv[1] == 'check':
        syncSDKVersion("./WhiteSDK/Classes/WhiteSDK.m", True)

if __name__ == "__main__":
    readPodVersion("./WhiteSDK.podspec")
    main(sys.argv)
