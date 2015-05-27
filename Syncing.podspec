Pod::Spec.new do |s|
  s.name = 'Syncing'
  s.version = '0.0.0'
  s.source_files = 'Syncing/*.{h,m}'
  s.dependency 'Raven'
  s.dependency 'RNCryptor'
end