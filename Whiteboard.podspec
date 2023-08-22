Pod::Spec.new do |s|
  s.name             = 'Whiteboard'
  s.version          = '2.16.67'
  s.summary          = 'netless.io Whiteboard API on iOS'

  s.description      = <<-DESC
  White-SDK-iOS 的开源版本实现，基于 White-SDK-iOS 2.4.18 继续开发
                       DESC

  s.homepage         = 'https://github.com/netless-io/whiteboard-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'leavesster' => 'yleaf@herewhite.com' }
  s.source           = { :git => 'https://github.com/netless-io/Whiteboard-iOS.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'

  # Resource whiteboard-bridge打包
  s.subspec 'Resource' do |src|
      src.resource_bundles = {
        'Whiteboard' => ['Whiteboard/Resource/*']
      }
  end
  
  # Model-YYModel
  s.subspec 'Model' do |model|
    model.dependency 'YYModel'
    model.source_files = 'Whiteboard/Classes/Model/**'
    model.public_header_files = 'Whiteboard/Classes/Model/**.h'
    model.private_header_files = 'Whiteboard/Classes/Object/*+Private.h'
    model.frameworks = 'UIKit'
  end
  
  # Model-YYKit
  s.subspec 'Model-YYKit' do |model|
    model.dependency 'YYKit'
    model.source_files = 'Whiteboard/Classes/Model/**'
    model.public_header_files = 'Whiteboard/Classes/Model/**.h'
    model.private_header_files = 'Whiteboard/Classes/Object/*+Private.h'
    model.frameworks = 'UIKit'
  end

  # JSON对象-YYModel
  s.subspec 'Object' do |object|
    object.source_files = 'Whiteboard/Classes/Object/**'
    object.public_header_files = 'Whiteboard/Classes/Object/**.h'
    object.private_header_files = 'Whiteboard/Classes/Object/*+Private.h'
    object.dependency 'Whiteboard/Model'
    object.frameworks = 'UIKit'
  end
  
  # JSON对象-YYKit
  s.subspec 'Object-YYKit' do |object|
    object.source_files = 'Whiteboard/Classes/Object/**'
    object.public_header_files = 'Whiteboard/Classes/Object/**.h'
    object.private_header_files = 'Whiteboard/Classes/Object/*+Private.h'
    object.dependency 'Whiteboard/Model-YYKit'
    object.frameworks = 'UIKit'
  end

  # PPT转码 http 请求封装 - YYModel
  s.subspec 'Converter' do |converter|
    converter.source_files = 'Whiteboard/Classes/Converter/**/*'
    converter.public_header_files = 'Whiteboard/Classes/Converter/**/*.h'
    converter.dependency 'Whiteboard/Object'
  end
  
  # PPT转码 http 请求封装 - YYKit
  s.subspec 'Converter-YYKit' do |converter|
    converter.source_files = 'Whiteboard/Classes/Converter/**/*'
    converter.public_header_files = 'Whiteboard/Classes/Converter/**/*.h'
    converter.dependency 'Whiteboard/Object-YYKit'
  end

  # 基础类，包括sdk，Displayer（Room与Player父类）- YYModel
  s.subspec 'Base' do |base|
    base.source_files = 'Whiteboard/Classes/SDK/**', 'Whiteboard/Classes/Displayer/**', 'Whiteboard/Classes/Whiteboard.h'
    base.public_header_files = 'Whiteboard/Classes/Displayer/**.h', 'Whiteboard/Classes/SDK/**.h', 'Whiteboard/Classes/Whiteboard.h'
    base.private_header_files = 'Whiteboard/Classes/Displayer/*+Private.h', 'Whiteboard/Classes/SDK/*+Private.h'
    base.frameworks = 'WebKit'
    base.dependency 'NTLBridge', '~> 3.1.4'
    base.dependency 'Whiteboard/Object'
  end
  
  # 基础类，包括sdk，Displayer（Room与Player父类）- YYKit
  s.subspec 'Base-YYKit' do |base|
    base.source_files = 'Whiteboard/Classes/SDK/**', 'Whiteboard/Classes/Displayer/**', 'Whiteboard/Classes/Whiteboard.h'
    base.public_header_files = 'Whiteboard/Classes/Displayer/**.h', 'Whiteboard/Classes/SDK/**.h', 'Whiteboard/Classes/Whiteboard.h'
    base.private_header_files = 'Whiteboard/Classes/Displayer/*+Private.h', 'Whiteboard/Classes/SDK/*+Private.h'
    base.frameworks = 'WebKit'
    base.dependency 'NTLBridge', '~> 3.1.4'
    base.dependency 'Whiteboard/Object-YYKit'
  end

  # 实时房间 - YYModel
  s.subspec 'Room' do |room|
    room.source_files = 'Whiteboard/Classes/Room/**'
    room.public_header_files = 'Whiteboard/Classes/Room/**.h'
    room.private_header_files = 'Whiteboard/Classes/Room/*+Private.h', 'Whiteboard/Classes/Room/Private/**.h'
    room.dependency 'Whiteboard/Base'
  end
  
  # 实时房间 - YYKit
  s.subspec 'Room-YYKit' do |room|
    room.source_files = 'Whiteboard/Classes/Room/**'
    room.public_header_files = 'Whiteboard/Classes/Room/**.h'
    room.private_header_files = 'Whiteboard/Classes/Room/*+Private.h', 'Whiteboard/Classes/Room/Private/**.h'
    room.dependency 'Whiteboard/Base-YYKit'
  end
  
  # 回放房间 - YYModel
  s.subspec 'Replayer' do |replayer|
    replayer.source_files = 'Whiteboard/Classes/Replayer/**'
    replayer.public_header_files = 'Whiteboard/Classes/Replayer/**.h'
    replayer.private_header_files = 'Whiteboard/Classes/Replayer/*+Private.h'
    replayer.dependency 'Whiteboard/Base'
  end
  
  # 回放房间 - YYKit
  s.subspec 'Replayer-YYKit' do |replayer|
    replayer.source_files = 'Whiteboard/Classes/Replayer/**'
    replayer.public_header_files = 'Whiteboard/Classes/Replayer/**.h'
    replayer.private_header_files = 'Whiteboard/Classes/Replayer/*+Private.h'
    replayer.dependency 'Whiteboard/Base-YYKit'
  end

  # 音视频 native 与回放房间结合 - YYModel
  s.subspec 'NativeReplayer' do |naitve|
    naitve.source_files = 'Whiteboard/Classes/NativeReplayer/**'
    naitve.public_header_files = 'Whiteboard/Classes/NativeReplayer/**.h'
    naitve.private_header_files = 'Whiteboard/Classes/NativeReplayer/*+Private.h'
    naitve.dependency 'Whiteboard/Replayer'
    naitve.frameworks = 'AVFoundation'
  end
  
  # 对SyncPlayer的支持
  s.subspec 'SyncPlayer' do |sync|
    sync.public_header_files = 'Whiteboard/Classes/SyncPlayer/**.h'
    sync.private_header_files = 'Whiteboard/Classes/SyncPlayer/*+Private.h'
    sync.source_files = 'Whiteboard/Classes/SyncPlayer/**'
    sync.dependency 'Whiteboard/Replayer'
    sync.dependency 'SyncPlayer'
  end
  
  # 对SyncPlayer的支持 - YYKit
  s.subspec 'SyncPlayer-YYKit' do |sync|
    sync.public_header_files = 'Whiteboard/Classes/SyncPlayer/**.h'
    sync.private_header_files = 'Whiteboard/Classes/SyncPlayer/*+Private.h'
    sync.source_files = 'Whiteboard/Classes/SyncPlayer/**'
    sync.dependency 'Whiteboard/Replayer-YYKit'
    sync.dependency 'SyncPlayer'
  end
  
  # 音视频 native 与回放房间结合 - YYKit
  s.subspec 'NativeReplayer-YYKit' do |naitve|
    naitve.source_files = 'Whiteboard/Classes/NativeReplayer/**'
    naitve.public_header_files = 'Whiteboard/Classes/NativeReplayer/**.h'
    naitve.private_header_files = 'Whiteboard/Classes/NativeReplayer/*+Private.h'
    naitve.dependency 'Whiteboard/Replayer-YYKit'
    naitve.frameworks = 'AVFoundation'
  end
  
  s.subspec 'Whiteboard-YYModel' do |sp|
      sp.public_header_files = 'Whiteboard/Classes/Whiteboard.h'
      sp.source_files = 'Whiteboard/Classes/Whiteboard.h'
      sp.dependency 'Whiteboard/Resource'
      sp.dependency 'Whiteboard/Converter'
      sp.dependency 'Whiteboard/Room'
      sp.dependency 'Whiteboard/NativeReplayer'
  end
  
  s.subspec 'Whiteboard-YYKit' do |sp|
      sp.public_header_files = 'Whiteboard/Classes/Whiteboard.h'
      sp.source_files = 'Whiteboard/Classes/Whiteboard.h'
      sp.dependency 'Whiteboard/Resource'
      sp.dependency 'Whiteboard/Converter-YYKit'
      sp.dependency 'Whiteboard/Room-YYKit'
      sp.dependency 'Whiteboard/NativeReplayer-YYKit'
  end

  s.default_subspec = 'Whiteboard-YYModel'
end
