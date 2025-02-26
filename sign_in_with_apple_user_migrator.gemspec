Gem::Specification.new do |spec|
  spec.name          = "sign_in_with_apple_user_migrator"
  spec.version       = "1.0.1"
  spec.authors       = ["sakurahigashi2"]
  spec.email         = ["joh.murata@gmail.com"]

  spec.summary       = "Apple Sign In User Migration Tool"
  spec.description   = "Tool for migrating Apple Sign In users between teams"
  spec.homepage      = "https://github.com/sakurahigashi2/sign_in_with_apple_user_migrator"
  spec.license       = "MIT"

  spec.metadata["documentation_uri"] = spec.homepage

  spec.required_ruby_version = ">= 2.5.0"

  spec.add_dependency "thor", "~> 1"
  spec.add_dependency "jwt", "~> 2"

  spec.add_development_dependency "rake", "~> 13"
  spec.add_development_dependency "rspec", "~> 3"
  spec.add_development_dependency "webmock", "~> 3"

  spec.files         = Dir.glob("lib/**/*") + ["bin/sign_in_with_apple_user_migrator"]
  spec.bindir        = "bin"
  spec.executables   = ["sign_in_with_apple_user_migrator"]
  spec.require_paths = ["lib"]
end
