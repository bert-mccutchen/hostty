# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"
require "rubygems/package"

Minitest::TestTask.create

require "standard/rake"

task default: %i[test standard]

ZIG_TARGETS = {
  "arm64-darwin" => "aarch64-macos",
  "x86_64-darwin" => "x86_64-macos",
  "x86_64-linux-gnu" => "x86_64-linux-gnu",
  "aarch64-linux-gnu" => "aarch64-linux-gnu"
}.freeze

def ghostty_revision
  @ghostty_revision ||= `git rev-parse HEAD:vendor/ghostty`.strip
end

def build_libghostty(prefix:, target: nil)
  stamp = File.join(prefix, "ghostty-revision")
  return if File.exist?(stamp) && File.read(stamp) == ghostty_revision

  cross = target ? ["-Dtarget=#{target}"] : []
  sh "zig", "build", "--build-file", "vendor/ghostty/build.zig",
    "-Demit-lib-vt", "-Doptimize=ReleaseFast", "-Dcpu=baseline", *cross, "--prefix", prefix
  File.write(stamp, ghostty_revision)
end

desc "Build libghostty-vt for this machine into vendor/libghostty"
task :libghostty do
  build_libghostty(prefix: File.expand_path("vendor/libghostty", __dir__))
end

namespace :native do
  ZIG_TARGETS.each do |platform, target|
    desc "Build the #{platform} gem with libghostty-vt inside"
    task platform do
      file_name = platform.include?("darwin") ? "libghostty-vt.dylib" : "libghostty-vt.so"
      packaged = "lib/hostty/ghostty/#{file_name}"
      prefix = File.expand_path("tmp/native/#{platform}", __dir__)

      begin
        build_libghostty(target:, prefix:)
        cp File.realpath(File.join(prefix, "lib", file_name)), packaged

        spec = Bundler.load_gemspec("hostty.gemspec").dup
        spec.platform = Gem::Platform.new(platform)
        spec.files += [packaged]
        mkdir_p "pkg"
        mv Gem::Package.build(spec), "pkg/"
      ensure
        rm_f packaged
      end
    end
  end

  desc "Build the gem for every platform"
  task all: ZIG_TARGETS.keys

  desc "Build the gems for every macOS platform"
  task darwin: ZIG_TARGETS.keys.grep(/darwin/)

  desc "Build the gems for every Linux platform"
  task linux: ZIG_TARGETS.keys.grep(/linux/)
end
