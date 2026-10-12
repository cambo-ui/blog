# Push The Script — Hugo blog

Static [Hugo](https://gohugo.io/) blog deployed on [Vercel](https://vercel.com/).
Push to `main` and Vercel builds the site and deploys it automatically.

## Layout

```
content/posts/     Markdown posts
layouts/           Custom templates (no theme)
static/            css, favicon, imported HTML
scripts/           new-post.sh, publish.sh
.opencode/plugins/ OpenCode tooling (blog_post, blog_publish)
hugo.toml          Site config
vercel.json        Vercel build settings
```

## Local preview

```sh
hugo server -D
```

Then open http://localhost:1313. `public/`, `resources/`, and `takeout-extract/`
are git-ignored.

## Publish a new post

From the command line, pipe the Markdown body in:

```sh
printf '# Hello\n\nBody **here**.\n' | ./scripts/new-post.sh \
  --title "My Post" --tags "security,ai" --description "Short summary"
```

Or keep the body in a file:

```sh
./scripts/new-post.sh --title "My Post" --body-file draft.md --tags "ai"
```

Useful flags:

| Flag | Meaning |
| --- | --- |
| `--slug my-post` | Override the URL slug (defaults to a slug of the title) |
| `--date 2026-10-12` | Override the date (defaults to today) |
| `--draft` | Save without committing/pushing |
| `--no-push` | Commit locally but don't push |
| `-m "msg"` | Custom commit message |

## Publish edits

To commit and push any pending edits (posts, images, config):

```sh
./scripts/publish.sh -m "Fix typo"
```

## Deploy (one-time setup)

1. Create an empty repo on GitHub (do **not** add a README/.gitignore).
2. Connect this folder and push:

   ```sh
   git remote add origin git@github.com:USER/REPO.git
   git push -u origin main
   ```

3. In Vercel: **Add New → Project → Import** the repo.
   Framework preset **Hugo** is auto-detected; leave build/output as set by
   `vercel.json`.
4. After the first deploy, set `baseURL` in `hugo.toml` to your live URL
   (`https://<project>.vercel.app/`, or your custom domain) and commit.

## Posting from OpenCode

The plugin in `.opencode/plugins/blog/` exposes two tools:

- **`blog_post`** — create a post and publish it (`title`, `body`, optional
  `tags`, `description`, `slug`, `date`, `draft`, `push`).
- **`blog_publish`** — commit + push pending changes (`message`, `push`).

Both shell out to `scripts/new-post.sh` / `scripts/publish.sh`.
