"""Verify the locally generated Mooncakes archive; never uploads it."""
from pathlib import Path, PurePosixPath
import hashlib
import json
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    archive = ROOT / "_build/publish/ShiChengxu-MoonEdifact-0.1.0.zip"
    required = {
        "moon.mod", "moon.pkg", "pkg.generated.mbti", "api.mbt", "syntax.mbt",
        "lexer.mbt", "envelope.mbt", "report.mbt", "cmd/nativeio/io.c",
        "cmd/main/main.mbt", "LICENSE", "README.md", "THIRD_PARTY.md", "AI_USAGE.md",
        "CHANGELOG.md", "docs/SCOPE.md", "docs/SYNTAX_PROFILES.md", "docs/DIAGNOSTICS.md",
        "docs/SECURITY.md", "testdata/manifest.json",
    }
    forbidden = {".git", "_build", "target", ".agent-workplace", ".agents", ".codex", ".moon", "__pycache__"}
    with zipfile.ZipFile(archive) as package:
        names = set(package.namelist())
        assert required <= names, f"Missing package files: {sorted(required - names)}"
        for name in names:
            path = PurePosixPath(name)
            assert not path.is_absolute() and ".." not in path.parts and "\\" not in name
            assert not forbidden.intersection(path.parts), name
            assert path.name not in {"goal.md", "AGENTS.md"}, name
        assert package.read("LICENSE") == (ROOT / "LICENSE").read_bytes()
        manifest = json.loads(package.read("testdata/manifest.json"))
        for fixture in manifest["files"]:
            data = package.read("testdata/" + fixture["file"])
            assert hashlib.sha256(data).hexdigest() == fixture["sha256"], fixture["file"]
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    (archive.parent / "check-result.json").write_text(json.dumps({
        "archive": archive.name, "sha256": digest, "files": len(names),
        "fixture_hashes_verified": len(manifest["files"]), "uploaded": False,
    }, indent=2) + "\n", encoding="utf-8")
    print(f"Local package: {len(names)} files verified; SHA256={digest}")
    print("No upload performed; registry availability and installation remain unverified.")


if __name__ == "__main__":
    main()
