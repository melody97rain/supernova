#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
ps_mem (stabilized for Debian 12/13, prefer smaps_rollup)

Perubahan:
- Guna Python 3 sahaja.
- `smaps_rollup` diaktifkan sebagai lalai (lebih pantas/tepat).
- Jatuh-balik automatik ke smaps/statm jika rollup tak ada.
- Opsyen `--no-rollup` untuk mematikan penggunaan rollup.
- Tidak tutup stdout/stderr secara manual; lebih selamat bila dipipe.
"""

import getopt
import time
import errno
import os
import sys

def std_exceptions(etype, value, tb):
    sys.excepthook = sys.__excepthook__
    if issubclass(etype, KeyboardInterrupt):
        return
    if issubclass(etype, BrokenPipeError) or (
        issubclass(etype, IOError) and getattr(value, "errno", None) == errno.EPIPE
    ):
        return
    sys.__excepthook__(etype, value, tb)

sys.excepthook = std_exceptions

PAGESIZE = int(os.sysconf("SC_PAGE_SIZE") // 1024)  # KiB
our_pid = os.getpid()

have_pss = 0
have_swap_pss = 0
USE_SMAPS_ROLLUP = True  # boleh dimatikan dengan --no-rollup

class Proc:
    def __init__(self):
        uname = os.uname()
        self.proc = "/compat/linux/proc" if uname[0] == "FreeBSD" else "/proc"

    def path(self, *args):
        return os.path.join(self.proc, *(str(a) for a in args))

    def open(self, *args):
        try:
            return open(self.path(*args), encoding="utf-8", errors="ignore")
        except (IOError, OSError) as e:
            if getattr(e, "errno", None) in (errno.ENOENT, errno.EPERM, errno.EACCES):
                raise LookupError
            raise

proc = Proc()

def parse_options():
    try:
        long_options = [
            "split-args",
            "help",
            "total",
            "discriminate-by-pid",
            "swap",
            "no-rollup",
        ]
        opts, args = getopt.getopt(sys.argv[1:], "shtdSp:w:", long_options)
    except getopt.GetoptError:
        sys.stderr.write(help())
        sys.exit(3)

    if len(args):
        sys.stderr.write("Argumen berlebihan: %s\n" % args)
        sys.exit(3)

    split_args = False
    pids_to_show = None
    discriminate_by_pid = False
    show_swap = False
    watch = None
    only_total = False
    use_rollup = True

    for o, a in opts:
        if o in ("-s", "--split-args"):
            split_args = True
        elif o in ("-t", "--total"):
            only_total = True
        elif o in ("-d", "--discriminate-by-pid"):
            discriminate_by_pid = True
        elif o in ("-S", "--swap"):
            show_swap = True
        elif o in ("-h", "--help"):
            sys.stdout.write(help())
            sys.exit(0)
        elif o == "-p":
            try:
                pids_to_show = [int(x) for x in a.split(",") if x.strip()]
            except Exception:
                sys.stderr.write(help())
                sys.exit(3)
        elif o == "-w":
            try:
                watch = int(a)
            except Exception:
                sys.stderr.write(help())
                sys.exit(3)
        elif o == "--no-rollup":
            use_rollup = False

    return (
        split_args,
        pids_to_show,
        watch,
        only_total,
        discriminate_by_pid,
        show_swap,
        use_rollup,
    )

def help():
    return (
        "Usage: ps_mem [OPTION]...\n"
        "Tunjuk penggunaan memori teras mengikut program\n\n"
        "  -h, --help                  Papar bantuan ini\n"
        "  -p <pid>[,pid2,...pidN]     Hanya tunjuk PIDs tersenarai\n"
        "  -s, --split-args            Kumpul ikut keseluruhan argumen CLI\n"
        "  -t, --total                 Tunjuk jumlah sahaja (perlukan PSS)\n"
        "  -d, --discriminate-by-pid   Bezakan setiap proses [pid]\n"
        "  -S, --swap                  Tunjuk maklumat swap\n"
        "  -w <N>                      Ulang ukur setiap N saat\n"
        "      --no-rollup             Jangan guna /proc/<pid>/smaps_rollup\n"
    )

def kernel_ver():
    try:
        kv = proc.open("sys/kernel/osrelease").readline().strip()
    except LookupError:
        kv = os.uname().release
    parts = kv.split(".")[:3]
    while len(parts) < 3:
        parts.append("0")
    cleaned = []
    for seg in parts:
        for ch in "-_":
            seg = seg.split(ch)[0]
        try:
            cleaned.append(int(seg))
        except Exception:
            cleaned.append(0)
    return tuple(cleaned[:3])

# ====== UTIL PARSER ======
def _sum_kb(lines):
    total = 0
    for l in lines:
        parts = l.split()
        if len(parts) >= 2 and parts[1].isdigit():
            total += int(parts[1])
    return total

# return Private(KiB), Shared(KiB), mem_id, Swap(KiB), SwapPss(KiB)
def getMemStats(pid):
    global have_pss, have_swap_pss

    # RSS fallback (KiB)
    try:
        Rss = int(proc.open(pid, "statm").readline().split()[1]) * PAGESIZE
    except LookupError:
        raise RuntimeError

    # 1) cuba smaps_rollup (lebih pantas & tepat)
    smaps_rollup = proc.path(pid, "smaps_rollup")
    if USE_SMAPS_ROLLUP and os.path.exists(smaps_rollup):
        try:
            content = proc.open(pid, "smaps_rollup").read().splitlines()
        except LookupError:
            raise RuntimeError

        # mem_id guna hash kandungan rollup (konsisten untuk CLONE_VM)
        mem_id = hash("\n".join(content))

        fields = {
            "Private_Clean:": 0,
            "Private_Dirty:": 0,
            "Shared_Clean:": 0,
            "Shared_Dirty:": 0,
            "Pss:": 0.0,
            "Swap:": 0,
            "SwapPss:": 0,
        }

        for line in content:
            parts = line.split()
            if not parts:
                continue
            key = parts[0]
            if key in ("Private_Clean:", "Private_Dirty:", "Shared_Clean:", "Shared_Dirty:", "Swap:", "SwapPss:"):
                if len(parts) >= 2 and parts[1].isdigit():
                    fields[key] += int(parts[1])
            elif key == "Pss:" and len(parts) >= 2:
                try:
                    fields["Pss:"] += float(parts[1]) + 0.5  # pembetulan truncation kecil
                    have_pss = 1
                except ValueError:
                    pass

        private = fields["Private_Clean:"] + fields["Private_Dirty:"]
        # Shared berdasarkan PSS - Private (proportional)
        shared = max(0.0, fields["Pss:"] - private)
        swap = fields["Swap:"]
        if fields["SwapPss:"] > 0:
            have_swap_pss = 1
        swap_pss = fields["SwapPss:"]

        return (private, shared, mem_id, swap, swap_pss)

    # 2) fallback ke smaps biasa
    smaps = proc.path(pid, "smaps")
    if os.path.exists(smaps):
        try:
            lines = proc.open(pid, "smaps").read().splitlines()
        except LookupError:
            raise RuntimeError

        mem_id = hash("\n".join(lines))
        Private_lines = []
        Shared_lines = []
        Pss_lines = []
        Swap_lines = []
        Swap_pss_lines = []

        for line in lines:
            if line.startswith("Shared"):
                Shared_lines.append(line)
            elif line.startswith("Private"):
                Private_lines.append(line)
            elif line.startswith("Pss:"):
                have_pss = 1
                Pss_lines.append(line)
            elif line.startswith("Swap:"):
                Swap_lines.append(line)
            elif line.startswith("SwapPss:"):
                have_swap_pss = 1
                Swap_pss_lines.append(line)

        shared = _sum_kb(Shared_lines)
        private = _sum_kb(Private_lines)

        if have_pss:
            pss_adjust = 0.5
            Pss = 0.0
            for l in Pss_lines:
                parts = l.split()
                if len(parts) >= 2:
                    try:
                        Pss += float(parts[1]) + pss_adjust
                    except ValueError:
                        pass
            shared = max(0.0, Pss - private)

        swap = _sum_kb(Swap_lines)
        swap_pss = _sum_kb(Swap_pss_lines)
        return (private, shared, mem_id, swap, swap_pss)

    # 3) kernel lama: gunakan statm (kurang tepat)
    kv = kernel_ver()
    if (2, 6, 1) <= kv <= (2, 6, 9):
        shared = 0
        private = Rss
    else:
        try:
            shared = int(proc.open(pid, "statm").readline().split()[2]) * PAGESIZE
        except LookupError:
            raise RuntimeError
        private = max(0, Rss - shared)

    return (private, shared, pid, 0, 0)

def getCmdName(pid, split_args, discriminate_by_pid):
    try:
        cmdline = proc.open(pid, "cmdline").read().split("\0")
    except LookupError:
        raise LookupError
    if cmdline and cmdline[-1] == "":
        cmdline = cmdline[:-1]

    path = proc.path(pid, "exe")
    try:
        path = os.readlink(path).split("\0")[0]
    except OSError as e:
        if getattr(e, "errno", None) in (errno.ENOENT, errno.EPERM, errno.EACCES):
            raise LookupError
        raise

    if split_args:
        base = " ".join(cmdline) if cmdline else os.path.basename(path)
    else:
        if path.endswith(" (deleted)"):
            base_path = path[:-10]
            if os.path.exists(base_path):
                path = base_path + " [updated]"
            elif cmdline and os.path.exists(cmdline[0]):
                path = cmdline[0] + " [updated]"
            else:
                path = base_path + " [deleted]"
        exe = os.path.basename(path)
        try:
            first = proc.open(pid, "status").readline()
            name_field = first.split(":", 1)[-1].strip() if ":" in first else first.strip()
            cmd = exe if exe.startswith(name_field) else name_field
        except LookupError:
            cmd = exe
        base = cmd

    if discriminate_by_pid:
        base = f"{base} [{pid}]"
    return base

def human(num, power="Ki", units=None):
    if units is None:
        powers = ["Ki", "Mi", "Gi", "Ti", "Pi"]
        n = float(num)
        i = 0
        while n >= 1000.0 and i < len(powers) - 1:
            n /= 1024.0
            i += 1
        return f"{n:.1f} {powers[i]}B"
    else:
        return f"{(num * 1024) // units:.0f}"

def cmd_with_count(cmd, count):
    return f"{cmd} ({count})" if count > 1 else cmd

def shared_val_accuracy():
    kv = kernel_ver()
    pid = os.getpid()
    if kv[:2] == (2, 4):
        try:
            mi = proc.open("meminfo").read()
            return 1 if "Inact_" not in mi else 0
        except LookupError:
            return 1
    elif kv[:2] == (2, 6):
        if os.path.exists(proc.path(pid, "smaps")):
            try:
                sm = proc.open(pid, "smaps").read()
                return 2 if "Pss:" in sm else 1
            except LookupError:
                return 1
        if (2, 6, 1) <= kv <= (2, 6, 9):
            return -1
        return 0
    elif kv[0] > 2 and (
        os.path.exists(proc.path(pid, "smaps")) or os.path.exists(proc.path(pid, "smaps_rollup"))
    ):
        return 2
    else:
        return 1

def show_shared_val_accuracy(possible_inacc, only_total=False):
    level = ("Amaran", "Ralat")[only_total]
    if possible_inacc == -1:
        sys.stderr.write(f"{level}: Sistem ini tidak melaporkan memori berkongsi.\n")
        sys.stderr.write("Nilai akan terlebih besar; jumlah tidak dipaparkan.\n")
    elif possible_inacc == 0:
        sys.stderr.write(f"{level}: Laporan memori berkongsi tidak tepat pada sistem ini.\n")
        sys.stderr.write("Nilai mungkin terlebih besar; jumlah tidak dipaparkan.\n")
    elif possible_inacc == 1:
        sys.stderr.write(f"{level}: Memori berkongsi sedikit terlebih kira per program; jumlah tidak dipaparkan.\n")

def get_memory_usage(pids_to_show, split_args, discriminate_by_pid, include_self=False, only_self=False):
    cmds = {}
    shareds = {}
    mem_ids = {}
    count = {}
    swaps = {}
    shared_swaps = {}

    for entry in os.listdir(proc.path("")):
        if not entry.isdigit():
            continue
        pid = int(entry)

        if only_self and pid != our_pid:
            continue
        if pid == our_pid and not include_self:
            continue
        if pids_to_show is not None and pid not in pids_to_show:
            continue

        try:
            cmd = getCmdName(pid, split_args, discriminate_by_pid)
        except LookupError:
            continue

        try:
            private, shared, mem_id, swap, swap_pss = getMemStats(pid)
        except RuntimeError:
            continue

        if cmd in shareds:
            if have_pss:
                shareds[cmd] += shared
            else:
                shareds[cmd] = max(shareds[cmd], shared)
        else:
            shareds[cmd] = shared

        cmds[cmd] = cmds.get(cmd, 0) + private
        count[cmd] = count.get(cmd, 0) + 1
        mem_ids.setdefault(cmd, {})[mem_id] = None

        swaps[cmd] = swaps.get(cmd, 0) + swap
        if have_swap_pss:
            shared_swaps[cmd] = shared_swaps.get(cmd, 0) + swap_pss
        else:
            shared_swaps[cmd] = 0

    total = 0
    total_swap = 0
    total_shared_swap = 0

    for cmd in list(cmds.keys()):
        cmd_count = count[cmd]
        if len(mem_ids[cmd]) == 1 and cmd_count > 1:
            cmds[cmd] //= cmd_count
            if have_pss:
                shareds[cmd] //= cmd_count
        cmds[cmd] = cmds[cmd] + shareds[cmd]
        total += cmds[cmd]
        total_swap += swaps[cmd]
        if have_swap_pss:
            total_shared_swap += shared_swaps[cmd]

    sorted_cmds = sorted(cmds.items(), key=lambda x: x[1])
    sorted_cmds = [x for x in sorted_cmds if x[1]]

    return (
        sorted_cmds,
        shareds,
        count,
        total,
        swaps,
        shared_swaps,
        total_swap,
        total_shared_swap,
    )

def print_header(show_swap, discriminate_by_pid):
    out = "   Private  +     Shared  =    RAM digunakan"
    if show_swap:
        if have_swap_pss:
            out += " " * 5 + "Shared Swap"
        out += "   Swap digunakan"
    out += "\tProgram"
    if discriminate_by_pid:
        out += "[pid]"
    out += "\n\n"
    sys.stdout.write(out)

def print_memory_usage(
    sorted_cmds, shareds, count, total, swaps, total_swap, shared_swaps, total_shared_swap, show_swap
):
    for cmd in sorted_cmds:
        prog = cmd[0]
        line = "%10s + %10s = %10s"
        data = (human(cmd[1] - shareds[prog]), human(shareds[prog]), human(cmd[1]))
        if show_swap:
            if have_swap_pss:
                line += "\t%10s"
                data += (human(shared_swaps[prog]),)
            line += "   %10s"
            data += (human(swaps[prog]),)
        line += "\t%s\n"
        data += (cmd_with_count(prog, count[prog]),)
        sys.stdout.write(line % data)

    if have_pss:
        if show_swap:
            if have_swap_pss:
                sys.stdout.write(
                    "%s\n%s%10s%s%10s%s%10s\n%s\n"
                    % ("-" * 66, " " * 28, human(total), " " * 6, human(total_shared_swap), " " * 3, human(total_swap), "=" * 66)
                )
            else:
                sys.stdout.write(
                    "%s\n%s%10s%s%10s\n%s\n" % ("-" * 50, " " * 28, human(total), " " * 3, human(total_swap), "=" * 50)
                )
        else:
            sys.stdout.write("%s\n%s%10s\n%s\n" % ("-" * 38, " " * 28, human(total), "=" * 38))

def verify_environment(only_total):
    if os.geteuid() != 0:
        sys.stderr.write(
            "Amaran: tidak berjalan sebagai root. Keputusan terhad kepada proses yang boleh diakses dan mungkin kurang tepat.\n"
        )
        if only_total:
            sys.stderr.write("Petua: --total lebih tepat jika dijalankan sebagai root (PSS penuh).\n")
    try:
        kernel_ver()
    except Exception:
        sys.stderr.write(
            "Tidak dapat akses %s\nHanya GNU/Linux dan FreeBSD (linprocfs) disokong\n" % proc.path("")
        )
        sys.exit(2)

def main():
    global USE_SMAPS_ROLLUP
    (
        split_args,
        pids_to_show,
        watch,
        only_total,
        discriminate_by_pid,
        show_swap,
        use_rollup,
    ) = parse_options()
    USE_SMAPS_ROLLUP = bool(use_rollup)

    verify_environment(only_total)

    if not only_total:
        print_header(show_swap, discriminate_by_pid)

    def run_once():
        return get_memory_usage(pids_to_show, split_args, discriminate_by_pid)

    if watch is not None:
        try:
            while True:
                (
                    sorted_cmds,
                    shareds,
                    count,
                    total,
                    swaps,
                    shared_swaps,
                    total_swap,
                    total_shared_swap,
                ) = run_once()

                if only_total and have_pss:
                    sys.stdout.write(human(total, units=1) + "\n")
                elif not only_total:
                    print_memory_usage(
                        sorted_cmds,
                        shareds,
                        count,
                        total,
                        swaps,
                        total_swap,
                        shared_swaps,
                        total_shared_swap,
                        show_swap,
                    )
                sys.stdout.flush()
                time.sleep(watch)
        except KeyboardInterrupt:
            pass
    else:
        (
            sorted_cmds,
            shareds,
            count,
            total,
            swaps,
            shared_swaps,
            total_swap,
            total_shared_swap,
        ) = run_once()
        if only_total and have_pss:
            sys.stdout.write(human(total, units=1) + "\n")
        elif not only_total:
            print_memory_usage(
                sorted_cmds,
                shareds,
                count,
                total,
                swaps,
                total_swap,
                shared_swaps,
                total_shared_swap,
                show_swap,
            )

    vm_accuracy = shared_val_accuracy()
    show_shared_val_accuracy(vm_accuracy, only_total)

if __name__ == "__main__":
    main()
