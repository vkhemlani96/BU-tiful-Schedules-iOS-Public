target ‘BUtiful Schedules’ do
  	source 'https://github.com/CocoaPods/Specs.git'
	platform :ios, ’10.0’
	use_frameworks!

	pod 'Alamofire',
  	:git => 'https://github.com/Alamofire/Alamofire.git',
  	:branch => 'swift3'

	pod 'Kanna',
  	:git => 'https://github.com/tid-kijyun/Kanna.git',
  	:branch => 'swift3.0’
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
  end