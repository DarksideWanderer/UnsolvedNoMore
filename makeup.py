#!/usr/bin/env python3
"""Merge each template category and build its PDF with Pandoc."""

from __future__ import annotations

import re
import shutil
import subprocess
import sys
from pathlib import Path


base_dir = Path(__file__).resolve().parent
output_dir = base_dir / "pdf_output"


def find_executable(name: str, common_paths: list[Path]) -> str:
    """Return an executable path without adding shell quotes."""
    executable = shutil.which(name)
    if executable is not None:
        return executable
    for path in common_paths:
        if path.is_file():
            return str(path)
    searched = ", ".join(str(path) for path in common_paths)
    raise FileNotFoundError(
        f"找不到 {name}。请把它加入 PATH，或安装到以下位置之一：{searched}"
    )


def natural_key(path: Path) -> tuple[int, str]:
    """Sort a file by its leading number and then by the remaining name."""
    matched = re.match(r"^(\d+)[_\- ]*(.*)$", path.stem)
    if matched is None:
        return 10**9, path.stem.lower()
    return int(matched.group(1)), matched.group(2).lower()


def read_markdown(path: Path) -> str:
    """Read UTF-8 first and retain a GBK fallback for old notes."""
    try:
        return path.read_text(encoding="utf-8").strip()
    except UnicodeDecodeError:
        print(f"警告：{path.name} 不是 UTF-8，尝试按 GBK 读取。")
        return path.read_text(encoding="gbk").strip()


def merge_markdown(folder: Path) -> str:
    markdown_files = sorted(folder.glob("*.md"), key=natural_key)
    sections: list[str] = []
    for path in markdown_files:
        anchor = re.sub(r"[^0-9A-Za-z_-]+", "-", path.stem).strip("-")
        content = read_markdown(path)
        sections.append(f"\\hypertarget{{{anchor}}}{{}}\n{content}\n")
    return "\n\n---\n\n".join(sections)


def build_pdf(folder: Path, pandoc: str) -> None:
    category = folder.name
    merged_path = output_dir / f"{category}_final.md"
    pdf_path = output_dir / f"{category}.pdf"
    merged_path.write_text(merge_markdown(folder), encoding="utf-8")

    command = [
        pandoc,
        str(merged_path),
        "-o",
        str(pdf_path),
        "--pdf-engine=xelatex",
        "--toc",
        "--variable",
        "toc-title:目录",
        "--syntax-highlighting=tango",
        "--variable",
        "geometry:margin=1in",
        "--variable",
        "mainfont:SimSun",
        "--variable",
        "monofont:Consolas",
        "--variable",
        "CJKmainfont:SimSun",
        "--variable",
        "header-includes=\\usepackage{amsmath}\\usepackage{amssymb}",
    ]
    print(f"生成 {category}.pdf")
    subprocess.run(command, check=True)


def template_folders() -> list[Path]:
    """Only include non-hidden directories that directly contain Markdown."""
    return sorted(
        folder
        for folder in base_dir.iterdir()
        if folder.is_dir()
        and not folder.name.startswith(".")
        and folder != output_dir
        and any(folder.glob("*.md"))
    )


def main() -> int:
    try:
        pandoc = find_executable(
            "pandoc",
            [
                Path(r"C:\Program Files\Pandoc\pandoc.exe"),
                Path(r"C:\Program Files (x86)\Pandoc\pandoc.exe"),
            ],
        )
        find_executable("xelatex", [])
        output_dir.mkdir(exist_ok=True)
        for folder in template_folders():
            build_pdf(folder, pandoc)
    except (FileNotFoundError, UnicodeDecodeError, subprocess.CalledProcessError) as error:
        print(f"构建失败：{error}", file=sys.stderr)
        return 1
    print("全部 PDF 生成完成。")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
