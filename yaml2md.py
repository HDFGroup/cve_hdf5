#!/usr/bin/env python3
import argparse
import re
import sys
import urllib.error
import urllib.request
from typing import Any, Dict, Iterable, List, Optional, Set


STATUS_LABELS = {
    "cannot_reproduce": "Cannot reproduce",
    "not_filed_against_hdf5": "Not filed against HDF5",
    "not_applicable": "N/A",
}
REQUIRED_FIELDS: Set[str] = {"cve_id", "version_fixed", "commit_hash", "description"}


def _validate_issue_fields(
    issue: Dict[str, Any],
    section_title: str,
    idx: int,
    check_links: bool = False,
) -> None:
    """Validate required issue fields for the expected YAML schema.

    Expected issue mapping keys:
    - id (CVE identifier string)
    - fix_releases (list of versions or status text)
    - commit_hash (40-char lowercase hex or "N/A")
    - description (non-empty string)
    - url (optional CVE record URL)
    """
    missing = []
    if not issue.get("id"):
        missing.append("cve_id")
    fix_releases = issue.get("fix_releases")
    if not fix_releases:
        missing.append("version_fixed")
    if "commit_hash" not in issue:
        missing.append("commit_hash")
    description = issue.get("description")
    if not description:
        missing.append("description")

    if missing:
        fields = ", ".join(sorted(missing))
        print(
            f"Invalid YAML: section '{section_title or 'Unknown'}' issue #{idx} "
            f"is missing required field(s): {fields}",
            file=sys.stderr,
        )

    commit_hash = issue.get("commit_hash")
    if commit_hash is None or commit_hash == "":
        print(
            f"\nInvalid YAML: section '{section_title or 'Unknown'}' issue #{idx} "
            "commit_hash must be a 40-char lowercase hex string",
            file=sys.stderr,
        )
        print(issue, file=sys.stderr)
    if isinstance(commit_hash, str) and commit_hash != "N/A":
        if not _validate_commit_hash(commit_hash):
            print(
                f"\nInvalid YAML: section '{section_title or 'Unknown'}' issue #{idx} "
                f"commit_hash '{commit_hash}' must be a 40-char lowercase hex string",
                file=sys.stderr,
            )
            print(issue, file=sys.stderr)
    elif not isinstance(commit_hash, str):
        print(
            f"\nInvalid YAML: section '{section_title or 'Unknown'}' issue #{idx} "
            "commit_hash must be a string",
            file=sys.stderr,
        )
        print(issue, file=sys.stderr)

    issue_id = str(issue.get("id", "")).strip()
    url = issue.get("url")
    if url:
        if not isinstance(url, str):
            print(
                f"\nInvalid YAML: section '{section_title or 'Unknown'}' issue #{idx} "
                "url must be a string",
                file=sys.stderr,
            )
            print(issue, file=sys.stderr)
        else:
            url = url.strip()
            if not _is_cve_url(url):
                print(
                    f"\nInvalid YAML: section '{section_title or 'Unknown'}' issue #{idx} "
                    f"url '{url}' is not a valid CVE record link",
                    file=sys.stderr,
                )
                print(issue, file=sys.stderr)
            elif issue_id and not url.endswith(f"id={issue_id}"):
                print(
                    f"\nInvalid YAML: section '{section_title or 'Unknown'}' issue #{idx} "
                    f"url '{url}' does not match id '{issue_id}'",
                    file=sys.stderr,
                )
                print(issue, file=sys.stderr)
            if check_links and _is_cve_url(url) and issue_id:
                if not _check_url(url):
                    print(
                        f"\nInvalid YAML: section '{section_title or 'Unknown'}' issue #{idx} "
                        f"url '{url}' is not reachable",
                        file=sys.stderr,
                    )
                    print(issue, file=sys.stderr)


def _validate_yaml_schema(data: Any, check_links: bool = False) -> None:
    """Validate the expected YAML schema for CVE list input.

    Expected structure:
    - Top-level list of sections (mappings).
    - Each section may include: title, url, issues.
    - issues must be a list of issue mappings (see _validate_issue_fields).
    - when enabled, CVE URLs are checked for format and reachability.
    """
    if not isinstance(data, list):
        print("Invalid YAML: expected top-level list", file=sys.stderr)
        return

    for section_idx, section in enumerate(data, start=1):
        if not isinstance(section, dict):
            print(
                f"Invalid YAML: section #{section_idx} must be a mapping",
                file=sys.stderr,
            )
            continue
        issues = section.get("issues") or []
        if not isinstance(issues, list):
            print(
                f"Invalid YAML: section '{section.get('title', '')}' issues must be a list",
                file=sys.stderr,
            )
            continue
        for issue_idx, issue in enumerate(issues, start=1):
            if not isinstance(issue, dict):
                print(
                    f"Invalid YAML: section '{section.get('title', '')}' issue #{issue_idx} "
                    "must be a mapping",
                    file=sys.stderr,
                )
                continue
            _validate_issue_fields(
                issue,
                str(section.get("title", "")),
                issue_idx,
                check_links=check_links,
            )


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


def _validate_commit_hash(hash_str: str) -> bool:
    return bool(re.match(r"^[0-9a-f]{40}$", hash_str))


def _is_cve_url(url: str) -> bool:
    return bool(re.match(r"^https://www\.cve\.org/CVERecord\?id=CVE-\d{4}-\d+$", url))


def _check_url(url: str) -> bool:
    request = urllib.request.Request(url, method="HEAD")
    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            return 200 <= response.status < 400
    except urllib.error.HTTPError as exc:
        if exc.code in {405, 501}:
            try:
                with urllib.request.urlopen(url, timeout=10) as response:
                    return 200 <= response.status < 400
            except urllib.error.URLError:
                return False
        return False
    except urllib.error.URLError:
        return False


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

    lines.append("\n**Commit Hash** links to the commit in the HDF5 GitHub repository.\n")
    lines.append("| CVE ID | Fixed in HDF5 vX.Y.Z | Commit Hash | Description")
    lines.append("|---------|--------|-------------|-------------|")

    for issue in issues:
        if not isinstance(issue, dict):
            continue
        lines.append(_format_issue_row(issue))

    return lines


def yaml_to_markdown(data: Any, validate: bool = False) -> str:
    """Render markdown from the expected CVE YAML schema.

    The input should be a list of sections, each containing an optional
    title/url and an issues list of issue mappings. See _validate_yaml_schema
    for the complete schema expectations.
    """
    if validate:
        _validate_yaml_schema(data)

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
        "--validate-only",
        action="store_true",
        help="Validate YAML schema and commit hashes, then exit",
    )
    parser.add_argument(
        "--check-links",
        action="store_true",
        help="Check CVE URLs for reachability during validation",
    )
    parser.add_argument(
        "-o",
        "--output",
        help="Path to write markdown output (default: stdout)",
    )
    args = parser.parse_args()

    data = _load_yaml(args.input)
    if args.validate_only:
        _validate_yaml_schema(data, check_links=args.check_links)
        return 0

    markdown = yaml_to_markdown(data, validate=False)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as handle:
            handle.write(markdown)
    else:
        sys.stdout.write(markdown)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
