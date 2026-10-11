"""Replay acceptance from a new local Git archive, with no inherited build cache."""
import argparse
import json
import re
import sys

from clean_consumer import TARGETS, prepare_snapshot, run


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--ref", default="HEAD")
    parser.add_argument("--target", choices=TARGETS, action="append")
    args = parser.parse_args()
    workspace, source, revision = prepare_snapshot(args.ref, "source-", isolated=True)
    interfaces = {path.relative_to(source).as_posix(): path.read_bytes()
                  for path in source.rglob("*.mbti")}
    run(["moon", "info"], source)
    updated = {path.relative_to(source).as_posix(): path.read_bytes()
               for path in source.rglob("*.mbti") if "_build" not in path.relative_to(source).parts}
    assert interfaces == updated, "Generated public interfaces drift from the committed snapshot"
    run(["moon", "fmt", "--check"], source)
    run([sys.executable, "scripts/repository_checks.py"], source)
    evidence = {"source_commit": revision, "source_directory": str(source),
                "tests": {}, "examples": {}, "cli": "not_run"}
    for target in args.target or TARGETS:
        run(["moon", "check", "--target", target, "--deny-warn"], source)
        run(["moon", "build", "--target", target, "--deny-warn"], source)
        output = run(["moon", "test", "--target", target, "--deny-warn"], source)
        summary = re.search(r"Total tests: (\d+), passed: (\d+), failed: (\d+)", output)
        assert summary and int(summary[1]) >= 60 and summary[1] == summary[2] and summary[3] == "0", output
        evidence["tests"][target] = int(summary[1])
        run([sys.executable, "scripts/examples_smoke.py", "--target", target], source)
        evidence["examples"][target] = 5 if target == "native" else 4
        if target == "native":
            cli = run([sys.executable, "scripts/cli_smoke.py"], source)
            assert "21 end-to-end checks passed" in cli, cli
            evidence["cli"] = "21 end-to-end checks passed"
        print(f"Clean source: {target}, {summary[1]} tests and documented examples passed.")
    run(["moon", "package"], source)
    package_output = run([sys.executable, "scripts/package_checks.py"], source)
    evidence["package"] = package_output.splitlines()[0]
    (workspace / "result.json").write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
    print(f"Clean source: interfaces and local package verified ({revision[:12]}).")
    print(f"Evidence: {workspace / 'result.json'}")


if __name__ == "__main__":
    main()
