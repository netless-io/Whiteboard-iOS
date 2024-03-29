Pod::Spec.new do |s|
  s.name             = 'Whiteboard'
  s.version          = '2.16.91'
  s.summary          = 'netless.io Whiteboard API on iOS'

  s.description      = <<-DESC
  White-SDK-iOS 的开源版本实现，基于 White-SDK-iOS 2.4.18 继续开发
                       DESC

  s.homepage         = 'https://github.com/netless-io/whiteboard-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'leavesster' => 'yleaf@herewhite.com' }
  s.source           = { :git => 'https://github.com/netless-io/Whiteboard-iOS.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.swift_versions = '5.0'

  # Resource whiteboard-bridge打包
  s.subspec 'Resource' do |src|
      src.resource_bundles = {
        'Whiteboard' => ['Whiteboard/Resource/*']
      }
  end
  
  s.subspec 'Whiteboard-Basic' do |spec|
      spec.source_files = 'Whiteboard/Classes/Model/**', 'Whiteboard/Classes/Object/**', 'Whiteboard/Classes/Converter/**/*', 'Whiteboard/Classes/SDK/**', 'Whiteboard/Classes/Displayer/**', 'Whiteboard/Classes/Whiteboard.h', 'Whiteboard/Classes/Room/**', 'Whiteboard/Classes/Replayer/**', 'Whiteboard/Classes/NativeReplayer/**'
      spec.public_header_files = 'Whiteboard/Classes/Model/**.h', 'Whiteboard/Classes/Object/**.h', 'Whiteboard/Classes/Converter/**/*.h', 'Whiteboard/Classes/Displayer/**.h', 'Whiteboard/Classes/SDK/**.h', 'Whiteboard/Classes/Whiteboard.h', 'Whiteboard/Classes/Room/**.h', 'Whiteboard/Classes/Replayer/**.h', 'Whiteboard/Classes/NativeReplayer/**.h'
      spec.private_header_files = 'Whiteboard/Classes/Object/*+Private.h', 'Whiteboard/Classes/Displayer/*+Private.h', 'Whiteboard/Classes/SDK/*+Private.h', 'Whiteboard/Classes/Room/*+Private.h', 'Whiteboard/Classes/Room/Private/**.h', 'Whiteboard/Classes/Replayer/*+Private.h', 'Whiteboard/Classes/NativeReplayer/*+Private.h'
      spec.frameworks = 'UIKit', 'WebKit', 'AVFoundation'
      spec.dependency 'NTLBridge', '~> 3.1.4'
      spec.dependency 'White_YYModel'
      spec.dependency 'Whiteboard/Resource'
  end
  
  # 对SyncPlayer的支持
  s.subspec 'SyncPlayer' do |sync|
    sync.public_header_files = 'Whiteboard/Classes/SyncPlayer/**.h'
    sync.source_files = 'Whiteboard/Classes/SyncPlayer/**'
    sync.dependency 'Whiteboard/Whiteboard-Basic'
    sync.dependency 'SyncPlayer'
  end

  s.default_subspec = 'Whiteboard-Basic'
end
