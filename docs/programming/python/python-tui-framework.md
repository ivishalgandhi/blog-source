# Building a Generic TUI Framework in Python
### Plug any data source — SQL, Python objects, REST APIs — into a reusable terminal UI

---

## Overview

The llmfit project shows what a polished terminal UI can look like. Its interactive
table, keyboard navigation, live filtering, and multi-theme support are all achievable
in Python using **Textual**, **Rich**, and **psutil** — without writing a line of Rust.

This article goes one step further: instead of a one-off TUI for a single purpose, we
design a **layered, provider-based architecture** that lets you swap any data source in
or out without touching the UI layer. The same shell can drive a SQL query monitor, a
live process viewer, a Pandas DataFrame explorer, or a REST API dashboard.

---

## Architecture: Four Layers

```
┌─────────────────────────────────────────────────────┐
│  Layer 1 — TUI Presentation                         │
│  Textual app · tabs · themes · keybindings · table  │
└──────────────────────┬──────────────────────────────┘
                       │  calls columns() / rows()
┌──────────────────────▼──────────────────────────────┐
│  Layer 2 — BaseProvider interface (abstract)        │
│  columns() · rows() · on_action()                   │
└───────────┬──────────────┬──────────────────────────┘
            │              │              │
   ┌────────▼───┐  ┌───────▼──────┐  ┌───▼──────────┐
   │ SQLProvider│  │PythonProvider│  │ HTTPProvider  │
   └────────────┘  └──────────────┘  └──────────────┘
            │              │              │
   ┌────────▼───┐  ┌───────▼──────┐  ┌───▼──────────┐
   │  Database  │  │ Python app / │  │ REST / JSON  │
   │ (any DB-   │  │ psutil/pandas│  │     API      │
   │  API 2.0)  │  └──────────────┘  └──────────────┘
   └────────────┘
```

**The rule**: Layers only talk to their immediate neighbour. The TUI never imports a
database driver. A provider never imports a Textual widget.

---

## Dependencies

```bash
pip install textual rich psutil
```

For SQL backends, add the driver you need:

```bash
pip install psycopg2-binary   # PostgreSQL
pip install duckdb            # DuckDB
# sqlite3 is part of the Python standard library
```

---

## Layer 2 — The Provider Interface

This is the only piece every integration must implement. Write it once and never change it.

```python
# provider.py
from abc import ABC, abstractmethod
from rich.text import Text


class BaseProvider(ABC):
    """
    Abstract base for all data providers.

    Subclass this and implement columns() + rows().
    Optionally override on_action() to handle row-level keypresses.
    """

    @abstractmethod
    def columns(self) -> list[str]:
        """
        Return the list of column header names.
        Order must match the order of values in each row dict.
        """
        ...

    @abstractmethod
    def rows(self) -> list[dict]:
        """
        Return the current dataset as a list of dicts.
        Each dict must contain a key for every column name returned by columns().
        Called on every refresh — keep it fast or cache internally.
        """
        ...

    def title(self) -> str:
        """Optional: display name shown in the TUI title bar."""
        return self.__class__.__name__

    def refresh_interval(self) -> float | None:
        """
        Optional: if a float is returned, the TUI will re-call rows() on that
        interval (in seconds). Return None to disable auto-refresh.
        """
        return None

    def on_action(self, key: str, row: dict) -> str | None:
        """
        Optional: called when the user presses a bound key on a selected row.
        Return a short status string to display, or None to do nothing.

        Example keys you might bind: 'd' for delete, 'r' for retry, 'o' for open.
        """
        return None

    def style_row(self, row: dict) -> dict[str, str]:
        """
        Optional: return a dict mapping column names to Rich style strings.
        Use to colour individual cells based on data values.

        Example:
            if row['status'] == 'error':
                return {'status': 'bold red', 'message': 'red'}
            return {}
        """
        return {}
```

---

## Layer 3 — Concrete Providers

### SQL Provider

