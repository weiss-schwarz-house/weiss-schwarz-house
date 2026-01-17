#!/usr/bin/env python3
"""
Scan `games/` markdown files, get git first/last commit dates, and update front matter:
 - If `date` missing: set to first commit date (YYYY-MM-DD)
 - If last commit date > date: set `updated` to last commit date

Usage: run at repo root where .git exists.
"""
import os
import re
import subprocess
from datetime import datetime

GAMES_DIR = 'games'

def git_date(path, first=False):
    # return ISO date string like 2026-01-17T12:34:56+00:00 or None
    cmd = ['git', 'log']
    if first:
        cmd += ['--diff-filter=A', '--format=%cI', '-1', '--', path]
    else:
        cmd += ['-1', '--format=%cI', '--', path]
    try:
        out = subprocess.check_output(cmd, stderr=subprocess.DEVNULL)
        s = out.decode().strip()
        return s if s else None
    except subprocess.CalledProcessError:
        return None

def read_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        return f.read()

def write_file(path, text):
    with open(path, 'w', encoding='utf-8') as f:
        f.write(text)

def update_front_matter(text, date_first, date_last):
    # find YAML front matter (between first two '---' lines)
    m = re.match(r'^(---\s*\n)(.*?)(\n---\s*\n)(.*)$', text, re.S)
    if not m:
        # no front matter: create one
        fm = []
        if date_first:
            fm.append(f'date: {date_first[:10]}')
        if date_last and date_last[:10] != (date_first or '')[:10]:
            fm.append(f'updated: {date_last[:10]}')
        new = '---\n' + '\n'.join(fm) + '\n---\n\n' + text
        return new, bool(fm)

    head, body, tail, rest = m.group(1), m.group(2), m.group(3), m.group(4)
    lines = body.splitlines()
    kv = {}
    for i, line in enumerate(lines):
        if ':' in line:
            k, v = line.split(':', 1)
            kv[k.strip()] = v.strip()

    changed = False
    # set date if missing
    if 'date' not in kv and date_first:
        lines.insert(0, f'date: {date_first[:10]}')
        changed = True
        kv['date'] = date_first[:10]

    # set updated if last > date
    try:
        if date_last:
            last_d = datetime.fromisoformat(date_last)
            existing_date = kv.get('date')
            if existing_date:
                existing_d = datetime.fromisoformat(existing_date)
            else:
                existing_d = None
            if (existing_d is None) or (last_d.date() > existing_d.date()):
                # set updated
                # replace if exists, else append
                found = False
                for idx, line in enumerate(lines):
                    if line.strip().startswith('updated:'):
                        lines[idx] = f'updated: {date_last[:10]}'
                        found = True
                        break
                if not found:
                    lines.append(f'updated: {date_last[:10]}')
                changed = True
    except Exception:
        pass

    new_body = '\n'.join(lines)
    new_text = head + new_body + tail + rest
    return new_text, changed

def main():
    repo_root = os.getcwd()
    changed_files = []
    for root, dirs, files in os.walk(GAMES_DIR):
        for fname in files:
            if not fname.endswith('.md'):
                continue
            path = os.path.join(root, fname)
            rel = os.path.relpath(path, repo_root)
            # skip index.md
            if os.path.basename(rel).lower() == 'index.md':
                continue

            first = git_date(rel, first=True)
            last = git_date(rel, first=False)
            if not first and not last:
                continue

            src = read_file(path)
            new_text, changed = update_front_matter(src, first, last)
            if changed and new_text != src:
                write_file(path, new_text)
                changed_files.append(rel)
                print(f'Updated {rel}')

    if changed_files:
        # configure git and commit
        subprocess.check_call(['git', 'config', 'user.name', 'github-actions[bot]'])
        subprocess.check_call(['git', 'config', 'user.email', '41898282+github-actions[bot]@users.noreply.github.com'])
        subprocess.check_call(['git', 'add'] + changed_files)
        msg = 'chore: update game dates by script'
        subprocess.check_call(['git', 'commit', '-m', msg])
        print('Committed changes')
    else:
        print('No changes')

if __name__ == '__main__':
    main()
