<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="../assets/hostty-dark.svg">
    <img src="../assets/hostty-light.svg" alt="Hostty" width="300">
  </picture>
</p>

# Features

### Contents

- [Pages](#pages)
- [How a Run Goes](#how-a-run-goes)

## Pages

- [Configuration](./configuration.md): the `.hostty.yml` file, ports, and environment variables.
- [Command Line](./command-line.md): the options and the exit codes.
- [Domains](./domains.md): local domains with NGINX and SSL.
- [Tabs](./tabs.md): the tab view, the keys, and the mouse.
- [Plain Output](./plain-output.md): the output of all processes together, for CI and pipes.
- [Stopping](./stopping.md): how hostty stops the processes.
- [Terminal Emulator](./terminal-emulator.md): which terminal features work inside a tab.

## How a Run Goes

```mermaid
flowchart TD
    start([hostty]) --> config[Read .hostty.yml]
    config --> domains[Add each domain]
    domains --> mode{Are stdin and stdout<br/>both terminals?}
    mode -- yes --> tabs[Show the processes in tabs]
    mode -- "no, or the plain option" --> plain[Print the output of all processes together]
    tabs --> quit[Ctrl-C twice, or TERM or HUP]
    plain --> first[Ctrl-C, TERM, HUP,<br/>or the first process exit]
    quit --> stop[Stop every process]
    first --> stop
    stop --> done([Exit])
```

Hostty keeps the domains after it exits.

---

[← Return to Hostty](../../README.md)
