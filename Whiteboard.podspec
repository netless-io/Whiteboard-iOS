Pod::Spec.new do |s|
  s.name             = 'Whiteboard'
  s.version          = '2.16.0'
  s.summary          = 'netless.io Whiteboard API on iOS'

  s.description      = <<-DESC
  White-SDK-iOS 的开源版本实现，基于 White-SDK-iOS 2.4.18 继续开发
                       DESC

  s.homepage         = 'https://github.com/netless-io/whiteboard-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'leavesster' => 'yleaf@herewhite.com' }
  s.source           = { :git => 'https://github.com/netless-io/Whiteboard-iOS.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  
  s.resource_bundles = {
    'Whiteboard' => ['Whiteboard/Resource/*']
  }

  s.source_files = 'Whiteboard/Classes/Whiteboard.h'
  
  # YYModel 隔离类
  s.subspec 'Model' do |model|
    model.source_files = 'Whiteboard/Classes/Model/**'
    model.public_header_files = 'Whiteboard/Classes/Model/**.h'
    model.private_header_files = 'Whiteboard/Classes/Object/*+Private.h'
    model.dependency 'YYModel', '~> 1.0.4'
    model.frameworks = 'UIKit'
  end

  # 配置类
  s.subspec 'Object' do |object|
    object.source_files = 'Whiteboard/Classes/Object/**'
    object.public_header_files = 'Whiteboard/Classes/Object/**.h'
    object.private_header_files = 'Whiteboard/Classes/Object/*+Private.h'
    object.dependency 'Whiteboard/Model'
    object.frameworks = 'UIKit'
  end

  # 动静态转换 http 请求封装
  s.subspec 'Converter' do |converter|
    converter.source_files = 'Whiteboard/Classes/Converter/**'
    converter.public_header_files = 'Whiteboard/Classes/Converter/**.h'
    converter.dependency 'Whiteboard/Object'
  end

  # 基础类，包括sdk，Displayer（Room与Player父类）
  s.subspec 'Base' do |base|
    base.source_files = 'Whiteboard/Classes/SDK/**', 'Whiteboard/Classes/Displayer/**'
    base.public_header_files = 'Whiteboard/Classes/Displayer/**.h', 'Whiteboard/Classes/SDK/**.h'
    base.private_header_files = 'Whiteboard/Classes/Displayer/*+Private.h', 'Whiteboard/Classes/SDK/*+Private.h'
    base.frameworks = 'WebKit'
    base.dependency 'dsBridge', '~> 3.0.2'
    base.dependency 'Whiteboard/Object'
  end

  # 实时房间
  s.subspec 'Room' do |room|
    room.source_files = 'Whiteboard/Classes/Room/**'
    room.public_header_files = 'Whiteboard/Classes/Room/**.h'
    room.private_header_files = 'Whiteboard/Classes/Room/*+Private.h'
    room.dependency 'Whiteboard/Base'
  end

  # 回放房间
  s.subspec 'Replayer' do |replayer|
    replayer.source_files = 'Whiteboard/Classes/Replayer/**'
    replayer.public_header_files = 'Whiteboard/Classes/Replayer/**.h'
    replayer.private_header_files = 'Whiteboard/Classes/Replayer/*+Private.h'
    replayer.dependency 'Whiteboard/Base'
  end

  # 音视频 native 与回放房间结合
  s.subspec 'NativeReplayer' do |naitve|
    naitve.source_files = 'Whiteboard/Classes/NativeReplayer/**'
    naitve.public_header_files = 'Whiteboard/Classes/NativeReplayer/**.h'
    naitve.private_header_files = 'Whiteboard/Classes/NativeReplayer/*+Private.h'
    naitve.dependency 'Whiteboard/Replayer'
    naitve.frameworks = 'AVFoundation'
  end
  
  # ---------
  # -YYModel-
  # ---------
#  s.default_subspec = 'Converter', 'Room', 'Replayer', 'NativeReplayer'
  
  # ---------
  # --YYKit--
  # ---------
  
  # YYModel 隔离类
#  s.subspec 'Model-YYKit' do |model|
#    model.source_files = 'Whiteboard/Classes/Model-YYKit/**'
#    model.public_header_files = 'Whiteboard/Classes/Model-YYKit/**.h'
#    model.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'USE_YYKit=1'}
#    model.dependency 'YYKit'
#    model.frameworks = 'UIKit'
#  end
#
#  # 配置类
#  s.subspec 'Object-YYKit' do |object|
#    object.source_files = 'Whiteboard/Classes/Object/**'
#    object.public_header_files = 'Whiteboard/Classes/Object/**.h'
#    object.private_header_files = 'Whiteboard/Classes/Object/*+Private.h'
#    object.dependency 'Whiteboard/Model-YYKit'
#    object.frameworks = 'UIKit'
#  end
#
#  # 动静态转换 http 请求封装
#  s.subspec 'Converter-YYKit' do |converter|
#    converter.source_files = 'Whiteboard/Classes/Converter/**'
#    converter.public_header_files = 'Whiteboard/Classes/Converter/**.h'
#    converter.dependency 'Whiteboard/Object-YYKit'
#  end
#
#  # 基础类，包括sdk，Displayer（Room与Player父类）
#  s.subspec 'Base-YYKit' do |base|
#    base.source_files = 'Whiteboard/Classes/SDK/**', 'Whiteboard/Classes/Displayer/**'
#    base.public_header_files = 'Whiteboard/Classes/Displayer/**.h', 'Whiteboard/Classes/SDK/**.h'
#    base.private_header_files = 'Whiteboard/Classes/Displayer/*+Private.h', 'Whiteboard/Classes/SDK/*+Private.h'
#    base.frameworks = 'WebKit'
#    base.dependency 'dsBridge', '~> 3.0.2'
#    base.dependency 'Whiteboard/Object-YYKit'
#  end
#
#  # 实时房间
#  s.subspec 'Room-YYKit' do |room|
#    room.source_files = 'Whiteboard/Classes/Room/**'
#    room.public_header_files = 'Whiteboard/Classes/Room/**.h'
#    room.private_header_files = 'Whiteboard/Classes/Room/*+Private.h'
#    room.dependency 'Whiteboard/Base-YYKit'
#  end
#
#  # 回放房间
#  s.subspec 'Replayer-YYKit' do |replayer|
#    replayer.source_files = 'Whiteboard/Classes/Replayer/**'
#    replayer.public_header_files = 'Whiteboard/Classes/Replayer/**.h'
#    replayer.private_header_files = 'Whiteboard/Classes/Replayer/*+Private.h'
#    replayer.dependency 'Whiteboard/Base-YYKit'
#  end
#
#  # 音视频 native 与回放房间结合
#  s.subspec 'NativeReplayer-YYKit' do |naitve|
#    naitve.source_files = 'Whiteboard/Classes/NativeReplayer/**'
#    naitve.public_header_files = 'Whiteboard/Classes/NativeReplayer/**.h'
#    naitve.private_header_files = 'Whiteboard/Classes/NativeReplayer/*+Private.h'
#    naitve.dependency 'Whiteboard/Replayer-YYKit'
#    naitve.frameworks = 'AVFoundation'
#  end
#
#  s.subspec 'Whiteboard-YYKit' do |sp|
#    sp.source_files = 'Whiteboard/Classes/Whiteboard.h'
#    sp.dependency 'Whiteboard/Converter-YYKit'
#    sp.dependency 'Whiteboard/Room-YYKit'
#    sp.dependency 'Whiteboard/Replayer-YYKit'
#    sp.dependency 'Whiteboard/NativeReplayer-YYKit'
#    sp.frameworks = 'UIKit'
#  end

end
