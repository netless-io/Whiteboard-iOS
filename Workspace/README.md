# Workspace

本workspace包含3个target 
Whiteboard - 对应原example
WhiteboardSDK包含WhiteboardSDK的源码 对应Framework开发  打包后的framework命名是：WhiteboardSDK
请cd至workspace运行pod install

WhiteboardSDK源码改动之后，运行 clean 然后直接编译运行即可直接在Whiteboard-Example app内应用

所做工作：
1.Whiteboard-Example引用 WhiteboardSDK 名改为 import <WhiteboardSDK/WhiteSDK.h>
2.Whiteboard内资源文件封装位resource.bundle 对应whiteSDKBundle调用方式修改
3.Whiteboard public&private 头文件设置
4.工程内有配置WhiteSDKToken 和 WhiteAppIdentifier



未做工作：
1.Framework使用文档
2.framework的2个架构兼容
