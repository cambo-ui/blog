#!/usr/bin/env python3
import html, re, sys, unicodedata
from xml.etree import ElementTree as ET
from pathlib import Path
from markdownify import markdownify as md

FEED = "takeout-extract/Takeout/Blogger/Blogs/Push The Script/feed.atom"
OUT = Path("content/posts")
OUT.mkdir(parents=True, exist_ok=True)

NS = {"a": "http://www.w3.org/2005/Atom",
      "b": "http://schemas.google.com/blogger/2018"}

tree = ET.parse(FEED)
root = tree.getroot()

def text(el, tag, ns="a"):
    found = el.find(f"{ns}:{tag}", NS)
    return found.text.strip() if found is not None and found.text else ""

def slugify(title, link):
    if link:
        m = re.search(r"/(\d{4})/(\d{2})/([^/]+)\.html", link)
        if m:
            return m.group(3)
    s = unicodedata.normalize("NFKD", title).encode("ascii", "ignore").decode()
    s = re.sub(r"[^a-zA-Z0-9]+", "-", s).strip("-").lower()
    return s or "post"

count = 0
for entry in root.findall("a:entry", NS):
    etype = text(entry, "type", "b")
    status = text(entry, "status", "b")
    if etype != "POST" or status != "LIVE":
        continue
    title = text(entry, "title")
    published = text(entry, "published")[:10]
    content_el = entry.find("a:content", NS)
    raw_html = content_el.text if content_el is not None and content_el.text else ""
    decoded = html.unescape(raw_html)
    link = ""
    for l in entry.findall("a:link", NS):
        if l.get("rel") == "alternate":
            link = l.get("href", "")
    slug = slugify(title, link)
    if "<style" in decoded or "<script" in decoded:
        # keep original HTML as standalone file, embed via iframe
        html_dir = Path("static/posts-html")
        html_dir.mkdir(parents=True, exist_ok=True)
        if "<body" in decoded:
            head = re.search(r"<head>(.*?)</head>", decoded, flags=re.S)
            bodym = re.search(r"<body[^>]*>(.*?)</body>", decoded, flags=re.S)
            styles = ""
            if head:
                styles = "".join(re.findall(r"<style.*?</style>", head.group(1), flags=re.S))
            body_html = (styles + "\n" + bodym.group(1)).strip() if bodym else decoded
        else:
            body_html = decoded
        standalone = f"<!DOCTYPE html>\n<html><head><meta charset='utf-8'><meta name='viewport' content='width=device-width, initial-scale=1'></head><body>\n{body_html}\n</body></html>\n"
        (html_dir / f"{slug}.html").write_text(standalone, encoding="utf-8")
        markdown = f'<iframe src="/posts-html/{slug}.html" style="width:100%;border:none;" loading="lazy"></iframe>'
    else:
        markdown = md(decoded, heading_style="ATX").strip()
    # plain-text description: strip style/script blocks first
    cleaned = re.sub(r"<(style|script)[^>]*>.*?</\1>", " ", decoded, flags=re.S)
    plain = re.sub(r"<[^>]+>", " ", cleaned)
    plain = re.sub(r"\s+", " ", plain).strip()
    desc = plain[:157] + "..." if len(plain) > 160 else plain
    desc = desc.replace('"', "'")
    title_esc = title.replace('"', "'")
    fm = f'''---
title: "{title_esc}"
date: {published}
description: "{desc}"
{f'url: "/{link.split("://")[-1].split("/", 1)[-1]}"' if link else ""}
---

'''
    (OUT / f"{slug}.md").write_text(fm + markdown + "\n", encoding="utf-8")
    count += 1
    print(f"  + {slug}.md  ({published})  {title}")

print(f"Imported {count} posts into {OUT}/")
