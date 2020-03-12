lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rtask/version'

Gem::Specification.new do |spec|
  spec.name          = 'rtask'
  spec.version       = RTask::VERSION
  spec.authors       = ['Canh Nguyen']
  spec.email         = ['canhnguyen@spokeo.com']

  spec.summary       = 'Ruby task based parallel.'
  spec.description   = 'RTask mimicks Task class in .NET to allow writing asynchronous code in ruby easier.'
  spec.homepage      = 'https://github.com/canhspokeo/rtask'
  spec.license       = 'MIT'

  spec.metadata['homepage_uri'] = 'https://github.com/canhspokeo/rtask'
  spec.metadata['source_code_uri'] = 'https://github.com/canhspokeo/rtask'
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = [
    'lib/rtask.rb',
    'lib/rtask/task.rb',
    'lib/rtask/task_helper.rb',
    'lib/rtask/task_scheduler.rb',
    'lib/rtask/task_status.rb',
    'lib/rtask/version.rb'
  ]
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
