Pod::Spec.new do |s|
  s.name             = 'VideoCache'
  s.version          = '0.2.1'
  s.summary          = 'VideoCache like SDWebImage'

  s.description      = <<-DESC
VideoCache like SDWebImage. Prefetch supported!
                       DESC

  s.homepage         = 'https://github.com/7ulipa/VideoCache'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'DirGoTii' => 'darwin.jxzang@gmail.com' }
  s.source           = { :git => 'https://github.com/7ulipa/VideoCache.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'VideoCache/Classes/**/*'

  s.frameworks = 'Foundation', 'AVFoundation'
  s.dependency 'ReactiveSwift'
  s.dependency 'ReactiveCocoa'
end
