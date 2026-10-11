"""Run the five documented MoonBit examples and verify meaningful outputs."""
from pathlib import Path
import argparse
import json
import subprocess

ROOT = Path(__file__).resolve().parents[1]
EXAMPLES = ("parse_minimal", "custom_una_multi_message", "released_separator",
            "diagnose_bad_envelope", "cli_inspect_validate")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--target", default="native", choices=("native", "js", "wasm-gc"))
    args = parser.parse_args()
    names = EXAMPLES if args.target == "native" else EXAMPLES[:4]
    for name in names:
        result = subprocess.run(["moon", "run", "--target", args.target, f"examples/{name}"],
                                cwd=ROOT, capture_output=True, text=True, encoding="utf-8", timeout=90)
        assert result.returncode == 0, (name, result.stdout, result.stderr)
        text = result.stdout
        if name == "parse_minimal":
            assert "messages=1 segments=5" in text and "first_tag=UNB" in text
        elif name == "custom_una_multi_message":
            assert "messages=2 segments=8" in text and "message_segments=5..7" in text
        elif name == "released_separator":
            assert "A+B:C'D?E" in text and "logical_bytes=9" in text
        elif name == "diagnose_bad_envelope":
            assert "E_MESSAGE_COUNT" in text and "E_MESSAGE_REFERENCE" in text and "valid=false" in text
        else:
            lines = text.splitlines()
            report = json.loads(next(line[8:] for line in lines if line.startswith("inspect=")))
            assert report["message_count"] == 1 and report["envelope"] == "passed"
            assert "exit=0" in lines
        print(f"{args.target}: {name} passed")

if __name__ == "__main__":
    main()
