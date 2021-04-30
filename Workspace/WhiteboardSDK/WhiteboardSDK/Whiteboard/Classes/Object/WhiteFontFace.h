//
//  WhiteFontFace.h
//  Whiteboard-Whiteboard
//
//  Created by yleaf on 2020/12/1.
//

#import "WhiteObject.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 该类的属性，均会等效转换成 CCS FontFace 中的对应字段，所有字段的值，均需与原始字段一致。
 *
 * @font-face {
 *  font-family: "Times New Roman";
 *  src: url("https://white-pan.oss-cn-shanghai.aliyuncs.com/Pacifico-Regular.ttf");
 *  font-style: italic;
 * }
 */
@interface WhiteFontFace : WhiteObject

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithFontFamily:(NSString *)name src:(NSString *)src;

/**
 * 字体名称，匹配时，需要完全一致
 */
@property (nonatomic, strong) NSString *fontFamily;

/**
 * 对应，CSS FontFace 中 font-style 字段
 * 该值为 italic，bold，或者 normal，默认值为 normal
 */
@property (nonatomic, strong, nullable) NSString *fontStyle;

/**
 * 字重，CSS FontFace 中 font-weight 字段
 * 传入数字即可，普通字重为 400，也是默认字体
 * 粗体在 动态 ppt 会被解析成 500 的字重，style 为 normal 的 css
 */
@property (nonatomic, strong, nullable) NSString *fontWeight;

/**
 * 对应 CSS FontFace 中 src 字段
 * 传入类似 url("https://white-pan.oss-cn-shanghai.aliyuncs.com/Pacifico-Regular.ttf")
 * 也可以根据 CSS FontFace 支持的其他格式进行填写
 */
@property (nonatomic, strong) NSString *src;

/**
 * 对应 CSS FontFace unicode range 字段
 */
@property (nonatomic, strong, nullable) NSString *unicodeRange;

@end

NS_ASSUME_NONNULL_END
