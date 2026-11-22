<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="../assets/hostty-dark.svg">
    <img src="../assets/hostty-light.svg" alt="Hostty" width="300">
  </picture>
</p>

# Command Line

### Contents

- [Usage](#usage)
- [Options](#options)
- [Exit Codes](#exit-codes)

## Usage

```shell
hostty [start] [options]
```

`hostty` and `hostty start` do the same thing.

## Options

| Option | What it does |
| --- | --- |
| `-f`, `--file FILE` | Read the processes from `FILE`. Defaults to `.hostty.yml`. |
| `-p`, `--port PORT` | Give the first process `PORT`. Defaults to 5000. See [Ports](./configuration.md#ports). |
| `-t`, `--timeout SECONDS` | Wait `SECONDS` for the processes to stop before hostty kills them. Defaults to 10. See [Stopping](./stopping.md). |
| `--plain` | Print the output of all processes together instead of in tabs. See [Plain Output](./plain-output.md). |
| `-v`, `--version` | Print the version. |
| `-h`, `--help` | Print the options. |

## Exit Codes

| Code | When |
| --- | --- |
| 0 | You quit hostty, or hostty got TERM or HUP. |
| The exit code of the first process that exited | In [plain output](./plain-output.md), a process exited on its own. A process that a signal killed gives 128 plus the signal number, such as 143 for TERM. |
| 1 | The options, the config file, or a domain had an error, or the tabs could not load [libghostty-vt](./terminal-emulator.md#what-it-does). Hostty prints the error. |
| 130 | You pressed Ctrl-C while hostty added the domains. |

---

[← Return to Features](./README.md)
