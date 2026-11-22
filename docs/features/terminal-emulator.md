<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="../assets/hostty-dark.svg">
    <img src="../assets/hostty-light.svg" alt="Hostty" width="300">
  </picture>
</p>

# Terminal Emulator

### Contents

- [What It Does](#what-it-does)
- [What Works](#what-works)
- [What Hostty Does Not Pass On](#what-hostty-does-not-pass-on)
- [Speed](#speed)

## What It Does

Each [tab](./tabs.md) shows its process the way a terminal would. Hostty writes the output of each process into [libghostty-vt](https://lib.ghostty.org/vt/), the terminal engine of [Ghostty](https://ghostty.org). libghostty-vt keeps a screen of characters and colors for each process, and Hostty draws the screen of the selected tab.

The [installation](../../README.md#installation) section says where Hostty gets libghostty-vt. Without it, Hostty stops before it shows the tabs:

```text
hostty: Tabs need libghostty-vt, which did not load (<details>). Run with --plain to skip the tabs.
```

## What Works

libghostty-vt reads the escape codes that a program writes the same way Ghostty does. That covers:

- Rails, Puma, Jekyll, Solid Queue, test runners, and other logs.
- irb, `binding.irb`, debug, and a shell.
- Full-screen programs, such as `btop`, `htop`, `vim`, `less`, and `tig`.

Hostty draws these from the screen:

| Area | Drawn |
| --- | --- |
| Text | UTF-8, wide characters such as CJK and emoji, and characters made of more than one code point. |
| Colors | 16, 256, and 24-bit colors, for text and background. |
| Text styles | Bold, dim, italic, underline, blink, inverse, invisible, strikethrough, and overline. |
| Screens | The main screen with its scrollback, and the alternate screen. |
| Resize | Wrapped lines on the main screen reflow when the window changes width. |
| Replies | libghostty-vt answers queries such as the cursor position and the device attributes, and Hostty writes the answer back to the process. |
| The bell | Hostty marks the tab, and it rings your terminal's bell while the window is out of focus. See [the screen of the tabs](./tabs.md#the-screen). |
| Focus changes | A program that asks for focus changes, such as `vim`, gets them while its tab is selected. |

## What Hostty Does Not Pass On

libghostty-vt tracks more than Hostty draws or forwards:

| Missing | What you see |
| --- | --- |
| Underline styles and underline colors | A plain underline, in the text color. |
| Images, such as Kitty graphics | Nothing in the place of the image. |
| Links | The link text, without a link. |
| Cursor shape | Your terminal's own cursor. |
| Window titles and clipboard writes | Nothing. |
| Keyboard modes other than application cursor keys and bracketed paste | Keys arrive in the form your terminal sends them. |

## Speed

- libghostty-vt reads about 450 to 1,800 MB of output a second on one CPU core, so a process that floods its output does not slow hostty down.
- Hostty reads the screen from libghostty-vt before each frame. A read takes about 1 ms at 80 by 24 and about 8 ms at 200 by 50. Hostty reads only the selected tab, at most about 60 times a second.

---

[← Return to Features](./README.md)
