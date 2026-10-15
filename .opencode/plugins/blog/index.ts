import { execFile } from "node:child_process"
import { existsSync } from "node:fs"
import { mkdtemp, rm, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import { isAbsolute, join, resolve } from "node:path"
import { promisify } from "node:util"

const exec = promisify(execFile)

type PostInput = {
  title: string
  body: string
  tags?: string[]
  description?: string
  slug?: string
  date?: string
  draft?: boolean
  push?: boolean
}

type PublishInput = {
  message?: string
  push?: boolean
}

/** Find the Hugo site root (the dir containing scripts/new-post.sh). */
function resolveSiteRoot(location: string, siteDir?: string): string {
  const candidates = [siteDir, "myblog", "."].filter(
    (c): c is string => typeof c === "string" && c.length > 0,
  )
  for (const candidate of candidates) {
    const dir = isAbsolute(candidate) ? candidate : resolve(location, candidate)
    if (existsSync(join(dir, "scripts", "new-post.sh"))) return dir
  }
  throw new Error(
    `blog plugin: could not find scripts/new-post.sh under ${location} (set plugins options.siteDir)`,
  )
}

async function runScript(
  scriptPath: string,
  args: string[],
  cwd: string,
  signal?: AbortSignal,
): Promise<string> {
  try {
    const { stdout, stderr } = await exec("bash", [scriptPath, ...args], {
      cwd,
      signal,
      maxBuffer: 16 * 1024 * 1024,
    })
    return [stdout, stderr].filter(Boolean).join("\n").trim() || "ok"
  } catch (error) {
    const e = error as { stdout?: string; stderr?: string; message?: string }
    const detail = [e.stdout, e.stderr, e.message].filter(Boolean).join("\n").trim()
    throw new Error(detail || "command failed")
  }
}

// `Plugin.define` from "@opencode/plugin" is an identity helper, but OpenCode's
// compiled runtime cannot resolve that bare specifier from a local plugin dir
// (it does not search the plugin's node_modules). Exporting the definition
// directly is equivalent and avoids the unresolvable import.
export default {
  id: "blog",
  async setup(ctx: any) {
    let siteRoot: string | undefined
    let resolveError = ""
    try {
      siteRoot = resolveSiteRoot(
        ctx.location.directory,
        typeof ctx.options.siteDir === "string" ? ctx.options.siteDir : undefined,
      )
    } catch (error) {
      resolveError = error instanceof Error ? error.message : String(error)
    }

    const requireSite = (): string => {
      if (!siteRoot) throw new Error(resolveError || "blog plugin: site root not found")
      return siteRoot
    }

    await ctx.tool.transform((editor) => {
      editor.namespace({
        name: "blog",
        description: "Publish posts to the Hugo blog (git commit + push, then Vercel deploys).",
      })

      editor.add({
        name: "post",
        description:
          "Create a new Markdown blog post in the Hugo site, commit it, and push to origin so Vercel deploys it. Use this for brand new posts.",
        input: {
          type: "object",
          properties: {
            title: { type: "string", description: "Post title." },
            body: { type: "string", description: "Post body as Markdown." },
            tags: { type: "array", items: { type: "string" }, description: "Optional tags." },
            description: { type: "string", description: "Optional short summary / SEO description." },
            slug: { type: "string", description: "Optional URL slug. Defaults to a slug of the title." },
            date: { type: "string", description: "Optional publish date (YYYY-MM-DD). Defaults to today." },
            draft: { type: "boolean", description: "If true, save as a draft and do not commit/push." },
            push: { type: "boolean", description: "Push to origin after committing. Defaults to true." },
          },
          required: ["title", "body"],
          additionalProperties: false,
        },
        options: { namespace: "blog", codemode: true },
        execute: async (input, context) => {
          try {
            const data = input as PostInput
            const root = requireSite()
            const dir = await mkdtemp(join(tmpdir(), "blog-post-"))
            const bodyFile = join(dir, "body.md")
            await writeFile(bodyFile, data.body, "utf8")
            const args = ["--title", data.title, "--body-file", bodyFile]
            if (data.slug) args.push("--slug", data.slug)
            if (data.date) args.push("--date", data.date)
            if (data.tags && data.tags.length > 0) args.push("--tags", data.tags.join(","))
            if (data.description) args.push("--description", data.description)
            if (data.draft) args.push("--draft")
            if (data.push === false) args.push("--no-push")
            try {
              const out = await runScript(join(root, "scripts", "new-post.sh"), args, root, context.signal)
              return { content: out }
            } finally {
              await rm(dir, { recursive: true, force: true })
            }
          } catch (error) {
            return { content: `blog_post failed: ${error instanceof Error ? error.message : String(error)}` }
          }
        },
      })

      editor.add({
        name: "publish",
        description:
          "Commit and push any pending changes in the Hugo site (edited posts, images, config) so Vercel deploys them.",
        input: {
          type: "object",
          properties: {
            message: { type: "string", description: "Commit message." },
            push: { type: "boolean", description: "Push to origin. Defaults to true." },
          },
          additionalProperties: false,
        },
        options: { namespace: "blog", codemode: true },
        execute: async (input, context) => {
          try {
            const data = input as PublishInput
            const root = requireSite()
            const args: string[] = []
            if (data.message) args.push("-m", data.message)
            if (data.push === false) args.push("--no-push")
            const out = await runScript(join(root, "scripts", "publish.sh"), args, root, context.signal)
            return { content: out }
          } catch (error) {
            return { content: `blog_publish failed: ${error instanceof Error ? error.message : String(error)}` }
          }
        },
      })
    })
  },
}
