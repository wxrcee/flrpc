# Check README.md for setup instructions and details.

import time
import sys
import re
from datetime import datetime

try:
    import psutil
except ImportError:
    sys.exit("[ERROR] psutil not installed. Run: pip install psutil")

try:
    import win32gui
    import win32process
except ImportError:
    sys.exit("[ERROR] pywin32 not installed. Run: pip install pywin32")

try:
    from pypresence import Presence, exceptions as rpc_exc
except ImportError:
    sys.exit("[ERROR] pypresence not installed. Run: pip install pypresence")


# Config

CLIENT_ID   = "1234567890123456789"  # Replace with your Discord application's client ID
POLL_INTERVAL = 5
LARGE_IMAGE = "fl_logo"
LARGE_TEXT  = "FL Studio"
SMALL_IMAGE = "note"

# Don't change below unless you know what you're doing

FL_PROCESS_NAMES = {"fl64.exe", "fl.exe", "fruityloops.exe"}

def find_fl_window():
    result = []
    def _enum(hwnd, _):
        if not win32gui.IsWindowVisible(hwnd):
            return
        title = win32gui.GetWindowText(hwnd)
        if not title:
            return
        try:
            _, pid = win32process.GetWindowThreadProcessId(hwnd)
            proc = psutil.Process(pid)
            if proc.name().lower() in FL_PROCESS_NAMES:
                result.append((pid, hwnd, title))
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            pass
    win32gui.EnumWindows(_enum, None)
    return result[0] if result else None

def parse_window_title(title: str):
    unsaved = title.endswith("*")
    title_clean = title.rstrip("* ").strip()

    demo = False
    if title_clean.upper().startswith("[DEMO]"):
        demo = True
        title_clean = title_clean[6:].strip()

    m = re.match(r"(.+?)\s*-\s*FL Studio\s*([\d.]+)?$", title_clean, re.IGNORECASE)
    if m:
        project = m.group(1).strip()
        ver_num = m.group(2)
        version = f"FL Studio {ver_num}" if ver_num else "FL Studio"
        if demo:
            version += " [DEMO]"
        return (version, project, unsaved)

    m2 = re.match(r"FL Studio\s*([\d.]+)?$", title_clean, re.IGNORECASE)
    if m2:
        ver_num = m2.group(1)
        version = f"FL Studio {ver_num}" if ver_num else "FL Studio"
        if demo:
            version += " [DEMO]"
        return (version, None, unsaved)
 
    return ("FL Studio", None, unsaved)

def build_presence_kwargs(version, project, unsaved, start_ts):
    if project:
        details = f"Working on: {project}{'  ✏' if unsaved else ''}"
        state   = version
        kwargs  = dict(details=details, state=state, start=start_ts,
                       large_image=LARGE_IMAGE, large_text=LARGE_TEXT,
                       small_image=SMALL_IMAGE, small_text="Project loaded")
    else:
        kwargs  = dict(details=version, state="No project open", start=start_ts,
                       large_image=LARGE_IMAGE, large_text=LARGE_TEXT)
    return kwargs
 
def run_presence():
    rpc = Presence(CLIENT_ID)
    connected = False
    start_ts  = None
    last_title = None

    while True:
        fl = find_fl_window()

        if fl is None:
            if connected:
                try:
                    rpc.clear()
                    rpc.close()
                except Exception:
                    pass
            return

        pid, hwnd, title = fl

        if not connected:
            try:
                rpc.connect()
                connected = True
                start_ts  = int(datetime.now().timestamp())
            except rpc_exc.DiscordNotFound:
                time.sleep(POLL_INTERVAL)
                continue
            except Exception:
                time.sleep(POLL_INTERVAL)
                continue

        if title != last_title:
            version, project, unsaved = parse_window_title(title)
            kwargs = build_presence_kwargs(version, project, unsaved, start_ts)
            try:
                rpc.update(**kwargs)
                last_title = title
            except Exception:
                connected = False
 
        time.sleep(POLL_INTERVAL)

def main():
    if CLIENT_ID == "YOUR_CLIENT_ID_HERE":
        sys.exit("[ERROR] Set your CLIENT_ID in fl_rpc.py")

    while True:
        while not find_fl_window():
            time.sleep(POLL_INTERVAL)
 
        run_presence()
 
        time.sleep(POLL_INTERVAL)

if __name__ == "__main__":
    main()
