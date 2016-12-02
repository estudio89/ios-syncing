Pod::Spec.new do |s|
  s.name = 'Syncing'
  s.version = '1.0.2'
  s.source_files = 'Syncing/*.{h,m}'
  s.dependency 'Raven', '~> 1.0.1'
  s.dependency 'RNCryptor', '~> 2.2'
  s.dependency 'ISO8601', '~> 0.3.0'
  s.authors = 'Estúdio 89'
  s.license = 'GPL'
  s.homepage = 'https://github.com/estudio89/ios-syncing'
  s.summary = 'E89 iOS Syncing'
  s.source = { :git => 'https://github.com/estudio89/ios-syncing.git' }
end