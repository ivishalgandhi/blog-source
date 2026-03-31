# Publishing Reference

## How it works

Two repos:
- `ivishalgandhi/blog-source` — source code and blog posts
- `ivishalgandhi/ivishalgandhi.github.io` — hosts the built site

On every `git push origin main` from `blog-source`:
1. GitHub Actions runs `.github/workflows/deploy.yml`
2. Builds the Docusaurus site (`yarn build`)
3. Pushes `./build` to the `gh-pages` branch of `ivishalgandhi.github.io`
4. GitHub Pages serves it at `vishalgandhi.in`

## Publishing a post

```bash
# create blog/YYYY-MM-DD-post-title.md
git add .
git commit -m "your message"
git push origin main
```

Monitor at: `github.com/ivishalgandhi/blog-source/actions`

## Required secret

`GH_PAT` — stored in `blog-source` repo → Settings → Secrets → Actions

A classic PAT with `repo` scope. Regenerate at `github.com/settings/tokens` if expired, then update the secret.

## GitHub Pages settings (one-time, ivishalgandhi.github.io repo)

- Source: `gh-pages` branch → `/ (root)`
- Custom domain: `vishalgandhi.in`

## Why not deploy directly from blog-source?

`blog-source` is a project repo — GitHub would serve it at `vishalgandhi.in/blog-source/`.
`ivishalgandhi.github.io` is the user page repo — serves from root `/`.
