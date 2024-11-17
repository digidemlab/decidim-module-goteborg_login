# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "decidim/goteborg_login/version"

Gem::Specification.new do |s|
  s.version = Decidim::GoteborgLogin.version
  s.authors = ["Nicklas Bystedt"]
  s.email = ["ybin64@gmail.com"]
  s.license = "AGPL-3.0"
  s.homepage = "https://decidim.org"
  s.metadata = {
    "bug_tracker_uri" => "https://github.com/decidim/decidim/issues",
    "documentation_uri" => "https://docs.decidim.org/",
    "funding_uri" => "https://opencollective.com/decidim",
    "homepage_uri" => "https://decidim.org",
    "source_code_uri" => "https://github.com/decidim/decidim"
  }
  s.required_ruby_version = ">= 3.1"

  s.name = "decidim-goteborg_login"
  s.summary = "A decidim goteborg_login module"
  s.description = "Foo."

  s.files = Dir["{app,config,lib}/**/*", "LICENSE-AGPLv3.txt", "Rakefile", "README.md"]

  s.add_dependency "decidim-core", Decidim::GoteborgLogin.version

  s.require_paths = ['lib']

  s.add_dependency 'omniauth-saml', '~> 2.1'
  s.add_dependency 'ruby-saml', '~> 1.17'

  # Basic development dependencies
  s.add_development_dependency 'rake', '~> 13.1'
  s.add_development_dependency 'rspec', '~> 3.13'

  # Testing the requests
  s.add_development_dependency 'rack-test', '~> 2.1.0'
  s.add_development_dependency 'webmock', '~> 3.20'
  s.add_development_dependency 'xmlenc', '~> 0.8.0'

  # Code coverage
  s.add_development_dependency 'simplecov', '~> 0.22.0'
end
