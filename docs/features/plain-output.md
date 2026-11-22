<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="../assets/hostty-dark.svg">
    <img src="../assets/hostty-light.svg" alt="Hostty" width="300">
  </picture>
</p>

# Plain Output

### Contents

- [When Hostty Prints Plain Output](#when-hostty-prints-plain-output)
- [The Output](#the-output)
- [When a Process Exits](#when-a-process-exits)
- [Limits](#limits)

## When Hostty Prints Plain Output

Hostty prints plain output in place of [tabs](./tabs.md) when either is true:

- You pass `--plain`.
- stdin or stdout is not a terminal, such as in CI or in `hostty | tee hostty.log`.

## The Output

Hostty prints every line of every process in one stream, with the time and the process name:

```text
12:00:01 hostty | Adding https://shop.test for web on port 5000.
12:00:02 web     | => Booting Puma
12:00:02 docs    | Server address: http://127.0.0.1:5100/
12:00:03 jobs    | SolidQueue-1.1.0 Started Supervisor (12.1ms)
```

- Lines from hostty itself use the name `hostty`.
- Each name gets its own color when stdout is a terminal.

## When a Process Exits

The first process that exits stops all the others:

```text
12:05:00 hostty | jobs exited with code 1.
12:05:00 hostty | Stopping all processes.
```

Hostty then exits with the exit code of that process. See [Stopping](./stopping.md) and the [exit codes](./command-line.md#exit-codes).

## Limits

- A process cannot read input. Hostty connects its stdin to `/dev/null`, so `binding.irb` and password prompts do not work. Use [tabs](./tabs.md) for those.
- A process writes to a pipe, not a terminal. Some programs hold back their output, or drop their colors, until a buffer fills. In Ruby, set `$stdout.sync = true` to print each line at once.

---

[← Return to Features](./README.md)
