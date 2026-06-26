import os
import re
from pathlib import Path

docs_dir = Path('docs')
# Build a map of filename -> new relative path from docs_dir
file_map = {}
for root, _, files in os.walk(docs_dir):
    for f in files:
        if f.endswith('.md'):
            full_path = Path(root) / f
            rel_path = full_path.relative_to(docs_dir)
            file_map[f] = str(rel_path).replace('\\\\', '/')

# Function to update links in a file
def process_file(filepath):
    try:
        content = filepath.read_text(encoding='utf-8')
    except Exception as e:
        print(f"Skipping {filepath}: {e}")
        return
        
    new_content = content
    # Replace markdown links like [Text](../old/path/FILE.md) or [Text](FILE.md)
    # We will use a regex to find all markdown links
    def link_replacer(match):
        text = match.group(1)
        link = match.group(2)
        # Extract filename from link
        filename = link.split('/')[-1].split('#')[0]
        if filename in file_map:
            # Construct relative path from current file to the target file
            target_path = docs_dir / file_map[filename]
            try:
                rel_link = os.path.relpath(target_path, filepath.parent).replace('\\\\', '/')
                # Preserve anchor if it exists
                anchor = ''
                if '#' in link:
                    anchor = '#' + link.split('#')[1]
                return f'[{text}]({rel_link}{anchor})'
            except ValueError:
                pass
        return match.group(0)

    new_content = re.sub(r'\[([^\]]+)\]\(([^)]+\.md(?:#[^)]*)?)\)', link_replacer, new_content)
    
    if new_content != content:
        filepath.write_text(new_content, encoding='utf-8')
        print(f"Updated links in {filepath}")

for root, _, files in os.walk(docs_dir):
    for f in files:
        if f.endswith('.md'):
            process_file(Path(root) / f)

print('Done updating links.')
