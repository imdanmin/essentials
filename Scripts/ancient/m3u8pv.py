#!/home/dan/.local/env/misc/bin/python
"""
m3u8_space_command.py

Space Command — M3U8 downloader with ffmpeg (-c copy), concurrency, and a space/missions UI.

Usage:
    python m3u8_space_command.py urls.txt

Environment:
    M3U8_CONCURRENCY - optional override of concurrency count

Requirements:
    - ffmpeg installed and in PATH
    - ffprobe recommended (for duration/progress percentage)
"""

from __future__ import annotations
import os
import sys
import shutil
import subprocess
import threading
import concurrent.futures
import time
import uuid
from datetime import datetime, timezone
from typing import Optional, Dict

# ---------- Config ----------
UI_REFRESH_INTERVAL = 0.5
CONCURRENCY_CAP = 32
FFPROBE_TIMEOUT = 15

# ---------- Terminal color & emoji helpers ----------
CSI = "\x1b["
RESET = CSI + "0m"

# Basic colors
COLOR_RED = CSI + "31m"
COLOR_GREEN = CSI + "32m"
COLOR_YELLOW = CSI + "33m"
COLOR_BLUE = CSI + "34m"
COLOR_MAGENTA = CSI + "35m"
COLOR_CYAN = CSI + "36m"
COLOR_BOLD = CSI + "1m"

def enable_windows_ansi_support():
    """Attempt to enable ANSI escape sequences on Windows consoles (best-effort)."""
    if os.name != "nt":
        return
    try:
        import ctypes
        kernel32 = ctypes.windll.kernel32
        hStdOut = kernel32.GetStdHandle(-11)
        mode = ctypes.c_uint()
        if kernel32.GetConsoleMode(hStdOut, ctypes.byref(mode)):
            ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004
            new_mode = mode.value | ENABLE_VIRTUAL_TERMINAL_PROCESSING
            kernel32.SetConsoleMode(hStdOut, ctypes.c_uint(new_mode))
    except Exception:
        pass  # best-effort; if it fails proceed without exception

def colored(text: str, color: str) -> str:
    return f"{color}{text}{RESET}"

# Emojis (space-themed)
EMOJI_ROCKET = "🚀"
EMOJI_TELESCOPE = "🔭"
EMOJI_COMET = "☄️"
EMOJI_PLANET = "🪐"
EMOJI_EXPLOSION = "💥"
EMOJI_SATELLITE = "🛰️"
EMOJI_ALIEN = "👽"
EMOJI_STAR = "✨"
EMOJI_CONTROL = "🛸"
EMOJI_CHECK = "✅"
EMOJI_CROSS = "❌"

# ---------- Utility functions ----------
def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

def human_bytes(num: Optional[int]) -> str:
    if num is None:
        return "N/A"
    try:
        num = int(num)
    except Exception:
        return str(num)
    for unit in ("B","KB","MB","GB","TB"):
        if abs(num) < 1024.0:
            return f"{num:3.1f}{unit}"
        num /= 1024.0
    return f"{num:.1f}PB"

def parse_ffmpeg_time(ts: str) -> Optional[float]:
    if not ts:
        return None
    try:
        # support "hh:mm:ss[.ms]" or "mm:ss[.ms]" variants robustly
        parts = ts.split(":")
        parts = [p for p in parts]
        parts = [float(p) for p in parts]
        if len(parts) == 3:
            hrs, mins, sec = parts
        elif len(parts) == 2:
            hrs = 0.0
            mins, sec = parts
        else:
            return float(ts)
        return hrs * 3600.0 + mins * 60.0 + sec
    except Exception:
        return None

def safe_filename() -> str:
    now = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    uid = uuid.uuid4().hex
    return f"m3u8_{now}_{uid}.mp4"

def find_executable(name: str) -> Optional[str]:
    return shutil.which(name)

# ---------- ffprobe helpers ----------
def ffprobe_duration(url: str) -> Optional[float]:
    ffprobe = find_executable("ffprobe")
    if not ffprobe:
        return None
    cmd = [ffprobe, "-v", "error", "-show_entries", "format=duration",
           "-of", "default=noprint_wrappers=1:nokey=1", url]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=FFPROBE_TIMEOUT)
        if proc.returncode != 0:
            return None
        out = proc.stdout.strip()
        if not out:
            return None
        return float(out)
    except Exception:
        return None

