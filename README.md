# mac_cleaner.py

A safe, **preview-first** disk-space recovery tool for macOS. It scans the folders that quietly eat gigabytes — caches, logs, old downloads, dev-tool leftovers, iOS backups, Docker data — shows you exactly what it found, and **deletes nothing until you confirm each category by hand.**

No installs, no dependencies, no daemon running in the background. One file, pure Python standard library.

> ⚠️ **Use at your own risk.** This tool permanently deletes files. It shows you everything first and asks before each category, but the final call is yours. No warranty — see [License](#license).

```
╔══════════════════════════════════════════════════════════════╗
║          macOS Disk Cleaner - Smart Purge<img width="1418" height="819" alt="macos_diskcleaner" src="https://github.com/user-attachments/assets/b2aafef1-e3b5-4cf8-b1a7-e4aaa7ec496f" />
         ║
╚══════════════════════════════════════════════════════════════╝
```

---

## Why this one?

Most "Mac cleaner" tools fall into two camps: bloated commercial apps that nag you for a subscription, or aggressive shell scripts that `rm -rf` things before you can blink. This sits deliberately in the middle:

- **Preview-first, always.** It runs a full scan and prints a sorted report *before* touching anything. The scan phase physically cannot delete a file.
- **Confirmation per category, not all-or-nothing.** You approve Trash but skip Downloads, or clean Docker but keep your iOS backups. Your call, every time.
- **Zero dependencies.** Standard library only. Nothing to `pip install`, nothing to trust but the ~800 lines you can read yourself.
- **Human-readable output.** Color-coded, sorted by size, with a `v` option to list the actual files inside any category before you commit.
- **Developer-aware.** It knows where the real space goes on a dev machine — Xcode `DerivedData`, npm/pip/yarn/cargo caches, Homebrew, Docker — not just the browser cache.
- **Conservative by design.** It skips known-sensitive caches (CloudKit, Safari, iCloud metadata), only reports files above a size threshold, and never counts symlinks twice.

It's a utility you can actually hand to a client, a coworker, or your past self — and trust that it won't nuke something important.

---

## Requirements

- macOS (tested on Monterey, Ventura, Sonoma)
- Python 3.6 or newer (ships with macOS)
- No external packages

---

## Usage

```bash
python3 mac_cleaner.py
```

That's the whole command. The script is **fully interactive** — there are no command-line flags. It walks you through three phases:

1. **Scan** — checks each location and reports what it finds (read-only).
2. **Report** — a summary sorted largest-first, with total recoverable space.
3. **Interactive cleanup** — you're asked about each category one at a time.

### Optional: run with elevated access

```bash
sudo python3 mac_cleaner.py
```

Running with `sudo` lets it reach system locations like `/var/log` and `/private/var/tmp`. Without it, the script simply skips anything it can't read (you'll see harmless "Operation not permitted" notes — that's expected, not an error). Only use `sudo` if you understand what you're clearing.

### During cleanup, per category you can type:

| Key | Action                                            |
|-----|---------------------------------------------------|
| `y` | Delete everything in this category                |
| `n` | Skip this category                                |
| `v` | View the individual items (top 20) before deciding |
| `q` | Quit — stops immediately, keeps what's already freed |

---

## What it scans

The scanner covers 12 categories, reported largest-first:

| Category                  | What it targets                                                        |
|---------------------------|------------------------------------------------------------------------|
| **Trash**                 | `~/.Trash` — already marked for deletion, easy win                     |
| **User Application Caches** | `~/Library/Caches` — apps rebuild these automatically                |
| **Browser Caches**        | Chrome, Firefox, Safari, Brave, Edge, Arc (keeps cookies/logins)      |
| **System & Application Logs** | `~/Library/Logs` and `/var/log`, older than 7 days               |
| **Old Downloads**         | `~/Downloads` items older than 30 days                                |
| **Package Manager Caches** | npm, pip, yarn, cargo, composer, gem, CocoaPods                     |
| **Homebrew Cache**        | Downloaded formulae and old versions                                  |
| **Xcode Data**            | `DerivedData`, Archives, iOS DeviceSupport, Simulator caches (often 10–50+ GB) |
| **iOS Device Backups**    | iPhone/iPad backups — can be *massive*, keep a recent one!            |
| **Docker Data**           | Images, containers, volumes (consider `docker system prune` instead)  |
| **Mail Downloads & Attachments** | Cached attachments — originals stay on the mail server         |
| **Miscellaneous Temp**    | `/tmp`, `~/.cache`, VS Code, Slack, Zoom, Spotify caches, and more    |

Only items larger than **1 MB** are reported, so the output stays focused on files that actually matter.

---

## Configuration

There are no flags, but two constants near the top of the file control behavior. Edit them to taste:

```python
DOWNLOADS_AGE_DAYS   = 30              # flag Downloads older than this
MIN_FILE_SIZE_REPORT = 1024 * 1024     # ignore anything smaller than 1 MB
```

---

## Safety notes

- **Nothing is deleted during scanning or reporting** — those phases only read.
- **Every deletion requires an explicit `y`** for that specific category.
- **Deletions are permanent.** Files removed by this tool do *not* go to the Trash — they're gone. Use `v` to inspect a category first if you're unsure.
- **Keep at least one recent iOS backup** before clearing that category.
- For **Docker**, prefer `docker system prune` so Docker's own bookkeeping stays consistent; the raw-folder delete here is a blunt fallback.
- The tool intentionally leaves sensitive caches (CloudKit, Safari data, iCloud metadata) alone.

> Review the report before confirming. This deletes real files. You are in control of every category — treat that responsibility accordingly.

---

## Example session



## License

**Free for everyone.** Released under the [MIT License](LICENSE) — use it, copy it, modify it, share it, ship it in your own projects, do whatever you like. No permission needed, no strings attached.

Provided **as is, with no warranty**. If it deletes something you wanted, that's on you — see the disclaimer above.

---

*Built by Brandon / WichitaComputerSolutions.com *
