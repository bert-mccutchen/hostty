<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="../assets/hostty-dark.svg">
    <img src="../assets/hostty-light.svg" alt="Hostty" width="300">
  </picture>
</p>

# Development

### Contents

- [Setup](#setup)
- [Platform Gems](#platform-gems)
- [Releasing](#releasing)
- [Running Hostty](#running-hostty)
- [Tests](#tests)
- [Linting](#linting)
- [Benchmark](#benchmark)
- [Pages](#pages)

## Setup

1. Install Zig 0.17. On macOS, run `brew install zig`.
2. Run the setup script:

   ```shell
   bin/setup
   ```

The setup script checks out libghostty-vt into `vendor/ghostty`, installs the gems, and builds the library into `vendor/libghostty`. Hostty loads the library from there when you run it from the repository.

Hostty needs Ruby 3.2 or later. Its runtime dependencies are ruby-nginx and ffi.

- After you change the libghostty-vt version in `vendor/ghostty`, run `bundle exec rake libghostty` to build it again.
- libghostty-vt 1.0 needs Zig 0.17. The build stops with an error on any other minor version.

## Platform Gems

`bundle exec rake native:all` builds a gem with libghostty-vt inside for each platform: `arm64-darwin`, `x86_64-darwin`, `x86_64-linux-gnu`, and `aarch64-linux-gnu`. Zig builds the library for every platform from one machine. Use `native:<platform>` to build one, such as `bundle exec rake native:x86_64-linux-gnu`. The gems go into `pkg/`.

`bundle exec rake build` builds the gem without the library. That gem uses a libghostty-vt from the package manager of the system.

CI builds every platform gem on each push and keeps them as build artifacts, so a broken build shows before a release.

## Releasing

1. Change `Hostty::VERSION` in `lib/hostty/version.rb`.
2. Merge the change into `main`.
3. Publish a GitHub release from `main`, with a tag for the version.

The release starts the "Ruby Gem" workflow. It builds the four platform gems and the gem without the library, then pushes all of them to RubyGems and to GitHub Packages.

## Running Hostty

Run hostty from the repository with your own config file:

```shell
bundle exec exe/hostty --file path/to/.hostty.yml
```

A config file of shell loops makes a quick sample, because it needs no server:

```yaml
processes:
  web: "i=0; while true; do i=$((i+1)); echo \"port $PORT, line $i\"; sleep 1; done"
  jobs: "i=0; while true; do i=$((i+1)); echo \"port $PORT, line $i\"; sleep 3; done"
  irb: "irb"
```

## Tests

```shell
bundle exec rake test
```

The tests use Minitest and run hostty through `Hostty::CLI`, the same entry point as `exe/hostty`:

| Directory | What it tests |
| --- | --- |
| `test/cli/` | Hostty end to end: the config, the domains, plain output, the tabs, and stopping. |
| `test/ghostty/` | The screen of each tab, which Hostty reads from libghostty-vt. |
| `test/support/` | Helpers for the tests above. |

- A fake stands in for ruby-nginx, so the tests never touch NGINX or `/etc/hosts`.
- The tab tests open a real pseudo-terminal and pass it to hostty as stdin and stdout. The test reads the output of hostty into libghostty-vt, the same library that hostty uses, so it checks the screen a user would see. It sends clicks and keys through the same pseudo-terminal.
- The tab tests wait for text on the screen, with a 5-second limit, instead of sleeping.

## Linting

```shell
bundle exec rake standard
```

`bundle exec rake` runs the tests and Standard together.

## Benchmark

```shell
bin/bench 20
```

The benchmark feeds 20 MB of each kind of generated log output through the screen of a tab, and prints the MB and lines read per second of CPU time. It then times one frame read at 80 by 24 and at 200 by 50. Run it before and after a change to `lib/hostty/ghostty/` to compare.

| Measure | Result |
| --- | --- |
| Plain log lines | About 1,900 MB/s, or 28.7 million lines a second |
| Colored Rails log lines | About 520 MB/s, or 6.2 million lines a second |
| Progress bar with carriage returns | About 920 MB/s, or 15 million lines a second |
| Frame read at 80 by 24 | 1.2 ms |
| Frame read at 200 by 50 | 7.4 ms |

The frame reads add a new line before each read, so every row of the screen changes. That is the slowest case for a frame read.

## Pages

- [Architecture](./architecture.md): how hostty works inside.

---

[← Return to Hostty](../../README.md)
