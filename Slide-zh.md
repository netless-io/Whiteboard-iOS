## Slide 部分功能指引

### WhiteSlideDelegate

Slide 有部分回调功能在 `WhiteSlideDelegate` 中，如果需要使用的话，需要首先通过 `WhiteSDK.setSlideDelegate` 来设置对应的回调处理对象。

### Customlink

该功能支持在点击 ppt 链接的时候，由外部控制跳转。

使用该功能首先要设置 `WhiteSlideDelegate`

其次在创建 slide 的时候，填入 customlinks。对应的方法如下：

```
@interface WhiteAppParam : WhiteObject

+ (instancetype)createSlideApp:(NSString *)dir taskId:(NSString *)taskId url:(NSString *)url title:(NSString *)title previewlist:(NSArray <NSString *>*)previewList resourceList: (NSArray <NSString *>*)resourceList customLinks:(NSArray <WhiteSlideCustomLink *>*)customLinks;
```

最后你会在 `WhiteSlideDelegate.slideOpenUrl` 里收到对应的点击事件，完成你自己的业务逻辑。