def ffprobe_audio_codec_is_aac(url: str) -> bool:
    ffprobe = find_executable("ffprobe")
    if not ffprobe:
        return False
    cmd = [ffprobe, "-v", "error", "-select_streams", "a:0",
           "-show_entries", "stream=codec_name",
           "-of", "default=noprint_wrappers=1:nokey=1", url]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=FFPROBE_TIMEOUT)
        if proc.returncode != 0:
            return False
        codec = proc.stdout.strip().lower()
        return codec == "aac"
    except Exception:
        return False

# ---------- Download worker and status ----------
class DownloadStatus:
    def __init__(self, idx: int, url: str):
        self.idx = idx
        self.url = url
        self.outfile: Optional[str] = None
        self.state: str = "queued"  # queued, probing, downloading, done, failed, cancelled
        self.progress_seconds: Optional[float] = None
        self.duration_seconds: Optional[float] = None
        self.percent: Optional[float] = None
        self.size_bytes: Optional[int] = None
        self.speed_str: Optional[str] = None
        self.last_log: str = ""
        self.returncode: Optional[int] = None
        self.err_message: Optional[str] = None

    def brief_outfile(self, width=30):
        if not self.outfile:
            return "N/A"
        s = self.outfile
        if len(s) <= width:
            return s
        return "..." + s[-(width-3):]

statuses_lock = threading.Lock()
statuses: Dict[int, DownloadStatus] = {}
active_procs_lock = threading.Lock()
active_procs: Dict[int, subprocess.Popen] = {}

def run_download(idx: int, url: str):
    st = statuses[idx]
    try:
        st.state = "probing"
        st.last_log = f"{EMOJI_TELESCOPE} scanning target"
        dur = ffprobe_duration(url)
        st.duration_seconds = dur
        use_aac_bsf = ffprobe_audio_codec_is_aac(url)
    except Exception:
        st.duration_seconds = None
        use_aac_bsf = False

    outname = safe_filename()
    st.outfile = outname

    cmd = [
        "ffmpeg",
        "-y", "-hide_banner",
        "-loglevel", "warning",
        "-progress", "pipe:1",
        "-i", url,
        "-c", "copy"
    ]
    if use_aac_bsf:
        cmd += ["-bsf:a", "aac_adtstoasc"]
    cmd += [outname]

    st.state = "downloading"
    st.last_log = f"{EMOJI_COMET} initiating transfer"
    try:
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, bufsize=1, universal_newlines=True)
    except FileNotFoundError:
        st.state = "failed"
        st.err_message = "ffmpeg not found in PATH"
        st.returncode = -1
        return
    except Exception as e:
        st.state = "failed"
        st.err_message = f"failed to start ffmpeg: {e}"
        st.returncode = -1
        return

    with active_procs_lock:
        active_procs[idx] = proc

    stderr_lines = []
    try:
        stdout = proc.stdout
        stderr = proc.stderr

        def stderr_reader():
            try:
                for line in stderr:
                    line = line.rstrip("\n")
                    stderr_lines.append(line)
                    if len(stderr_lines) > 200:
                        stderr_lines.pop(0)
            except Exception:
                pass

        stderr_thread = threading.Thread(target=stderr_reader, daemon=True)
        stderr_thread.start()

        current = {}
        while True:
            line = stdout.readline()
            if line == "" and proc.poll() is not None:
                break
            if not line:
                time.sleep(0.05)
                continue
            line = line.strip()
            if not line:
                continue
            st.last_log = line
            if "=" in line:
                k, v = line.split("=", 1)
                current[k.strip()] = v.strip()
                if k == "out_time":
                    sec = parse_ffmpeg_time(v.strip())
                    st.progress_seconds = sec
                elif k == "out_time_ms":
                    try:
                        msm = float(v.strip())
                        if msm > 1e6:
                            sec = msm / 1e6
                        else:
                            sec = msm / 1000.0
                        st.progress_seconds = sec
                    except Exception:
                        pass
                elif k == "total_size":
                    try:
                        st.size_bytes = int(v.strip())
                    except Exception:
                        pass
                elif k == "speed":
                    st.speed_str = v.strip()
                elif k == "progress":
                    pass
            if st.progress_seconds is not None and st.duration_seconds:
                try:
                    pct = (st.progress_seconds / st.duration_seconds) * 100.0
                    st.percent = min(100.0, max(0.0, pct))
                except Exception:
                    st.percent = None

        proc.wait()
        stderr_thread.join(timeout=1.0)
        st.returncode = proc.returncode
        if proc.returncode == 0:
            st.state = "done"
            st.last_log = f"{EMOJI_PLANET} touchdown complete"
        else:
            st.state = "failed"
            st.err_message = "\n".join(stderr_lines[-30:]) if stderr_lines else f"ffmpeg exited with code {proc.returncode}"
    except Exception as e:
        try:
            proc.kill()
        except Exception:
            pass
        st.state = "failed"
        st.err_message = f"exception while running ffmpeg: {e}"
    finally:
        with active_procs_lock:
            active_procs.pop(idx, None)

