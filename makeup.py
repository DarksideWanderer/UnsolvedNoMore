#!/usr/bin/env python3
import os
import re
import subprocess
import shutil
import sys

# 确保使用 UTF-8 编码
sys.stdout.reconfigure(encoding='utf-8') if hasattr(sys.stdout, 'reconfigure') else None

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(BASE_DIR, "pdf_output")
os.makedirs(OUT_DIR, exist_ok=True)

# 自动查找 pandoc，可兼容 Windows 路径
def find_pandoc():
    # 1. 先尝试系统 PATH
    if shutil.which("pandoc"):
        return "pandoc"
    # 2. 常见 Windows 安装路径
    common_paths = [
        r'C:\Program Files\Pandoc\pandoc.exe',
        r'C:\Program Files (x86)\Pandoc\pandoc.exe'
    ]
    for path in common_paths:
        if os.path.exists(path):
            return f'"{path}"'  # 只在需要时加引号
    print("❌ 找不到 pandoc，请先安装 Pandoc 并确保在 PATH 中。")
    sys.exit(1)

PANDOC = find_pandoc()

def natural_key(name):
    """按文件名前导数字排序"""
    m = re.match(r"^(\d+)[_\- ]*(.*)$", name)
    if m:
        return (int(m.group(1)), m.group(2).lower())
    return (9999, name.lower())

def clean_content(content):
    """清理内容中的特殊字符"""
    # 替换常见的编码错误字符
    replacements = {
        '鈥?': '"',      # 你遇到的特定字符
        'â€œ': '"',      # 左双引号
        'â€': '"',       # 右双引号  
        'â€™': "'",      # 单引号
        'â€"': '—',     # 破折号
        'â€¦': '…',      # 省略号
        'Ã©': 'é',       # 常见的编码错误
        'Ã¨': 'è',
        'Ã': 'à',
    }
    
    for old, new in replacements.items():
        content = content.replace(old, new)
    
    return content

def merge_markdown(folder):
    """合并文件夹下的 Markdown 文件，返回合并后的文本和文件顺序列表"""
    files = sorted([f for f in os.listdir(folder) if f.endswith(".md")], key=natural_key)
    merged_lines = []
    file_order = []
    
    for fname in files:
        path = os.path.join(folder, fname)
        title = os.path.splitext(fname)[0].replace("_", " ")
        file_order.append(title)
        
        try:
            with open(path, "r", encoding="utf-8") as f:
                content = f.read().strip()
        except UnicodeDecodeError:
            # 如果 UTF-8 失败，尝试其他编码
            try:
                with open(path, "r", encoding="gbk") as f:
                    content = f.read().strip()
                print(f"⚠️  文件 {fname} 使用 GBK 编码读取")
            except:
                with open(path, "r", encoding="utf-8", errors="replace") as f:
                    content = f.read().strip()
                print(f"⚠️  文件 {fname} 使用错误替换模式读取")
        
        # 清理内容
        content = clean_content(content)
        
        # 给每个文件加一个锚点 label，用于目录页页码引用
        merged_lines.append(f"\\hypertarget{{{title}}}{{}}\n{content}\n\n")
    
    return "\n\n---\n\n".join(merged_lines), file_order

def build_pdf_with_pandoc(folder):
    category = os.path.basename(folder)
    merged_text, file_order = merge_markdown(folder)

    final_md = os.path.join(OUT_DIR, f"{category}_final.md")
    pdf_file = os.path.join(OUT_DIR, f"{category}.pdf")

    # 直接写合并后的 Markdown（不再生成手动目录）
    with open(final_md, "w", encoding="utf-8") as f:
        f.write(merged_text)

    print(f"📝 正在生成 {category}.pdf...")
    
    # 准备 pandoc 命令
    pandoc_cmd = [
        PANDOC,
        final_md,
        "-o", pdf_file,
        '--pdf-engine=xelatex',
        '--toc',
        '--variable', 'toc-title:目录',
        '--variable', 'toc-ownpage',
        '--highlight-style=tango',
        '--variable', 'geometry:margin=1in',
        '--variable', 'mainfont:SimSun',
        '--variable', 'monofont:Consolas', 
        '--variable', 'CJKmainfont:SimSun',
        '--variable', 'encoding=utf-8',
        '--variable', 'header-includes=\\usepackage{amsmath}\\usepackage{amssymb}\\usepackage{xeCJK}\\setCJKmainfont{SimSun}'
    ]
    
    # 打印命令用于调试
    print("🔧 执行命令:", ' '.join(pandoc_cmd))
    
    try:
        # 调用 Pandoc 生成 PDF
        result = subprocess.run(
            pandoc_cmd,
            check=True,
            capture_output=True,
            text=True,
            encoding='utf-8'
        )
        print(f"✅ 成功生成 {category}.pdf")
        
    except subprocess.CalledProcessError as e:
        print(f"❌ 生成 PDF 失败:")
        print("标准输出:", e.stdout)
        print("标准错误:", e.stderr)
        raise

def main():
    print("🚀 开始处理 Markdown 文件...")
    for d in os.listdir(BASE_DIR):
        folder = os.path.join(BASE_DIR, d)
        if os.path.isdir(folder) and not d.startswith(".") and d != "pdf_output":
            print(f"📁 处理文件夹: {d}")
            build_pdf_with_pandoc(folder)
    print("🎉 所有处理完成!")

if __name__ == "__main__":
    main()