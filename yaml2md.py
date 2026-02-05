#!/usr/bin/env python3
import argparse
import re
import sys
from typing import Any, Dict, Iterable, List, Optional


STATUS_LABELS = {
    "cannot_reproduce": "Cannot reproduce",
    "not_filed_against_hdf5": "Not filed against HDF5",
    "not_applicable": "N/A",
}


def _load_yaml(path: str) -> Any:
    try:
        import yaml  # type: ignore
    except ImportError as exc:  # pragma: no cover - runtime dependency
        raise SystemExit(
            "PyYAML is required. Install with: pip install pyyaml"
        ) from exc

    with open(path, "r", encoding="utf-8") as handle:
        return yaml.safe_load(handle)


def _collapse_ws(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def _title_with_link(title: str, url: Optional[str]) -> str:
    if not url:
        return title
    marker = " from "
    if marker in title:
        prefix, suffix = title.split(marker, 1)
        return f"{prefix}{marker}[{suffix}]({url})"
    return f"[{title}]({url})"


def _format_fix_releases(fix_releases: Optional[Iterable[str]], status: Optional[str]) -> str:
    if fix_releases:
        return "/".join(str(item) for item in fix_releases)
    if status and status in STATUS_LABELS:
        return STATUS_LABELS[status]
    return "Cannot determine"


def _format_commit_hash(
    commit_hash: Optional[str],
    commit_url: Optional[str],
    status: Optional[str],
) -> str:
    if commit_hash:
        if commit_url:
            label = str(commit_hash)[:7]
            return f"[{label}]({commit_url})"
        return str(commit_hash)
    if status and status in STATUS_LABELS:
        return "N/A"
    return "Cannot determine"


def _format_issue_row(issue: Dict[str, Any]) -> str:
    issue_id = str(issue.get("id", "")).strip()
    url = issue.get("url")
    if issue_id and url:
        issue_cell = f"<span style=\"white-space:nowrap\">[{issue_id}]({url})</span>"
    else:
        issue_cell = issue_id or "Unknown"

    status = issue.get("status")
    fix_releases = issue.get("fix_releases")
    commit_hash = issue.get("commit_hash")
    commit_url = issue.get("commit_url")
    description = _collapse_ws(str(issue.get("description", ""))).replace("|", "\\|")

    fix_cell = _format_fix_releases(fix_releases, status)
    commit_cell = _format_commit_hash(commit_hash, commit_url, status)

    return f"|{issue_cell}|{fix_cell}|{commit_cell}|{description}|"


def _format_section(section: Dict[str, Any]) -> List[str]:
    title = str(section.get("title", "")).strip()
    url = section.get("url")
    issues = section.get("issues") or []

    lines: List[str] = []
    if title:
        lines.append(_title_with_link(title, url))
        lines.append("")

    lines.append("\n👉 **Commit Hash** links to the commit in the HDF5 GitHub repository.\n")
    lines.append("| CVE ID | Fixed in HDF5 vX.Y.Z | Commit Hash | Description")
    lines.append("|---------|--------|-------------|-------------|")

    for issue in issues:
        if not isinstance(issue, dict):
            continue
        lines.append(_format_issue_row(issue))

    return lines


def yaml_to_markdown(data: Any) -> str:
    if not isinstance(data, list):
        raise SystemExit("Expected top-level YAML list")

    sections: List[str] = []
    for section in data:
        if not isinstance(section, dict):
            continue
        section_lines = _format_section(section)
        sections.extend(section_lines)
        sections.append("")

    while sections and sections[-1] == "":
        sections.pop()

    return "\n".join(sections) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Convert CVE_list.yml to markdown table.")
    parser.add_argument(
        "input",
        nargs="?",
        default="CVE_list.yml",
        help="Path to YAML input (default: CVE_list.yml)",
    )
    parser.add_argument(
        "-o",
        "--output",
        help="Path to write markdown output (default: stdout)",
    )
    args = parser.parse_args()

    data = _load_yaml(args.input)
    markdown = yaml_to_markdown(data)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as handle:
            handle.write(markdown)
    else:
        sys.stdout.write(markdown)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
