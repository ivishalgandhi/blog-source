# Fix "xterm-ghostty: unknown terminal type" Error

When connecting to a remote Ubuntu machine from a MacBook using Ghostty, you may encounter the error:
'xterm-ghostty': unknown terminal type.

This occurs because the remote machine lacks Ghostty's terminfo entry. Here's how to fix it.

## Solution

Run the following command on your MacBook, replacing `user@ubuntu-host` with your actual SSH details:

```bash
infocmp -x xterm-ghostty | ssh user@ubuntu-host -- tic -x -
```

This copies Ghostty's terminfo entry to the Ubuntu machine, enabling commands like `clear` to work.

## Notes

If you see a warning like `"'<stdin>', line 2, col 31, terminal 'xterm-ghostty': older tic versions may treat the description field as an alias"`, it’s harmless and can be ignored.

To eliminate the warning, update `ncurses` on Ubuntu:

```bash
sudo apt update && sudo apt install ncurses-bin
```

Alternatively, remove the description field:

```bash
infocmp -x xterm-ghostty | sed '1 s/|.*$//' | ssh user@ubuntu-host -- tic -x -
```

If you can't copy the terminfo, add this to `~/.ssh/config` on your MacBook (create the file if needed):

```
Host ubuntu-host
  SetEnv TERM=xterm-256color
```

**Note:** This fallback may limit some Ghostty features.

After applying the fix, reconnect via SSH.
