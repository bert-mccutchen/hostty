# frozen_string_literal: true

require_relative "lib/hostty/version"

Gem::Specification.new do |spec|
  spec.name = "hostty"
  spec.version = Hostty::VERSION
  spec.authors = ["Bert McCutchen"]
  spec.email = ["mail@bertm.dev"]

  spec.summary = "Process manager that gives each process a local domain with NGINX."
  spec.description = "Process manager with a CLI that runs the processes of a project and gives each one an optional local domain with SSL through ruby-nginx."
  spec.homepage = "https://github.com/bert-mccutchen/hostty"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/releases"
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .gitmodules test/ vendor/ .github/ .standard.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ffi", "~> 1.17"
  spec.add_dependency "ruby-nginx", "~> 1.0"
end