# ---------- UI / monitor ----------
def state_icon_and_color(state: str):
    if state == "queued":
        return EMOJI_ROCKET, COLOR_YELLOW
    if state == "probing":
        return EMOJI_TELESCOPE, COLOR_CYAN
    if state == "downloading":
        return EMOJI_COMET, COLOR_BLUE
    if state == "done":
        return EMOJI_CHECK, COLOR_GREEN
    if state == "failed":
        return EMOJI_EXPLOSION, COLOR_RED
    if state == "cancelled":
        return EMOJI_CROSS, COLOR_MAGENTA
    return EMOJI_STAR, COLOR_MAGENTA

def monitor_loop(total_count: int, stop_event: threading.Event):
    spinner = "|/-\\"
    spin_idx = 0
    while not stop_event.is_set():
        lines = []
        header = f"{EMOJI_CONTROL} {COLOR_BOLD}Space Command — Mission Control{RESET} {EMOJI_STAR}"
        lines.append(header)
        lines.append(f"Mission clock: {datetime.now().astimezone().isoformat()}")
        lines.append("=".ljust(80, "="))
        with statuses_lock:
            items = sorted(statuses.items())
        active = sum(1 for _, s in items if s.state == "downloading")
        queued = sum(1 for _, s in items if s.state in ("queued", "probing"))
        done = sum(1 for _, s in items if s.state == "done")
        failed = sum(1 for _, s in items if s.state == "failed")
        lines.append(f"{EMOJI_SATELLITE} Active: {active}    {EMOJI_ROCKET} Queued: {queued}    {EMOJI_PLANET} Done: {done}    {EMOJI_EXPLOSION} Failed: {failed}")
        lines.append("-" * 80)
        for idx, st in items:
            icon, color = state_icon_and_color(st.state)
            percent_str = f"{st.percent:5.1f}%" if st.percent is not None else "  N/A "
            dur_str = f"{st.progress_seconds:.1f}s" if st.progress_seconds is not None else "N/A"
            size_str = human_bytes(st.size_bytes)
            speed = st.speed_str or ""
            outfile_brief = st.brief_outfile(34)
            left = f"[{idx+1:02d}] {icon} {st.state.upper():10s}"
            middle = f"{outfile_brief:34s} | {percent_str} | {dur_str:>7s} | {size_str:>8s} | {speed:>7s}"
            lines.append(f"{colored(left, color)}  {middle}")
            if st.state == "failed":
                err = st.err_message or st.last_log
                if err:
                    excerpt = err.strip().splitlines()[-2:]
                    for ln in excerpt:
                        lines.append(colored(f"       ERR: {ln}", COLOR_RED))
        lines.append("")
        lines.append(colored("Mission notes:", COLOR_BOLD))
        lines.append(" - This console uses ffmpeg -c copy to maximize network throughput and minimize CPU usage.")
        lines.append(" - Percent progress requires ffprobe to detect duration; live streams may show N/A.")
        lines.append(colored(" - Tip: set M3U8_CONCURRENCY env var to override concurrency (e.g. export M3U8_CONCURRENCY=8)", COLOR_YELLOW))
        lines.append(colored("Press Ctrl-C to abort mission (graceful termination will be attempted).", COLOR_MAGENTA))
        out = "\n".join(lines)
        # clear and print
        sys.stdout.write("\x1b[2J\x1b[H")
        sys.stdout.write(out + "\n")
        sys.stdout.flush()
        time.sleep(UI_REFRESH_INTERVAL)
        spin_idx = (spin_idx + 1) % len(spinner)
    # final summary
    try:
        sys.stdout.write("\x1b[2J\x1b[H")
        with statuses_lock:
            items = sorted(statuses.items())
        lines = [f"{EMOJI_CONTROL} Final Mission Debrief:"]
        for idx, st in items:
            icon, color = state_icon_and_color(st.state)
            base = f"[{idx+1:02d}] {icon} {st.state.upper():8s} {st.brief_outfile(60)}"
            lines.append(colored(base, color))
            if st.state == "done":
                lines.append(f"       -> stored: {st.outfile}")
            elif st.state == "failed":
                lines.append(colored(f"       -> ERROR: {st.err_message or st.last_log}", COLOR_RED))
        sys.stdout.write("\n".join(lines) + "\n")
        sys.stdout.flush()
    except Exception:
        pass

