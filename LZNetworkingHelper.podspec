
Pod::Spec.new do |s|
	s.name             = 'LZNetworkingHelper'
	s.version          = '2.1.0'
	s.summary          = 'LZNetworkingHelper.'
	s.description      = <<-DESC
	网络请求：
    1.HTTP Request
    2.Network Status
	DESC
	
	s.homepage         = 'https://github.com/liLeiBest'
	s.license          = { :type => 'MIT', :file => 'LICENSE' }
	s.author           = { 'lilei' => 'lilei0502@139.com' }
	s.source           = { :git => 'https://github.com/liLeiBest/LZNetworkingHelper.git', :tag => s.version.to_s }
	
	s.frameworks            = 'Foundation', 'UIKit'
	s.ios.deployment_target = '9.0'
	
	s.source_files			= 'LZNetworkingHelper/Classes/*.{h,m}'
	s.public_header_files	= 'LZNetworkingHelper/Classes/*.h'
	s.dependency 'AFNetworking'
	
	pch_AF = <<-EOS
	#if DEBUG
	#define LZNetworkingLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
	#else
	#define LZNetworkingLog(fmt, ...)
	#endif
	EOS
	s.prefix_header_contents = pch_AF
	
end
