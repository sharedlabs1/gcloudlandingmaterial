#!/usr/bin/env python3
"""
Improved converter for Markdown lab guides to AsciiDoc format
"""

import os
import re
import glob
from pathlib import Path

def convert_md_to_adoc(content):
    """Convert markdown content to AsciiDoc format"""
    
    lines = content.split('\n')
    result_lines = []
    in_code_block = False
    code_block_lang = None
    
    for line in lines:
        if line.startswith('```'):
            if not in_code_block:
                # Starting a code block
                in_code_block = True
                lang_match = re.match(r'^```(\w+)', line)
                if lang_match:
                    code_block_lang = lang_match.group(1)
                    result_lines.append(f'[source,{code_block_lang}]')
                else:
                    result_lines.append('[source]')
                result_lines.append('----')
            else:
                # Ending a code block
                in_code_block = False
                code_block_lang = None
                result_lines.append('----')
        elif line.startswith('````'):
            if not in_code_block:
                # Starting a code block with 4 backticks
                in_code_block = True
                lang_match = re.match(r'^````(\w+)', line)
                if lang_match:
                    code_block_lang = lang_match.group(1)
                    result_lines.append(f'[source,{code_block_lang}]')
                else:
                    result_lines.append('[source]')
                result_lines.append('----')
            else:
                # Ending a code block with 4 backticks
                in_code_block = False
                code_block_lang = None
                result_lines.append('----')
        elif in_code_block:
            # Inside a code block, keep the line as-is
            result_lines.append(line)
        else:
            # Not in a code block, apply other conversions
            # Replace headers (# becomes =, ## becomes ==, etc.)
            if line.startswith('#'):
                level = len(line) - len(line.lstrip('#'))
                header_text = line.lstrip('#').strip()
                result_lines.append('=' * level + ' ' + header_text)
            else:
                # Apply other conversions
                converted_line = line
                
                # Replace bold text (**text** becomes *text*)
                converted_line = re.sub(r'\*\*(.+?)\*\*', r'*\1*', converted_line)
                
                # Replace italic text (*text* becomes _text_)
                converted_line = re.sub(r'(?<!\*)\*([^*]+?)\*(?!\*)', r'_\1_', converted_line)
                
                # Replace links [text](url) becomes link:url[text]
                converted_line = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'link:\2[\1]', converted_line)
                
                # Replace images ![alt](url) becomes image:url[alt]
                converted_line = re.sub(r'!\[([^\]]*)\]\(([^)]+)\)', r'image::\2[\1]', converted_line)
                
                # Replace unordered lists (- becomes *)
                converted_line = re.sub(r'^(\s*)- (.+)$', r'\1* \2', converted_line)
                
                # Replace blockquotes (> becomes quote block)
                if converted_line.startswith('> '):
                    converted_line = converted_line[2:]
                    result_lines.append('[quote]')
                    result_lines.append('____')
                    result_lines.append(converted_line)
                    result_lines.append('____')
                    continue
                
                # Replace horizontal rules (--- becomes ''')
                if converted_line.strip() == '---':
                    converted_line = "'''"
                
                result_lines.append(converted_line)
    
    content = '\n'.join(result_lines)
    
    # Handle tables
    lines = content.split('\n')
    in_table = False
    converted_lines = []
    
    for line in lines:
        if '|' in line and not in_table:
            # Check if this looks like a table header
            if '|' in line and not line.strip().startswith('image::'):
                in_table = True
                converted_lines.append('[cols="1,1,1", options="header"]')
                converted_lines.append('|===')
                converted_lines.append(line)
        elif in_table and '|' in line:
            if '---' in line:
                # Skip markdown table separator
                continue
            converted_lines.append(line)
        elif in_table and '|' not in line:
            converted_lines.append('|===')
            converted_lines.append(line)
            in_table = False
        else:
            converted_lines.append(line)
    
    content = '\n'.join(converted_lines)
    
    # Add document attributes at the top
    adoc_header = """:toc:
:toclevels: 3
:numbered:
:source-highlighter: highlightjs
:icons: font

"""
    
    return adoc_header + content

def convert_file(input_file, output_dir):
    """Convert a single markdown file to AsciiDoc"""
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Convert content
        adoc_content = convert_md_to_adoc(content)
        
        # Generate output filename
        input_path = Path(input_file)
        output_filename = input_path.stem + '.adoc'
        output_path = Path(output_dir) / output_filename
        
        # Write converted content
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(adoc_content)
        
        print(f"✓ Converted {input_path.name} -> {output_filename}")
        return True
        
    except Exception as e:
        print(f"✗ Error converting {input_file}: {str(e)}")
        return False

def main():
    """Main conversion function"""
    # Define paths
    lab_guides_dir = r"c:\Users\niran\Downloads\gcpcloudusingterraform\gcloudlandingmaterial\workshop-materials\lab-guides"
    output_dir = r"c:\Users\niran\Downloads\gcpcloudusingterraform\gcloudlandingmaterial\workshop-materials\adoc-lab-guides"
    
    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)
    
    # Find all markdown files
    md_files = glob.glob(os.path.join(lab_guides_dir, "*.md"))
    
    if not md_files:
        print("No markdown files found in the lab-guides directory")
        return
    
    print(f"Found {len(md_files)} markdown files to convert")
    print("=" * 50)
    
    # Convert each file
    successful_conversions = 0
    for md_file in md_files:
        if convert_file(md_file, output_dir):
            successful_conversions += 1
    
    print("=" * 50)
    print(f"Conversion complete: {successful_conversions}/{len(md_files)} files converted successfully")
    
    # Create a README file explaining the conversion
    readme_content = """# AsciiDoc Lab Guides

This directory contains the AsciiDoc versions of the lab guides converted from Markdown format.

## Features

* Table of Contents (TOC) enabled
* Numbered sections
* Syntax highlighting for code blocks
* Font icons

## Usage

You can view these files with any AsciiDoc viewer or convert them to HTML using:

```bash
asciidoctor filename.adoc
```

Or convert to PDF using:

```bash
asciidoctor-pdf filename.adoc
```

## Original Files

The original Markdown files are preserved in the `lab-guides` directory.
"""
    
    readme_path = Path(output_dir) / "README.md"
    with open(readme_path, 'w', encoding='utf-8') as f:
        f.write(readme_content)
    
    print(f"✓ Created README.md with usage instructions")

if __name__ == "__main__":
    main()