# ---------- Main ----------
def main():
    enable_windows_ansi_support()

    if len(sys.argv) != 2:
        eprint("Usage: python m3u8_space_command.py <urls_file>")
        sys.exit(2)
    urls_file = sys.argv[1]
    if not os.path.isfile(urls_file):
        eprint(f"File not found: {urls_file}")
        sys.exit(2)

    ffmpeg = find_executable("ffmpeg")
    ffprobe = find_executable("ffprobe")
    if not ffmpeg:
        eprint(colored("Error: ffmpeg not found in PATH. Install ffmpeg and ensure it's available in your PATH.", COLOR_RED))
        eprint("  On Debian/Ubuntu: sudo apt install ffmpeg")
        eprint("  On macOS (Homebrew): brew install ffmpeg")
        sys.exit(1)
    if not ffprobe:
        eprint(colored("Warning: ffprobe not found. Percent progress may be unavailable for some streams.", COLOR_YELLOW))

    with open(urls_file, "r", encoding="utf-8") as fh:
        raw_lines = [ln.strip() for ln in fh.readlines()]
    urls = []
    for ln in raw_lines:
        if not ln:
            continue
        if ln.lstrip().startswith("#"):
            continue
        urls.append(ln)
    if not urls:
        eprint(colored("No URLs found (after removing comments/blank lines).", COLOR_RED))
        sys.exit(1)

    total = len(urls)
    env_j = os.getenv("M3U8_CONCURRENCY")
    if env_j:
        try:
            concurrency = max(1, int(env_j))
        except Exception:
            concurrency = None
    else:
        cpu = os.cpu_count() or 1
        concurrency = min(CONCURRENCY_CAP, max(1, cpu * 2))
    concurrency = min(concurrency, total)

    eprint(colored(f"{EMOJI_CONTROL} Launching {total} mission target(s), concurrency = {concurrency}", COLOR_CYAN))
    eprint("")

    with statuses_lock:
        statuses.clear()
        for i, url in enumerate(urls):
            statuses[i] = DownloadStatus(i, url)

    stop_event = threading.Event()
    monitor_thread = threading.Thread(target=monitor_loop, args=(total, stop_event), daemon=True)
    monitor_thread.start()

    executor = concurrent.futures.ThreadPoolExecutor(max_workers=concurrency)
    futures = []
    try:
        for i, url in enumerate(urls):
            fut = executor.submit(run_download, i, url)
            futures.append(fut)
        for fut in concurrent.futures.as_completed(futures):
            try:
                fut.result()
            except Exception as e:
                eprint(colored("Worker exception: " + str(e), COLOR_RED))
    except KeyboardInterrupt:
        eprint(colored("\nAbort signal received — commanding all craft to stand down...", COLOR_MAGENTA))
        with active_procs_lock:
            for k, p in list(active_procs.items()):
                try:
                    p.terminate()
                except Exception:
                    try:
                        p.kill()
                    except Exception:
                        pass
        eprint("Sent terminate to ffmpeg processes. Waiting briefly...")
        time.sleep(1.0)
    finally:
        executor.shutdown(wait=False)
        stop_event.set()
        monitor_thread.join(timeout=2.0)

    successes = []
    failures = []
    with statuses_lock:
        for idx, st in statuses.items():
            if st.state == "done":
                successes.append(st)
            else:
                failures.append(st)

    eprint("")
    eprint(colored(f"{EMOJI_PLANET} Mission Summary:", COLOR_BOLD))
    eprint(colored(f"  succeeded: {len(successes)}", COLOR_GREEN))
    for s in successes:
        eprint(f"    - {s.outfile}")
    eprint(colored(f"  failed or incomplete: {len(failures)}", COLOR_RED if failures else COLOR_GREEN))
    for f in failures:
        eprint(colored(f"    - url: {f.url}", COLOR_YELLOW))
        eprint(colored(f"      state: {f.state}  error: {f.err_message or f.last_log}", COLOR_RED))

    if failures:
        sys.exit(2)
    else:
        sys.exit(0)

if __name__ == "__main__":
    main()
