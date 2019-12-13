Pod::Spec.new do |s|
  s.name             = 'Whiteboard'
  s.version          = '0.0.2'
  s.summary          = 'netless.io Whiteboard API on iOS'

  s.description      = <<-DESC
  White-SDK-iOS 的开源版本实现，基于 White-SDK-iOS 2.4.18 继续开发
                       DESC

  s.homepage         = 'https://github.com/netless-io/whiteboard-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'leavesster' => 'yleaf@herewhite.com' }
  s.source           = { :git => 'https://github.com/netless-io/Whiteboard-iOS.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  
  s.resource_bundles = {
    'Whiteboard' => ['Whiteboard/Resource/*']
  }

  s.source_files = 'Whiteboard/Classes/whiteboard.h'

  # 动静态转换 http 请求封装
  s.subspec 'Converter' do |sp|
    sp.source_files = 'Whiteboard/Classes/Converter/**'
    sp.dependency 'Whiteboard/Object'
  end

  # 实时房间
  s.subspec 'Room' do |sp|
    sp.source_files = 'Whiteboard/Classes/Room/**'
    sp.dependency 'Whiteboard/Base'
  end

  # 回放房间
  s.subspec 'Replayer' do |sp|
    sp.source_files = 'Whiteboard/Classes/Replayer/**'
    sp.dependency 'Whiteboard/Base'
  end

  # 音视频 native 与回放房间结合
  s.subspec 'NativeReplayer' do |sp|
    sp.source_files = 'Whiteboard/Classes/NativeReplayer/**'
    sp.dependency 'Whiteboard/Replayer'
    sp.frameworks = 'AVFoundation'
  end

  # 基础类，包括sdk，Displayer（Room与Player父类）
  s.subspec 'Base' do |sp|
    sp.source_files = 'Whiteboard/Classes/**', 'Whiteboard/Classes/Displayer/**'
    sp.frameworks = 'WebKit'
    sp.dependency 'dsBridge', '~> 3.0.2'
    sp.dependency 'Whiteboard/Object'
  end

  # 配置类
  s.subspec 'Object' do |sp|
    sp.source_files = 'Whiteboard/Classes/Object/**'
    sp.dependency 'YYModel', '~> 1.0.4'
    sp.frameworks = 'UIKit'
  end

end