Works with any [PEP 249](https://peps.python.org/pep-0249/) compliant driver:
`sqlite3`, `psycopg2`, `duckdb`, `pymysql`, `pyodbc`, etc.

```python
# providers/sql.py
import sqlite3
from provider import BaseProvider


class SQLProvider(BaseProvider):
    """
    Execute a SQL query and expose the result set as TUI rows.

    Args:
        dsn:        connection string or file path (sqlite3 style)
        query:      SQL SELECT statement
        params:     optional bind parameters (tuple or dict)
        driver:     any PEP 249 module; defaults to sqlite3
        interval:   auto-refresh interval in seconds (None = no refresh)
        title:      label shown in TUI title bar
    """

    def __init__(
        self,
        dsn: str,
        query: str,
        params: tuple | dict = (),
        driver=None,
        interval: float | None = None,
        title: str = "SQL Viewer",
    ):
        self._driver  = driver or sqlite3
        self._conn    = self._driver.connect(dsn)
        self._query   = query
        self._params  = params
        self._interval = interval
        self._title   = title

    def title(self) -> str:
        return self._title

    def refresh_interval(self) -> float | None:
        return self._interval

    def columns(self) -> list[str]:
        cur = self._conn.execute(self._query, self._params)
        return [desc[0] for desc in cur.description]

    def rows(self) -> list[dict]:
        cur  = self._conn.execute(self._query, self._params)
        cols = [desc[0] for desc in cur.description]
        return [dict(zip(cols, row)) for row in cur.fetchall()]

    def style_row(self, row: dict) -> dict[str, str]:
        # Example: highlight rows where a 'status' column signals a problem
        styles = {}
        if row.get("status") in ("error", "failed", "critical"):
            styles["status"] = "bold red"
        elif row.get("status") in ("warning", "pending"):
            styles["status"] = "yellow"
        elif row.get("status") in ("ok", "success", "running"):
            styles["status"] = "green"
        return styles
```

**Usage examples:**

```python
# SQLite — local file
provider = SQLProvider(
    dsn="app.db",
    query="SELECT id, name, status, created_at FROM jobs ORDER BY created_at DESC",
    interval=5.0,       # re-query every 5 seconds
    title="Job Monitor",
)

# PostgreSQL via psycopg2
import psycopg2
provider = SQLProvider(
    dsn="host=localhost dbname=myapp user=admin password=secret",
    query="SELECT pid, usename, state, query FROM pg_stat_activity WHERE state != 'idle'",
    driver=psycopg2,
    interval=3.0,
    title="PG Active Queries",
)

# DuckDB — query a Parquet file directly
import duckdb
provider = SQLProvider(
    dsn=":memory:",
    query="SELECT * FROM read_parquet('events.parquet') ORDER BY ts DESC LIMIT 500",
    driver=duckdb,
    title="Events",
)
```

---

### Python Object Provider

Wraps any callable that returns a list of dicts. Works with `psutil`, `pandas`,
custom classes, generators, anything.

```python
# providers/python_obj.py
from typing import Callable
from provider import BaseProvider


class PythonProvider(BaseProvider):
    """
    Wrap any Python callable as a TUI data source.

    Args:
        data_fn:    callable() -> list[dict]  — called on every refresh
        col_names:  ordered list of column headers
        interval:   auto-refresh interval in seconds
        title:      label shown in TUI title bar
        styler:     optional callable(row) -> dict[str, str] for per-cell styles
        actions:    dict mapping key -> callable(row) -> str | None
    """

    def __init__(
        self,
        data_fn: Callable[[], list[dict]],
        col_names: list[str],
        interval: float | None = None,
        title: str = "Python Viewer",
        styler: Callable | None = None,
        actions: dict[str, Callable] | None = None,
    ):
        self._fn       = data_fn
        self._cols     = col_names
        self._interval = interval
        self._title    = title
        self._styler   = styler
        self._actions  = actions or {}

    def title(self) -> str:           return self._title
    def refresh_interval(self):       return self._interval
    def columns(self) -> list[str]:   return self._cols
    def rows(self) -> list[dict]:     return self._fn()

    def style_row(self, row: dict) -> dict[str, str]:
        return self._styler(row) if self._styler else {}

    def on_action(self, key: str, row: dict) -> str | None:
        fn = self._actions.get(key)
        return fn(row) if fn else None
```

**Usage examples:**

```python
import psutil
import pandas as pd

# Process monitor — live CPU/memory per process
def get_processes():
    return [
        {
            "pid":    p.pid,
            "name":   p.name(),
            "cpu%":   f"{p.cpu_percent():.1f}",
            "mem MB": f"{p.memory_info().rss / 1024**2:.1f}",
            "status": p.status(),
        }
        for p in psutil.process_iter(["name", "cpu_percent", "memory_info", "status"])
    ]

provider = PythonProvider(
    data_fn=get_processes,
    col_names=["pid", "name", "cpu%", "mem MB", "status"],
    interval=2.0,
    title="Process Monitor",
    styler=lambda row: {"cpu%": "red"} if float(row["cpu%"]) > 50 else {},
)

# Pandas DataFrame viewer
df = pd.read_csv("results.csv")
provider = PythonProvider(
    data_fn=lambda: df.to_dict("records"),
    col_names=list(df.columns),
    title="Results",
)

# Custom app data — e.g. a task queue
provider = PythonProvider(
    data_fn=lambda: task_queue.get_pending(),
    col_names=["id", "task", "priority", "retries", "next_run"],
    interval=1.0,
    title="Task Queue",
    actions={
        "d": lambda row: task_queue.delete(row["id"]) or f"Deleted {row['id']}",
        "r": lambda row: task_queue.retry(row["id"])  or f"Retrying {row['id']}",
    },
)
```

---

### HTTP Provider

For REST APIs or JSON endpoints that return lists.

```python
# providers/http.py
import urllib.request
import json
from provider import BaseProvider


class HTTPProvider(BaseProvider):
    """
    Fetch a JSON array from an HTTP endpoint.

    The endpoint must return either:
      - a JSON array:                   [ {...}, {...} ]
      - a JSON object with a list key:  { "results": [...] }

    Args:
        url:        full URL to GET
        list_key:   if the response is a dict, the key containing the list
        col_names:  column headers (inferred from first row if omitted)
        interval:   auto-refresh in seconds
        title:      TUI title bar label
        headers:    extra HTTP headers (e.g. Authorization)
    """

    def __init__(
        self,
        url: str,
        list_key: str | None = None,
        col_names: list[str] | None = None,
        interval: float | None = 10.0,
        title: str = "HTTP Viewer",
        headers: dict | None = None,
    ):
        self._url      = url
        self._list_key = list_key
        self._cols     = col_names
        self._interval = interval
        self._title    = title
        self._headers  = headers or {}
        self._cache: list[dict] = []

    def title(self):              return self._title
    def refresh_interval(self):   return self._interval

    def _fetch(self) -> list[dict]:
        req = urllib.request.Request(self._url, headers=self._headers)
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = json.loads(resp.read())
        return data[self._list_key] if self._list_key else data

    def columns(self) -> list[str]:
        if self._cols:
            return self._cols
        rows = self._fetch()
        self._cache = rows
        return list(rows[0].keys()) if rows else []

    def rows(self) -> list[dict]:
        try:
            self._cache = self._fetch()
        except Exception:
            pass   # return stale cache on network error
        return self._cache
```

**Usage examples:**

```python
# Ollama — locally running model list
provider = HTTPProvider(
    url="http://localhost:11434/api/tags",
    list_key="models",
    col_names=["name", "size", "modified_at"],
    interval=5.0,
    title="Ollama Models",
)

# GitHub API — open issues
provider = HTTPProvider(
    url="https://api.github.com/repos/owner/repo/issues?state=open&per_page=50",
    col_names=["number", "title", "user.login", "created_at", "comments"],
    headers={"Authorization": "Bearer YOUR_TOKEN"},
    interval=30.0,
    title="Open Issues",
)

# Any JSON list endpoint
provider = HTTPProvider(
    url="https://yourapi.com/v1/deployments",
    list_key="data",
    interval=10.0,
    title="Deployments",
)
```

---

## Layer 1 — The Generic TUI Shell

This is the only Textual code you need. It is completely data-agnostic.

```python
# tui.py
import platform
import psutil
from rich.text import Text
from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.widgets import DataTable, Static, TabbedContent, TabPane

from provider import BaseProvider

# ── Themes ────────────────────────────────────────────────────────────────────
THEMES = {
    "Default":   {"bg":"#0d0d1a","bg2":"#13132b","hdr_bg":"#1a1a35","hdr_fg":"#5bc8fa","title":"#5bc8fa","cursor":"#1e2a4a","text":"#d0d8f0","dim":"#606880","accent":"#5bc8fa","bar":"#0a0a14"},
    "Dracula":   {"bg":"#282a36","bg2":"#21222c","hdr_bg":"#44475a","hdr_fg":"#bd93f9","title":"#ff79c6","cursor":"#44475a","text":"#f8f8f2","dim":"#6272a4","accent":"#8be9fd","bar":"#191a21"},
    "Solarized": {"bg":"#002b36","bg2":"#073642","hdr_bg":"#073642","hdr_fg":"#268bd2","title":"#2aa198","cursor":"#073642","text":"#839496","dim":"#586e75","accent":"#2aa198","bar":"#00212b"},
    "Nord":      {"bg":"#2e3440","bg2":"#3b4252","hdr_bg":"#434c5e","hdr_fg":"#88c0d0","title":"#81a1c1","cursor":"#434c5e","text":"#d8dee9","dim":"#4c566a","accent":"#88c0d0","bar":"#242933"},
    "Monokai":   {"bg":"#272822","bg2":"#1e1f1c","hdr_bg":"#3e3d32","hdr_fg":"#a6e22e","title":"#f92672","cursor":"#49483e","text":"#f8f8f2","dim":"#75715e","accent":"#66d9e8","bar":"#1a1a16"},
    "Gruvbox":   {"bg":"#282828","bg2":"#3c3836","hdr_bg":"#504945","hdr_fg":"#83a598","title":"#fabd2f","cursor":"#504945","text":"#ebdbb2","dim":"#928374","accent":"#83a598","bar":"#1d2021"},
}
THEME_NAMES = list(THEMES.keys())


def make_css(t: dict) -> str:
    return f"""
Screen {{ background: {t['bg']}; }}
#title-bar {{ background:{t['bar']}; color:{t['title']}; text-style:bold; padding:0 1; height:1; }}
#hw-bar    {{ background:{t['bg2']}; color:{t['text']}; padding:0 1; height:1; }}
#status-bar{{ background:{t['bar']}; color:{t['dim']};  padding:0 1; height:1; }}
TabbedContent, TabPane {{ background:{t['bg']}; height:1fr; padding:0; }}
Tabs  {{ background:{t['bg2']}; }}
Tab   {{ background:{t['bg2']}; color:{t['dim']}; padding:0 2; }}
Tab.-active {{ background:{t['hdr_bg']}; color:{t['accent']}; text-style:bold; }}
Tab:hover   {{ background:{t['hdr_bg']}; color:{t['text']}; }}
DataTable {{ background:{t['bg']}; color:{t['text']}; height:1fr; }}
DataTable > .datatable--header {{ background:{t['hdr_bg']}; color:{t['hdr_fg']}; text-style:bold; }}
DataTable > .datatable--cursor {{ background:{t['cursor']}; }}
DataTable > .datatable--hover  {{ background:{t['bg2']}; }}
#info-panel {{ background:{t['bg']}; color:{t['text']}; padding:1 2; height:1fr; }}
"""


def hw_bar_text() -> str:
    vm = psutil.virtual_memory()
    return (
        f"[bold]RAM[/] {vm.available/1024**3:.1f} GB free / {vm.total/1024**3:.1f} GB  "
        f"[bold]CPU[/] {psutil.cpu_count(logical=False)}c · {(platform.processor() or platform.machine())[:40]}"
    )


class GenericTUI(App):
    """
    A theme-aware, tabbed TUI shell driven by any BaseProvider.

    Tabs:
        Data  — the provider's live table
        Info  — provider metadata + keybinding reference

    Keys:
        t   cycle theme          f   cycle filter (if provider supports it)
        r   force refresh        q   quit
        j/k ↑↓ navigate rows
    """

    BINDINGS = [
        Binding("q", "quit",          "Quit"),
        Binding("t", "cycle_theme",   "Theme"),
        Binding("r", "force_refresh", "Refresh"),
        Binding("j", "cursor_down",   "Down",    show=False),
        Binding("k", "cursor_up",     "Up",      show=False),
    ]

    def __init__(self, provider: BaseProvider):
        super().__init__()
        self.provider   = provider
        self.theme_idx  = 0
        self.CSS        = make_css(THEMES[THEME_NAMES[0]])
        self._status    = ""

    def T(self): return THEMES[THEME_NAMES[self.theme_idx]]

    # ── Compose ───────────────────────────────────────────────────────────────
    def compose(self) -> ComposeResult:
        yield Static(self._title_text(), id="title-bar")
        yield Static(hw_bar_text(),      id="hw-bar")
        with TabbedContent():
            with TabPane(f"📊  {self.provider.title()}", id="tab-data"):
                yield DataTable(id="data-table", cursor_type="row")
            with TabPane("ℹ   Info", id="tab-info"):
                yield Static(self._info_text(), id="info-panel")
        yield Static(self._status_text(), id="status-bar")

    def on_mount(self):
        self.refresh_table()
        interval = self.provider.refresh_interval()
        if interval:
            self.set_interval(interval, self.refresh_table)

    # ── Table refresh ─────────────────────────────────────────────────────────
    def refresh_table(self):
        try:
            table = self.query_one("#data-table", DataTable)
        except Exception:
            return
        cols = self.provider.columns()
        rows = self.provider.rows()
        table.clear(columns=True)
        table.add_columns(*cols)
        t = self.T()
        for row in rows:
            styles = self.provider.style_row(row)
            cells  = []
            for col in cols:
                val  = str(row.get(col, ""))
                style = styles.get(col, t["text"])
                cells.append(Text(val, style=style))
            table.add_row(*cells)
        self._update_status(f"{len(rows)} rows")

    # ── Text builders ─────────────────────────────────────────────────────────
    def _title_text(self):
        name = THEME_NAMES[self.theme_idx]
        return (f"  ⚡ {self.provider.title()}  [dim]·[/]  Theme: {name}"
                f"  [dim]·  t=theme  r=refresh  Tab=switch-tab  q=quit[/]")

    def _status_text(self):
        interval = self.provider.refresh_interval()
        auto = f"  [dim]auto-refresh: {interval}s[/]" if interval else ""
        return f"{self._status}{auto}"

    def _info_text(self):
        c = self.T()["accent"]
        p = self.provider
        interval_str = f"{p.refresh_interval()}s" if p.refresh_interval() else "manual (press r)"
        col_list = ", ".join(p.columns())
        theme_list = "\n".join(
            f"    {'→ ' if i == self.theme_idx else '  '}{n}"
            for i, n in enumerate(THEME_NAMES)
        )
        return (
            f"\n  [{c}]Provider[/{c}]       {p.__class__.__name__}\n"
            f"  [{c}]Title[/{c}]          {p.title()}\n"
            f"  [{c}]Columns[/{c}]        {col_list}\n"
            f"  [{c}]Auto-refresh[/{c}]   {interval_str}\n\n"
            f"  [{c}]Keybindings[/{c}]\n"
            f"    Tab   next tab        t   cycle theme\n"
            f"    r     force refresh   j/k ↑↓  navigate\n"
            f"    q     quit\n\n"
            f"  [{c}]Themes (press t)[/{c}]\n{theme_list}\n"
        )

    def _update_status(self, msg: str):
        self._status = msg
        try:
            self.query_one("#status-bar", Static).update(self._status_text())
        except Exception:
            pass

    def _full_refresh(self):
        self.CSS = make_css(self.T())
        try:
            self.query_one("#title-bar", Static).update(self._title_text())
            self.query_one("#info-panel", Static).update(self._info_text())
        except Exception:
            pass
        self.refresh_table()
        self.refresh()

    # ── Actions ───────────────────────────────────────────────────────────────
    def action_cycle_theme(self):
        self.theme_idx = (self.theme_idx + 1) % len(THEME_NAMES)
        self._full_refresh()

    def action_force_refresh(self):
        self.refresh_table()

    def action_cursor_down(self):
        try: self.query_one("#data-table", DataTable).action_scroll_down()
        except Exception: pass

    def action_cursor_up(self):
        try: self.query_one("#data-table", DataTable).action_scroll_up()
        except Exception: pass
```

---

## Wiring It Together

Three lines is all it takes once the providers are defined:

```python
# main.py
from tui import GenericTUI
from providers.sql import SQLProvider
from providers.python_obj import PythonProvider
from providers.http import HTTPProvider

# --- Option A: SQL ---
provider = SQLProvider(
    dsn="app.db",
    query="SELECT id, name, status, created_at FROM jobs ORDER BY created_at DESC",
    interval=5.0,
    title="Job Monitor",
)

# --- Option B: psutil process monitor ---
import psutil
provider = PythonProvider(
    data_fn=lambda: [
        {"pid": p.pid, "name": p.name(), "cpu%": f"{p.cpu_percent():.1f}",
         "mem MB": f"{p.memory_info().rss / 1024**2:.1f}", "status": p.status()}
        for p in psutil.process_iter(["name","cpu_percent","memory_info","status"])
    ],
    col_names=["pid","name","cpu%","mem MB","status"],
    interval=2.0,
    title="Process Monitor",
    styler=lambda row: {"cpu%": "bold red"} if float(row["cpu%"]) > 50 else {},
)

# --- Option C: Ollama REST API ---
provider = HTTPProvider(
    url="http://localhost:11434/api/tags",
    list_key="models",
    col_names=["name","size","modified_at"],
    interval=5.0,
    title="Ollama Models",
)

# --- Launch ---
GenericTUI(provider).run()
```

---

## File Layout

```
my_tui_project/
├── provider.py              # BaseProvider abstract class
├── tui.py                   # GenericTUI Textual app
├── providers/
│   ├── __init__.py
│   ├── sql.py               # SQLProvider
│   ├── python_obj.py        # PythonProvider
│   └── http.py              # HTTPProvider
└── main.py                  # entry point — pick your provider and run
```

---

## Key Design Principles

### 1. The interface is the contract

`BaseProvider` has exactly three required methods: `columns()`, `rows()`, and
`on_action()`. As long as a class implements these, the TUI doesn't care what's
behind it. A provider can query a database, call an API, parse a log file, or
generate data in memory — the TUI never knows or needs to know.

### 2. Live refresh is opt-in

Return a float from `refresh_interval()` and the TUI automatically polls that
provider on that cadence. Return `None` and data is only fetched on mount or when
the user presses `r`. This lets you use the same shell for both static datasets and
live dashboards.

### 3. Style logic belongs in the provider

`style_row()` keeps visual feedback close to the data that drives it. The TUI layer
just applies whatever the provider says — it never contains `if status == 'error'`
conditions. This means you can unit-test your styling logic without spinning up a TUI.

### 4. Themes are pure CSS

Each theme is a flat dict of hex color strings. `make_css()` turns it into a
Textual CSS string. Cycling themes is a single index increment plus a CSS rebuild —
no widget state changes, no re-renders of individual cells.

### 5. Actions stay in the provider

`on_action(key, row)` lets each provider define what pressing `d`, `r`, `o`, etc.
does for a selected row. The TUI just forwards the keypress and row. This means
action logic lives with the data logic, not scattered through the UI layer.

---

## Extending the Framework

### Adding a new tab to every TUI

Add the pane inside `compose()` in `tui.py` once. All providers benefit immediately:

```python
with TabPane("📈  Stats", id="tab-stats"):
    yield Static(self._stats_text(), id="stats-panel")
```

### Adding a provider-specific tab

Override a `extra_tab()` method on `BaseProvider` and check for it in `compose()`:

```python
# In BaseProvider
def extra_tab(self) -> tuple[str, str] | None:
    """Return (tab_label, content_text) or None."""
    return None

# In GenericTUI.compose()
extra = self.provider.extra_tab()
if extra:
    label, content = extra
    with TabPane(label, id="tab-extra"):
        yield Static(content, id="extra-panel")
```

### Sorting and filtering

Add `sort_key` and `filter_fn` parameters to `BaseProvider.__init__()`, apply them
inside `rows()`, and expose key bindings in the TUI to cycle through them:

```python
class SQLProvider(BaseProvider):
    def __init__(self, ..., sort_col: str = "id", ascending: bool = True):
        self._sort_col  = sort_col
        self._ascending = ascending

    def rows(self):
        direction = "ASC" if self._ascending else "DESC"
        cur = self._conn.execute(
            f"{self._query} ORDER BY {self._sort_col} {direction}",
            self._params
        )
        ...
```

### Streaming / async providers

Textual is async-native. If your data source is async (websocket, async DB driver,
`aiohttp`), subclass `BaseProvider` and use `async def rows()`. In `GenericTUI`,
call it with `await self.provider.rows()` inside a `worker`:

```python
@work
async def refresh_table_async(self):
    rows = await self.provider.rows()
    # update table on the main thread
    self.call_from_thread(self._apply_rows, rows)
```

---

## Summary

| What you build once | What you swap per use case |
|---|---|
| `BaseProvider` ABC | `SQLProvider` query string |
| `GenericTUI` Textual app | `PythonProvider` lambda |
| All 6 themes | `HTTPProvider` URL + key |
| Tab structure | `style_row()` logic per provider |
| Refresh loop | `on_action()` handlers per provider |
| Keybindings | `refresh_interval()` per provider |

The TUI shell is ~120 lines. Each provider is ~30–50 lines. The entire framework
fits in a single afternoon of Python, and adding a new data source is a matter of
subclassing `BaseProvider` and implementing two methods.