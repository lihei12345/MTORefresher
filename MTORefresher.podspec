Pod::Spec.new do |s|
  s.name		          = "MTORefresher"
  s.version          	= "1.0.1"
  s.summary          	= "MTORefresher is a Swift implementation of pull-to-refresh"
  s.description      	= "MTORefresher is a Swift implementation of pull-to-refresh, include pull-down and pull-up. Use 1 line of code can make this. Also you can use Component protocol to custom your own pull-to-refresh Component."
  s.homepage         	= "https://github.com/lihei12345/MTORefresher"
  s.license           = 'MIT'
  s.author           	= { "lifuqiang" => "195135955@qq.com" }
  s.source	      	  = { :git => "https://github.com/lihei12345/MTORefresher.git", :tag => s.version.to_s }
  s.platform		      = :ios, '8.0'
  s.requires_arc    	= true
  s.default_subspec   = "Core" 

  s.subspec "Core" do |ss|
    ss.source_files   = "Source/*.swift"
    ss.framework      = "UIKit"
  end

  s.subspec "BasicComponent" do |ss|
    ss.source_files   = "BasicComponent/*.swift"
    ss.dependency "MTORefresher/Core"
    ss.resources = "BasicComponent/*.{png,jpg}" 
  end
end
