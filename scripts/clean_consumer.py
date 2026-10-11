"""Test a separate consumer against an uncached Git snapshot, without publishing."""
from io import BytesIO
from pathlib import Path, PurePosixPath
import argparse
import json
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
TARGETS = ("native", "js", "wasm-gc")

CONSUMER_TESTS = r'''///|
test "consumer/direct message and private report" {
  let result = @edifact.parse(
    b"UNB+UNOA:3+S+R+261011:1200+I'UNH+1+ORDERS:D:96A:UN'BGM+220+PRIVATE'UNT+3+1'UNZ+1+I'",
  )
  assert_true(result.is_valid())
  assert_eq(result.rules, @edifact.NotChecked)
  assert_true(result.interchange is Some({ messages, .. }) && messages.length() == 1)
  assert_true(!@edifact.report_json(result).contains("PRIVATE"))
  assert_true(@edifact.report_json(result, show_values=true).contains("PRIVATE"))
}

///|
test "consumer/released component and raw byte span" {
  let result = @edifact.parse(
    b"UNB+UNOA:3+S+R+261011:1200+I'UNH+1+ORDERS:D:96A:UN'FTX+A?+B'UNT+3+1'UNZ+1+I'",
  )
  assert_true(result.is_valid())
  let doc = result.document.unwrap()
  let value = doc.segments[2].elements[0].components[0]
  assert_eq(value.value, b"A+B")
  assert_eq(value.span.end - value.span.start, 4)
}

///|
test "consumer/configurable budget and safe failure" {
  let limits = { ..@edifact.default_limits(), max_input_bytes: 4, }
  let result = @edifact.parse(b"UNB+UNOA:3'", limits~)
  assert_true(!result.is_valid())
  assert_true(result.document is None)
  assert_eq(result.diagnostics[0].code, "R_INPUT_BYTES")
  assert_eq(result.diagnostics[0].layer, @edifact.Resource)
}
'''


def run(arguments, cwd):
    result = subprocess.run(arguments, cwd=cwd, capture_output=True, text=True,
                            encoding="utf-8", errors="replace", timeout=180)
    if result.returncode:
        raise RuntimeError(f"{arguments!r}\n{result.stdout}\n{result.stderr}")
    return result.stdout


def prepare_snapshot(ref, prefix):
    revision = run(["git", "rev-parse", "--verify", ref + "^{commit}"], ROOT).strip()
    archive = subprocess.run(["git", "archive", "--format=zip", revision], cwd=ROOT,
                             capture_output=True, check=True, timeout=30).stdout
    build = (ROOT / "_build").resolve()
    build.mkdir(exist_ok=True)
    workspace = Path(tempfile.mkdtemp(prefix=prefix, dir=build)).resolve()
    assert workspace.is_relative_to(build)
    source = workspace / "source"
    source.mkdir()
    with zipfile.ZipFile(BytesIO(archive)) as snapshot:
        for entry in snapshot.infolist():
            path = PurePosixPath(entry.filename)
            destination = (source / path).resolve()
            assert not path.is_absolute() and destination.is_relative_to(source)
            assert "\\" not in entry.filename
            if entry.is_dir():
                destination.mkdir(parents=True, exist_ok=True)
            else:
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_bytes(snapshot.read(entry))
    assert not (source / "_build").exists(), "Source snapshot must have no build cache"
    return workspace, source, revision


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--ref", default="HEAD", help="Committed source to test")
    parser.add_argument("--target", choices=TARGETS, action="append")
    args = parser.parse_args()
    workspace, source, revision = prepare_snapshot(args.ref, "consumer-")
    consumer = workspace / "consumer"
    consumer.mkdir()
    (workspace / "moon.work").write_text('members = [ "./source", "./consumer" ]\n', encoding="utf-8")
    (consumer / "moon.mod").write_text(
        'name = "local/edifact_consumer"\nversion = "0.0.0"\n'
        'preferred_target = "native"\nimport { "ShiChengxu/MoonEdifact@0.1.0" }\n', encoding="utf-8")
    (consumer / "moon.pkg").write_text(
        'import { "ShiChengxu/MoonEdifact" @edifact, } for "test"\n'
        'supported_targets = "+native+js+wasm-gc"\n', encoding="utf-8")
    (consumer / "consumer_test.mbt").write_text(CONSUMER_TESTS, encoding="utf-8")
    targets = args.target or TARGETS
    for target in targets:
        run(["moon", "check", "--target", target, "--deny-warn", str(consumer)], workspace)
        output = run(["moon", "test", "--target", target, "--deny-warn", str(consumer)], workspace)
        assert "Total tests: 3, passed: 3, failed: 0" in output, output
        print(f"Clean consumer: {target}, 3 public API tests passed ({revision[:12]}).")
    (workspace / "result.json").write_text(json.dumps({
        "source_commit": revision, "targets": list(targets), "tests_per_target": 3,
        "dependency_source": "local Git archive; not a registry installation",
    }, indent=2) + "\n", encoding="utf-8")
    print(f"Evidence: {workspace / 'result.json'}")


if __name__ == "__main__":
    main()
