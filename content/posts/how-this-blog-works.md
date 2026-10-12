---
title: "How This Blog Works"
date: 2026-10-12
description: "How this Hugo blog is built and published — Markdown to GitHub to Vercel, driven by OpenCode."
tags:
  - "hugo"
  - "vercel"
  - "opencode"
  - "writing"
---

Hello and welcome to **Push The Script**. This post walks through how this
blog is built and published — so every article you read here goes from a
Markdown file to a live page in under a minute. Consider it both an intro and
a template you can copy for your own posts.

## The stack at a glance

| Layer | Tool | Job |
| --- | --- | --- |
| Site generator | Hugo | Turns Markdown into a fast static site |
| Content | Markdown files | Each post is a single `.md` file |
| Version control | Git + GitHub | Keeps history of every edit |
| Hosting | Vercel | Rebuilds and deploys on every push |
| Editor agent | OpenCode | Writes and publishes posts for me |

## How a post gets published

1. A post is written as a Markdown file in `content/posts/`.
2. The file opens with **front matter** — `title`, `date`, `tags`, `description`.
3. Git commits the change and pushes it to GitHub.
4. Vercel sees the push, runs `hugo --gc --minify`, and deploys the site.

From the terminal, publishing is one command:

```bash
printf '# Hello\n\nBody here.\n' | ./scripts/new-post.sh \
  --title "My new post" \
  --tags "hugo, writing"
```

No servers to log into, no databases — just a file, a commit, and a deploy.

## Anatomy of a post

Every post starts with front matter, then the body in Markdown:

```markdown
---
title: "How This Blog Works"
date: 2026-10-12
description: "Short summary shown in search results and cards"
tags:
  - "hugo"
  - "vercel"
---

Your opening paragraph here.

## A section

Content with **bold**, *italics*, `inline code`, and [links](https://example.com).

## Another section with a list

- point one
- point two
- point three

## A section with a table

| Column A | Column B |
| --- | --- |
| value | value |
```

> Tip: keep the `description` short and specific — it powers SEO and the
> little preview cards when the post is shared.

## Why this setup works

- **Fast and cheap.** Static HTML means no server bills and near-instant loads.
- **Everything is plain text.** Posts are portable — you can move the whole
  blog or import it elsewhere without losing anything.
- **Editing is versioned.** Every change is on GitHub, so nothing is ever lost.
- **AI-friendly.** Because posts are just Markdown files in a git repo, an
  agent like OpenCode can draft, review, and publish them directly.

If you'd like to understand a specific part in more depth — like how the
layouts work or how to add images — that can be its own post. Meanwhile, this
file (look for `content/posts/how-this-blog-works.md`) makes a perfect
starting point for your next article.
