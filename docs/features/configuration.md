<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="../assets/hostty-dark.svg">
    <img src="../assets/hostty-light.svg" alt="Hostty" width="300">
  </picture>
</p>

# Configuration

### Contents

- [The Config File](#the-config-file)
- [Top-Level Settings](#top-level-settings)
- [Process Settings](#process-settings)
- [Ports](#ports)
- [Environment Variables](#environment-variables)
- [Working Directory and Shell](#working-directory-and-shell)
- [Config Errors](#config-errors)

## The Config File

Hostty reads `.hostty.yml` from the current directory. Use the `--file` option to read another file. The [command line](./command-line.md) page lists every option.

The file lists the processes under `processes`, with settings for all of them next to it:

```yaml
skip_used_ports: true
processes:
  web:
    command: "bin/rails server -p $PORT"
    domain: "shop.test"
    ssl: true
  docs:
    command: "bundle exec jekyll serve --port $PORT"
    port: "random"
  jobs:
    command: "bin/jobs"
    env:
      JOB_CONCURRENCY: "2"
```

A process with only a command can be a plain string:

```yaml
processes:
  jobs: "bin/jobs"
```

Hostty starts the processes in the order of the file. The tabs and the [ports](#ports) follow the same order.

## Top-Level Settings

| Setting | Required | What it does |
| --- | --- | --- |
| `processes` | Yes | The processes to run, by name. |
| `skip_used_ports` | No | When `true`, hostty moves a process to the next free port when its port is in use. When `false`, a port in use stops hostty. Defaults to `false`. See [Ports](#ports). |

## Process Settings

| Setting | Required | What it does |
| --- | --- | --- |
| `command` | Yes | The command to run. |
| `domain` | No | A local domain for the process, such as `shop.test`. See [Domains](./domains.md). |
| `ssl` | No | Serve the domain over HTTPS. Defaults to `false`. |
| `log` | No | Write NGINX access and error logs for the domain to `~/.ruby-nginx/logs`. Defaults to `false`. |
| `host` | No | The address that the domain points to and that NGINX sends requests to. Defaults to `127.0.0.1`. |
| `root` | No | The directory NGINX serves static files from, relative to the config file. See [NGINX Configs](./domains.md#nginx-configs). |
| `template` | No | The NGINX server config for the domain: `"rails"`, `"proxy"`, or the path to an ERB file. See [NGINX Configs](./domains.md#nginx-configs). |
| `port` | No | A port number, or `"random"`. See [Ports](#ports). |
| `env` | No | More environment variables for the process. |

## Ports

Hostty sets `PORT` for each process. The `port` setting of the process decides where the port comes from:

| `port` setting | Port | When the port is in use |
| --- | --- | --- |
| Not set | From the position of the process. The first process gets 5000, and each next process gets 100 more. | Follows `skip_used_ports`. |
| `"random"` | A random port from 10000 to 59999. | Follows `skip_used_ports`. |
| A number, such as `3000` | That port. | Always stops. Hostty never moves a port that you set. |

Before it adds a domain or starts a process, hostty checks that it can open each port:

- With `skip_used_ports: false`, a port in use stops hostty with an error.
- With `skip_used_ports: true`, hostty tries the next port up, as many as 100 ports, and prints the change:

  ```text
  12:00:01 hostty | Port 5000 for web is in use. web uses 5001.
  ```

Other details:

- The `--port` option changes the first position port. `hostty --port 3000` gives 3000, 3100, and 3200.
- Hostty gives the processes with a port number their ports first. A position port or a random port never takes a port that another process sets.
- A domain sends its requests to the port of its process, so the command must listen on `$PORT`.
- A [restart](./tabs.md#exited-processes-and-restarts) keeps the port that the process got at start.
- Another program can still take a port in the short gap after the check and before the process opens it.
- On macOS, AirPlay Receiver uses port 5000. Turn AirPlay Receiver off, start from another port with `--port`, or set `skip_used_ports: true`.

## Environment Variables

Each process gets the environment of hostty, plus `PORT`, plus its `env` setting. Hostty turns every `env` value into a string.

An `env` setting cannot change `PORT`. Use the `port` setting for that.

## Working Directory and Shell

- Each process runs in the directory of the config file, even when you start hostty from another directory.
- Hostty runs each command with `/bin/sh -c`, so shell syntax such as `$PORT`, `&&`, and pipes works.

## Config Errors

Hostty stops before it adds a domain or starts a process when the config file has an error. It prints the error and exits with code 1:

| The config file has | Hostty prints |
| --- | --- |
| No file at the path | `No config file at <path>.` |
| A YAML syntax error | `The config file at <path> is not valid YAML: <details>` |
| No processes under `processes` | `The config file at <path> must list at least one process under processes.` |
| A top-level setting hostty does not know | `The config file at <path> has unknown settings: <settings>.` |
| A `skip_used_ports` that is not `true` or `false` | `skip_used_ports must be true or false.` |
| A process with no command | `<name> needs a command.` |
| A process setting hostty does not know | `<name> has unknown settings: <settings>.` |
| A `root` or `template` that is not text | `<name> needs a text value for its <setting>.` |
| A port that is not a number from 1 to 65535, or `"random"` | `<name> needs a port from 1 to 65535, or "random".` |
| A port in use, with `skip_used_ports: false` | `Port <port> for <name> is in use. Free the port, or set skip_used_ports to true.` |
| A port number that is in use | `Port <port> for <name> is in use. Free the port, or change the port of <name>.` |
| Two processes on one port | `<name> and <name> both use port <port>.` |
| No free port within 100 ports, with `skip_used_ports: true` | `No free port for <name> from <first> to <last>.` |
| Two processes with one domain | `More than one process uses the domain <domain>.` |

---

[← Return to Features](./README.md)
