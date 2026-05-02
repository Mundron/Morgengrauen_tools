#!/usr/bin/env python3
"""
extract_lua.py — Extract Lua scripts from a Mudlet MudletPackage XML file.

Usage:
    python3 extract_lua.py <path/to/module.xml>
    cat module.xml | python3 extract_lua.py -

Output: annotated Lua source printed to stdout (redirect to a .lua file as needed).
"""

import sys
import html
import xml.etree.ElementTree as ET
from pathlib import Path


# ---------------------------------------------------------------------------
# Node types that carry executable Lua in a <script> child
# ---------------------------------------------------------------------------
SCRIPT_BEARING = {
    "Script", "Alias", "Trigger", "Timer", "Action", "Key"
}

# Node types that are folder/group containers (recurse but don't emit directly)
FOLDER_TYPES = {
    "ScriptGroup", "AliasGroup", "TriggerGroup", "KeyGroup",
    "TimerGroup", "ActionGroup",
}

# Package-level wrapper elements whose children we process
PACKAGE_TYPES = {
    "ScriptPackage", "AliasPackage", "TriggerPackage",
    "TimerPackage", "ActionPackage", "KeyPackage",
}

SEPARATOR = "-" * 72


def unescape(text: str) -> str:
    """Unescape HTML entities that Mudlet encodes inside XML CDATA."""
    if not text:
        return ""
    # html.unescape handles &lt; &gt; &amp; &quot; &#39; etc.
    text = html.unescape(text)
    # Non-breaking space → regular space
    text = text.replace("\u00a0", " ")
    return text


def get_child_text(element, tag: str, default: str = "") -> str:
    child = element.find(tag)
    if child is not None and child.text:
        return child.text.strip()
    return default


def is_folder(element) -> bool:
    return element.get("isFolder", "no").lower() == "yes"


def format_header(breadcrumb: list[str], source: str, extra_comments: list[str] = None) -> str:
    path = " > ".join(breadcrumb)
    lines = [
        SEPARATOR,
        f"-- [{path}]",
        f"-- Source: {source}",
    ]
    if extra_comments:
        for c in extra_comments:
            lines.append(f"-- {c}")
    lines.append(SEPARATOR)
    return "\n".join(lines)


def extract_from_node(element, breadcrumb: list[str], source: str, results: list):
    """
    Recursively extract Lua from a node element.
    Appends (header_str, lua_str) tuples to `results`.
    """
    tag = element.tag

    if tag in PACKAGE_TYPES or tag in FOLDER_TYPES:
        # Determine group label for the breadcrumb
        name_el = element.find("name")
        label = name_el.text.strip() if (name_el is not None and name_el.text) else tag
        new_crumb = breadcrumb + [label]
        for child in element:
            extract_from_node(child, new_crumb, source, results)
        return

    if tag not in SCRIPT_BEARING:
        return  # ignore TriggerPackage/etc at root — handled above

    if is_folder(element):
        # A Script/Alias/etc node marked isFolder contains children, not code
        name_el = element.find("name")
        label = name_el.text.strip() if (name_el is not None and name_el.text) else tag
        new_crumb = breadcrumb + [label]
        for child in element:
            extract_from_node(child, new_crumb, source, results)
        return

    # --- Actual script-bearing leaf node ---
    name = get_child_text(element, "name", default="<unnamed>")
    script_el = element.find("script")
    if script_el is None or not (script_el.text or "").strip():
        return  # nothing to emit

    lua = unescape(script_el.text)
    if not lua.strip():
        return

    extra = []

    # For Aliases: include the regex pattern
    regex_el = element.find("regex")
    if regex_el is not None and regex_el.text:
        extra.append(f"Pattern: {regex_el.text.strip()}")

    # For Triggers: include regexCodeList entries
    rcl = element.find("regexCodeList")
    if rcl is not None:
        patterns = [s.text.strip() for s in rcl.findall("string") if s.text]
        if patterns:
            extra.append("Patterns:")
            for p in patterns:
                extra.append(f"  {p}")

    # Event handlers
    ehl = element.find("eventHandlerList")
    if ehl is not None:
        events = [s.text.strip() for s in ehl.findall("string") if s.text]
        if events:
            extra.append("Events: " + ", ".join(events))

    header = format_header(breadcrumb + [name], source, extra)
    results.append((header, lua))


def extract_from_xml(xml_text: str, source: str) -> list[tuple[str, str]]:
    """Parse XML and return list of (header, lua) tuples."""
    try:
        root = ET.fromstring(xml_text)
    except ET.ParseError as e:
        print(f"-- ERROR: Could not parse XML: {e}", file=sys.stderr)
        return []

    if root.tag != "MudletPackage":
        print(f"-- WARNING: Root element is <{root.tag}>, not <MudletPackage>. Proceeding anyway.",
              file=sys.stderr)

    results = []
    # Process each top-level package
    package_order = [
        "ScriptPackage", "AliasPackage", "TriggerPackage",
        "TimerPackage", "ActionPackage", "KeyPackage",
    ]
    for pkg_name in package_order:
        pkg_el = root.find(pkg_name)
        if pkg_el is None:
            continue
        for child in pkg_el:
            extract_from_node(child, [pkg_name], source, results)

    return results


def main():
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print(__doc__)
        sys.exit(0)

    path_arg = sys.argv[1]

    if path_arg == "-":
        xml_text = sys.stdin.read()
        source = "<stdin>"
    else:
        p = Path(path_arg)
        if not p.exists():
            print(f"ERROR: File not found: {path_arg}", file=sys.stderr)
            sys.exit(1)
        xml_text = p.read_text(encoding="utf-8", errors="replace")
        source = str(p)

    results = extract_from_xml(xml_text, source)

    if not results:
        print(f"-- No Lua scripts found in {source}")
        sys.exit(0)

    print(f"-- Extracted {len(results)} Lua block(s) from {source}")
    print(f"-- Generated by mudlet-lua-extractor skill")
    print()

    for header, lua in results:
        print(header)
        print(lua.rstrip())
        print()


if __name__ == "__main__":
    main()
