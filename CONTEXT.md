# Context — The Data Column (blog)

Glossary of domain terms for the blog. Keep this free of implementation detail.

## Terms

### Reader
A visitor to the blog. To leave a Reaction or a Comment, a Reader must be
authenticated via GitHub. Anonymous Readers can view everything but cannot
Like or Comment.

### Post
A single blog article, addressed by its URL pathname (e.g. `/2026/06/orchestration-go`).
The pathname is the stable identity used to associate Reactions and Comments
with a Post.

### Reaction (a.k.a. "Like")
An emoji reaction a Reader leaves on a Post as a whole (e.g. 👍/❤️). Backed by
reactions on the Post's backing GitHub Discussion. This is what the user calls
a "like".

### Comment
Free-text feedback a Reader leaves on a Post. Comments are threaded and are
stored as replies in the Post's backing GitHub Discussion.

### Backing Discussion
The single GitHub Discussion that holds all Reactions and Comments for one Post.
Created lazily the first time a Reader interacts with the Post. Lives in the
public `ivishalgandhi.github.io` repo and is matched to its Post by URL
`pathname`. Reactions and Comments appear only on individual blog Posts, not on
docs or book pages.
