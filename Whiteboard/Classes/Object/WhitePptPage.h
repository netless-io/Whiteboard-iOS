//
//  WhitePptPage.h
//  WhiteSDK
//
//  Created by leavesster on 2018/8/15.
//

#import <UIKit/UIkit.h>
#import "WhiteObject.h"

NS_ASSUME_NONNULL_BEGIN

/** 用于配置待插入场景的图片或动态 PPT 页的参数。场景中可插入的图片或动态 PPT 包括：
  
  - PNG、JPG/JPEG、WEBP 格式的图片，或由 PPT、PPTX、DOC、DOCX、PDF 格式的文件转换成 PNG、JPG/JPEG、WEBP 格式的图片。
  - 使用 [Agora 互动文档转换功能](https://docs.agora.io/cn/whiteboard/file_conversion_overview?platform=RESTful)转换过的 PPTX 文件。 
 */
@interface WhitePptPage : WhiteObject

/** 创建待插入场景的图片或动态 PPT 并初始化一个 `WhitePptPage` 对象。

 **Note：**

 - 每个场景中只能插入一张图片和一页动态 PPT。
 - 场景中展示的图片或动态 PPT 中心点默认为白板内部坐标系得原点且无法移动，即无法改变图片或动态 PPT 在白板内部的位置。

 @param src src 图片或动态 PPT 页的地址，支持的格式如下：

 - 图片：URL 地址，可以是你自己生成的 URL 地址，也可以是通过文档转换功能生成的 URL 地址，例如，`"https://docs-test-xxx.oss-cn-hangzhou.aliyuncs.com/staticConvert/2fdxxxxx67e/1.jpeg"`。
 - 动态 PPT 页：通过文档转换功能生成的 URI 地址，例如，`"pptx://cover.herewhite.com/dynamicConvert/6a212c90fa5311ea8b9c074232aaccd4/1.slide"`，即[动态文档转换任务的查询结果](https://docs.agora.io/cn/whiteboard/whiteboard_file_conversion?platform=RESTful#查询转换任务的进度（get）)中 `conversionFileUrl` 字段的值。
 @param size 图片或动态 PPT 在白板中的尺寸，单位为像素。

 @return 初始化的 `WhitePptPage` 对象。
 */
- (instancetype)initWithSrc:(NSString *)src size:(CGSize)size;

/** 创建待插入场景的图片或动态 PPT 并初始化一个 `WhitePptPage` 对象。

 **Note：**

 - 每个场景中只能插入一张图片和一页动态 PPT。
 - 场景中展示的图片或动态 PPT 中心点默认为白板内部坐标系得原点且无法移动，即无法改变图片或动态 PPT 在白板内部的位置。

 @param src src 图片或动态 PPT 页的地址，支持的格式如下：

 - 图片：URL 地址，可以是你自己生成的 URL 地址，也可以是通过文档转换功能生成的 URL 地址，例如，`"https://docs-test-xxx.oss-cn-hangzhou.aliyuncs.com/staticConvert/2fdxxxxx67e/1.jpeg"`。
 - 动态 PPT 页：通过文档转换功能生成的 URI 地址，例如，`"pptx://cover.herewhite.com/dynamicConvert/6a212c90fa5311ea8b9c074232aaccd4/1.slide"`，即[动态文档转换任务的查询结果](https://docs.agora.io/cn/whiteboard/whiteboard_file_conversion?platform=RESTful#查询转换任务的进度（get）)中 `conversionFileUrl` 字段的值。
 @param url 图片或动态 PPT 预览图的 URL 地址。动态 PPT 预览图的 URL 地址可以从[文档转换任务的查询结果](https://docs.agora.io/cn/whiteboard/whiteboard_file_conversion?platform=RESTful#查询转换任务的进度（get）)中的 `preview` 字段获取，例如，"https://docs-test-xxx.oss-cn-hangzhou.aliyuncs.com/dynamicConvert/2fdxxxxx67e/preview/1.png"。
 @param size 图片或动态 PPT 在白板中的尺寸，单位为像素。

 @return 初始化的 `WhitePptPage` 对象。
 */
- (instancetype)initWithSrc:(NSString *)src preview:(NSString *)url size:(CGSize)size;

/**
 场景图片或动态 PPT 的地址。
 */
@property (nonatomic, copy) NSString *src;
/**
 图片或动态 PPT 在白板中的宽度，单位为像素。
 */
@property (nonatomic, assign) CGFloat width;
/**
 图片或动态 PPT 在白板中的高度，单位为像素。
 */
@property (nonatomic, assign) CGFloat height;

/**
 图片的或动态 PPT 预览图的 URL 地址。
 */
@property (nonatomic, copy, readonly) NSString *previewURL;

@end

NS_ASSUME_NONNULL_END
