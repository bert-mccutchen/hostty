<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="../assets/hostty-dark.svg">
    <img src="../assets/hostty-light.svg" alt="Hostty" width="300">
  </picture>
</p>

# Tabs

### Contents

- [When Hostty Shows Tabs](#when-hostty-shows-tabs)
- [The Screen](#the-screen)
- [Keys and Mouse](#keys-and-mouse)
- [Typing Into a Process](#typing-into-a-process)
- [Scrolling](#scrolling)
- [Exited Processes and Restarts](#exited-processes-and-restarts)
- [Selecting Text](#selecting-text)

## When Hostty Shows Tabs

Hostty shows tabs when both stdin and stdout are terminals. Otherwise, and with `--plain`, it prints [plain output](./plain-output.md).

The tabs need libghostty-vt. The [terminal emulator](./terminal-emulator.md) page covers what works inside a tab.

## The Screen

```text
 ● web  ● docs  ● jobs                                     https://shop.test
=> Booting Puma
=> Rails 8.0.0 application starting in development
* Listening on http://127.0.0.1:5000
Use Ctrl-C to stop



 Switch: click or Shift+Tab | Scroll: history | [restart] | Quit: Ctrl-C twice
```

- The top row shows a tab per process. The selected tab is blue.
- The dot in each tab is green while the process runs and red after it exits.
- When a process in another tab rings the bell, the dot of its tab blinks yellow until you select that tab.
- When a process rings the bell while your terminal window is out of focus, hostty also rings your terminal's bell. Your terminal clears its own bell mark when you return to the window.
- When the selected process has a [domain](./domains.md), the right end of the top row shows its URL. Click the URL to open it in your browser.
- The middle rows show the selected process, as a terminal would show it.
- The bottom row is the help bar. `[restart]` is a button.

The screen fits the window, and it redraws when you resize the window. Each process also gets the new size.

## Keys and Mouse

| Action | What it does |
| --- | --- |
| Click a tab | Shows that process. |
| Click the URL | Opens the domain of the selected process in your browser, with `open` on macOS or `xdg-open` on Linux. |
| Shift+Tab | Shows the next process. After the last tab, it goes back to the first. |
| Mouse wheel | Scrolls the selected process. See [Scrolling](#scrolling). |
| Drag across the output | Selects the text and copies it. See [Selecting Text](#selecting-text). |
| Click `[restart]` | Restarts the selected process. |
| Ctrl-C | Sends Ctrl-C to the selected process. |
| Ctrl-C twice within half a second | Quits hostty. See [Stopping](./stopping.md). |
| Any other key | Goes to the selected process. |

The first Ctrl-C of a double press also goes to the selected process.

Hostty keeps Shift+Tab for itself, so a process never gets it.

When a program turns on mouse reporting, as `btop`, `htop`, and `vim` do, the clicks, drags, and wheel steps inside its tab go to the program. Hold Shift while you drag to select text in that tab instead. Some terminals, such as Ghostty, keep a Shift drag for their own selection, so hostty never sees it. Clicks on the tab bar and the help bar always stay with hostty.

## Typing Into a Process

Each process runs in its own terminal inside hostty. Programs that read from a terminal work in their tab:

- `binding.irb` and `debugger` in a Rails app.
- A `sudo` password prompt.
- irb, a shell, or any other interactive program.

Click the tab of the process, then type.

## Scrolling

What a mouse wheel step does depends on the program in the tab:

| The program | A wheel step |
| --- | --- |
| Turned on mouse reporting, such as `btop`, `htop`, or `vim` | Goes to the program, which scrolls its own list or text. |
| Shows a full screen without mouse reporting, such as `less` or `man` | Sends 3 up or down arrow keys to the program. |
| Prints lines, such as a Rails server or a test runner | Scrolls 3 lines through the older output. The help bar shows how far up you are, such as `Scrolled up 30`. |

- Hostty keeps the last 5000 lines of each process.
- A key press goes back to the newest output.

## Exited Processes and Restarts

When a process exits, the other processes keep running. Its tab turns red, and its screen shows the exit code:

```text
[hostty] web exited with code 1.
```

Click `[restart]` to start it again, with the same command and port. A process that still runs gets TERM first, then starts again after it exits.

## Selecting Text

Drag across the output of a process to select its text. Hostty highlights the selection and copies the text when you let go of the mouse button. The selection stays inside the tab, so it never includes the tab bar or the help bar.

- Hostty drops the spaces at the end of each line.
- To select more than one screen, drag onto the tab bar or the help bar. The output scrolls while you hold the pointer there, and it scrolls faster the longer you hold. The mouse wheel also scrolls during a drag.
- The selection stays on its lines when the output scrolls.
- A key press, a resize, or a click elsewhere in the output clears the selection.
- In a program with mouse reporting, such as `btop`, a plain drag goes to the program. Hold Shift to select instead.

Hostty copies the text in two ways, so it works in most setups:

- An OSC 52 escape code, which your terminal turns into a clipboard write. Ghostty, kitty, WezTerm, and Alacritty accept it. iTerm2 accepts it after you turn on "Applications in terminal may access clipboard".
- The first clipboard command it finds: `pbcopy` on macOS, or `wl-copy`, `xclip`, or `xsel` on Linux.

Your terminal's own selection still works with a modifier key held while you drag. That key is Option in Terminal and iTerm2, and Shift in Ghostty and most Linux terminals.

---

[← Return to Features](./README.md)
