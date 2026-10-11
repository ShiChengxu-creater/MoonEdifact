"""Offline fixture, source inventory and targeted credential checks."""
from pathlib import Path
import hashlib
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def main():
    paths = subprocess.run(["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
                           cwd=ROOT, capture_output=True, check=True).stdout.decode("utf-8").split("\0")
    paths = sorted(set(path for path in paths if path and (ROOT / path).is_file()))
    # This is a deliberately narrow check, not a full security audit.
    patterns = (
        re.compile(r"-----BEGIN (?:RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----"),
        re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
        re.compile(r"\bgh[pousr]_[A-Za-z0-9]{30,}\b"),
        re.compile(r"\bxox[baprs]-[A-Za-z0-9-]{20,}\b"),
    )
    counts = {}
    invalid_core = 0
    codes = set()
    for path in paths:
        content = (ROOT / path).read_text(encoding="utf-8", errors="replace")
        for pattern in patterns:
            assert not pattern.search(content), f"Possible credential in {path}; inspect locally"
        if path.endswith(".mbt"):
            names = re.findall(r'^test "([^"]+)"', content, re.MULTILINE)
            counts[path] = len(names)
            if "/" not in path:
                invalid_core += sum(name.startswith("invalid/") for name in names)
            if not path.endswith(("_test.mbt", "_wbtest.mbt")):
                codes.update(re.findall(r'"([SER]_[A-Z_]+)"', content))
    assert sum(counts.values()) >= 60, counts
    assert invalid_core >= 20, invalid_core
    manifest = json.loads((ROOT / "testdata/manifest.json").read_text(encoding="utf-8"))
    for entry in manifest["files"]:
        path = ROOT / "testdata" / entry["file"]
        assert path.resolve().is_relative_to((ROOT / "testdata").resolve())
        assert hashlib.sha256(path.read_bytes()).hexdigest() == entry["sha256"], path.name
    assert "Apache License" in (ROOT / "LICENSE").read_text(encoding="utf-8")
    diagnostics = ROOT / "docs/DIAGNOSTICS.md"
    if diagnostics.exists():
        documented = set(re.findall(r"\b[SER]_[A-Z_]+\b", diagnostics.read_text(encoding="utf-8")))
        assert codes <= documented, f"Undocumented diagnostic codes: {sorted(codes - documented)}"
    print(f"Repository: {sum(counts.values())} tests, {invalid_core} malformed core tests, "
          f"{len(manifest['files'])} fixture hashes, targeted credential scan passed.")


if __name__ == "__main__":
    main()
