<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="../assets/hostty-dark.svg">
    <img src="../assets/hostty-light.svg" alt="Hostty" width="300">
  </picture>
</p>

# Domains

### Contents

- [What a Domain Does](#what-a-domain-does)
- [When Hostty Adds a Domain](#when-hostty-adds-a-domain)
- [Prompts](#prompts)
- [When a Domain Fails](#when-a-domain-fails)
- [Removing a Domain](#removing-a-domain)

## What a Domain Does

A process with a `domain` setting gets a local address, such as `https://shop.test`, that points to its port:

```yaml
processes:
  web:
    command: "bin/rails server -p $PORT"
    domain: "shop.test"
    ssl: true
```

[ruby-nginx](https://github.com/bert-mccutchen/ruby-nginx) does the work for each domain:

- It writes an NGINX server config that sends requests for the domain to the port of the process.
- It adds the domain to `/etc/hosts`.
- It makes an SSL certificate with mkcert, when `ssl` is `true`.
- It restarts NGINX.

```mermaid
flowchart LR
    browser[Browser] -- "https://shop.test" --> hosts["/etc/hosts<br/>shop.test = 127.0.0.1"]
    hosts --> nginx[NGINX]
    nginx -- "localhost:5000" --> web[web process]
```

The [settings](./configuration.md#settings) page lists `ssl`, `log`, and `host`.

## When Hostty Adds a Domain

Hostty adds every domain before it starts any process. It prints one line per domain:

```text
12:00:01 hostty | Adding https://shop.test for web on port 5000.
```

Hostty adds the domains in your real terminal, before the tabs open, so every prompt can ask you for input.

## Prompts

Adding a domain can stop and ask you for input:

- ruby-nginx asks before it installs NGINX or mkcert, when either is missing. It needs both, even for a domain without `ssl`.
- `sudo` asks for your password, because editing `/etc/hosts` and restarting NGINX need root.

ruby-nginx updates `/etc/hosts` on every run, so the password prompt can come back on each start. Your `sudo` timeout decides how often it does.

## When a Domain Fails

When a domain fails, or you decline a prompt, hostty prints the error, starts no process, and exits with code 1:

```text
hostty: NGINX is required to continue. Please install NGINX.
```

ruby-nginx removes the domain that failed. The domains that hostty added before it stay in place.

## Removing a Domain

Hostty keeps every domain after it exits. To remove one, delete its line from `/etc/hosts` and its server config from `~/.ruby-nginx/servers`, then restart NGINX. The ruby-nginx command line can also remove a domain.

---

[← Return to Features](./README.md)
