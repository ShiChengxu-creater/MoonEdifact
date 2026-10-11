"""Offline CLI acceptance checks. Uses only Python's standard library."""
from pathlib import Path
import argparse
import json
import subprocess

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--exe", type=Path)
    config = parser.parse_args()
    executable = config.exe or ROOT / "_build/native/debug/build/cmd/main/main.exe"
    executable = executable.resolve()
    assert executable.is_file(), "Build the native CLI first."
    checks = 0

    def run(arguments, expected):
        nonlocal checks
        result = subprocess.run([str(executable), *arguments], cwd=ROOT,
                                capture_output=True, text=True, encoding="utf-8", timeout=15)
        assert result.returncode == expected, (arguments, result.returncode, result.stdout, result.stderr)
        checks += 1
        return result

    assert "Usage:" in run(["--help"], 0).stdout
    assert "0.1.0" in run(["--version"], 0).stdout
    good = json.loads(run(["inspect", "testdata/minimal.edi", "--json"], 0).stdout)
    assert (good["syntax"], good["envelope"], good["rules"]) == ("passed", "passed", "not_checked")
    assert (good["message_count"], good["segment_count"]) == (1, 5)
    assert all("value" not in c for s in good["segments"] for e in s["elements"] for c in e["components"])
    assert "messages=1 segments=5" in run(["validate", "testdata/minimal.edi"], 0).stdout
    two = json.loads(run(["inspect", "testdata/custom-una-two.edi", "--json", "--show-values"], 0).stdout)
    assert two["message_count"] == 2 and two["segment_count"] == 8
    assert two["segments"][2]["elements"][0]["components"][0]["value"] == "A*B;C~D!E"
    bad = json.loads(run(["validate", "testdata/bad-count.edi", "--json"], 1).stdout)
    assert bad["diagnostics"][0]["code"] == "E_MESSAGE_COUNT"
    payload = (ROOT / "testdata/bad-count.edi").read_bytes()
    offset = payload.index(b"UNT+2") + 4
    assert bad["diagnostics"][0]["span"] == {"start": offset, "end": offset + 1}
    private = run(["inspect", "testdata/bad-reference.edi", "--json"], 1).stdout
    assert "E_MESSAGE_REFERENCE" in private and "DO-NOT-LEAK" not in private
    assert "I/O error" in run(["validate", "testdata/no-such-file.edi"], 2).stderr
    assert "Unknown option" in run(["inspect", "testdata/minimal.edi", "--unknown"], 2).stderr
    assert "I/O error" in run(["validate", "testdata"], 2).stderr
    limited = json.loads(run(["inspect", "testdata/minimal.edi", "--json", "--max-bytes", "12"], 1).stdout)
    assert limited["diagnostics"][0]["code"] == "R_INPUT_BYTES"

    scratch = ROOT / "_build/smoke"
    scratch.mkdir(parents=True, exist_ok=True)
    unicode_file = scratch / "数据 input.edi"
    unicode_file.write_bytes((ROOT / "testdata/minimal.edi").read_bytes())
    run(["validate", str(unicode_file)], 0)
    large = scratch / "multi-chunk.edi"
    content = b"UNB+UNOA:3+S+R+261011:1200+I'UNH+1+ORDERS:D:96A:UN'FTX+" + b"A" * 12000 + b"'UNT+3+1'UNZ+1+I'"
    large.write_bytes(content)
    run(["validate", str(large), "--max-bytes", str(len(content))], 0)
    run(["validate", str(large), "--max-bytes", str(len(content) - 1)], 1)
    truncated = scratch / "truncated.edi"
    truncated.write_bytes(b"UNB+UNOA:3+S'FTX+A?")
    failure = json.loads(run(["inspect", str(truncated), "--json"], 1).stdout)
    assert failure["diagnostics"][0]["code"] == "S_RELEASE_TRUNCATED"
    empty = scratch / "empty.edi"
    empty.write_bytes(b"")
    run(["validate", str(empty)], 1)
    print(f"CLI acceptance: {checks} end-to-end checks passed.")

if __name__ == "__main__":
    main()
