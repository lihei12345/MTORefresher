Pod::Spec.new do |s|
  s.name		        = "MTORefresher"
  s.version          	= "0.1.0"
  s.summary          	= "MTORefresher is a Swift implementation of pull-to-refresh"
  s.description      	= "Easy + Flexible"
  s.homepage         	= "https://github.com/lihei12345/MTORefresher"
  s.license             = 'MIT'
  s.author           	= { "lifuqiang" => "195135955@qq.com" }
  s.source	      	    = { :git => "git@github.com:lihei12345/MTORefresher.git", :tag => s.version.to_s }
  s.platform		    = :ios, '8.0'
  s.requires_arc    	= true
  s.source_files        = 'Source/*.Swift'
end