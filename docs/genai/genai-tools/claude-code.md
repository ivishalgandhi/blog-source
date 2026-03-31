# Claude Code Tips and Tricks

## First time setup 

- /terminal-setup enable shift+enter to insert new lines
- /allowed-tools Customize tool permissions
- /install-github-app 
- /config - Turn on notifications
- /theme Enable light/dark mode
- use dictation for long prompts


## Using Claude-Code to answer code base

- Q&A
    - How is @routingcontroller.py used ? 
    - How do i make a new @app/services/validationtemplatefactory ? 
    - Why does recoverfromexception take so many arguments ? 
    - why did we fix issue # 182872 by adding the if/esle in @src/login.ts ? 
    - In which version did we release the new @api/ext/prehooks.php API ? 
    - Look at PR #92882 then carefully verify which version were impacted ? 
    - What did i ship last week ? 
    - ask about git history ? 
    
## Editing code

- Use the tools to give it done
- Already has tools to edit files, brainstorm the code, TODOs, Subagents, listing files, webfetch and search, filesearch

## Use tools your way

- Propose fixes - i will implement one 
- Identify edge cases covered in signuptest.ts
- commit,push,pr
- use 3 parallel agents to brainstorm ideams for how to cleanup

## Plugin your teams tools

- Tell claude code about your bash tools
    - use the barley cli to check for error logs in the last training run use -h how to check it
    
- Tell claude about your MCP tools

```bash

claude mcp app barly_server --node myserver

```
## Common workflows

- Explore, plan, confirm, code commit

- Write tests commit code iterate commit

- write code screenshot result iterate
    - implement mock.png then screnshot it with puppeteer and iterate till it looks like the mock
    

## Give claude more context

- /enterprise root/CLAUDE.md
- ~/.claude/CLAUDE.md
- project-root/
    - CLAUDE.md
    - CLAUDE.local.md
- shortcut: type #
- Common bash commands - Common MCP tools
- Architectural decisions
- Important files
- Style guides
- Claude will pull on demand
- Take time to tune the performance

## Memory

/memory

## Configure CLAUDE.MD MCP Servers 

- Puppeteer pilot end to end test

## Common keybindings

- shift+tab to auto accept edits
- # to create a memory
- ! to enter bash mode
- @ to add a file
- Esc to cancel
- double esc to jump back in history --resume to resume
- ctrl+r for verbose output
- /vibe

## Claude Code SDK

```bash

claude -p

```bash
claude -p \
"What did i do this week?" \
--allowedTools Bash(git log:*)
--output-format json
```

```bash
git status | claude -p "What are my changes" \\
--output-format=json | jq '.result'

"Your changes are:"
````



## Multi Claude

- ssh + tmux

- use one checkout with git worktrees

- github actions + launch jobs in parallel

- use multiple checkouts in separate terminal tabs


## Learnings from building agents

- Bash is dangerous - make it safe ; static read only commands ; complex tier command structure system
- claude code is multimodal
- CLI instead of IDE
    - Terminal is the common denominator
- Machine learning modelling 
    - 





## References


https://www.youtube.com/watch?v=6eBSHbLKuN0


