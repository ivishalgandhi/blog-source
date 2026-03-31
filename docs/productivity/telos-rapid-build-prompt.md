---
id: telos-rapid-build-prompt
title: Telos Rapid Build Prompt - 7 Minute Method
sidebar_label: Rapid Build Prompt
sidebar_position: 5
---

# Telos Rapid Build Prompt - 7 Minute Method

This is the proven prompt that guides you through creating a complete Telos File in 7-10 minutes. Simply copy and paste everything below into ChatGPT or any AI assistant and follow the coach's questions.

---

# 📝 TELOS File Rapid-Build Prompt  
*Copy & paste everything below into ChatGPT (or any LLM) and follow the coach's questions. You'll have a first-draft TELOS in about 7 – 10 minutes.*

---

## SYSTEM INSTRUCTIONS  
You are a focused **TELOS Coach**.  
Your job is to guide the user through each section of a TELOS file quickly and thoughtfully, then output a completed markdown file using the **TEMPLATE** provided.  

**Flow:**  
1. Greet the user and explain you'll ask a brief series of questions.  
2. Work through the sections in this order, using the **SECTION QUESTIONS**.  
3. After each section, paraphrase the user's answers back for confirmation.  
4. Keep momentum—short follow-ups only when clarity is needed.  
5. When all sections are done, assemble and display the finished TELOS file exactly in the **TEMPLATE** format.  
6. Close by reminding the user to save the file and revisit it often.

---

## SECTION QUESTIONS  

### 1️⃣ Problems  
- "Name 1-3 problems in the world that truly frustrate you."  
- "Who else is affected, and why does this matter to you personally?"  
- "Distill each problem into one clear sentence (≤ 20 words)."

### 2️⃣ Missions  
For every problem:  
- "What concrete, lifelong pursuit could you take on to address this problem?"  
- "Phrase each mission starting with an action verb (e.g., **Protect**, **Build**, **Educate**)."

### 3️⃣ Narratives  
Craft three versions that communicate your main mission(s):  
1. **Short** – ≤ 15 words  
2. **Conversational** – 1 sentence  
3. **30-second pitch** – ≈ 70 words  

Prompt follow-ups to sharpen clarity and energy.

### 4️⃣ Goals + Metrics  
For each mission gather 1-3 SMART goals:  
- Specific outcome  
- Measurable metric  
- Achievable scope  
- Relevant to the mission  
- Time-bound ("by {'<date>'}")

### 5️⃣ Challenges  
- "List honest internal or external obstacles that could block you."

### 6️⃣ Strategies  
For every challenge:  
- "What practical strategy will you use to overcome this obstacle?"

### 7️⃣ Projects (optional if time)  
- "Name any active or upcoming projects that directly advance your strategies or goals."

### 8️⃣ History (optional if time)  
- "Share 3-5 milestone events that shaped who you are (year + 1-line description)."

### 9️⃣ Log (explain only)  
- Tell the user: "Going forward, add dated journal bullets under **📒 Log** to track progress."

---

## TEMPLATE  
*(Replace `<>` with the user's answers and keep the headings exactly as written.)*

```markdown
# TELOS

## ✅ Problems
- **P1:** <Problem 1>
- **P2:** <Problem 2>
- **P3:** <Problem 3>

## 🎯 Missions
- **M1 (→P1):** <Mission 1>
- **M2 (→P2):** <Mission 2>
- **M3 (→P3):** <Mission 3>

## 🎙️ Narratives
- **Short (15 words):** "<Short narrative>"
- **Conversational (1 sentence):** "<Conversational narrative>"
- **30-sec Pitch:** "<30-second narrative>"

## 🥅 Goals + Metrics
- **G1 (→M1):** <Goal 1> — *Metric:* <metric>
- **G2 (→M2):** <Goal 2> — *Metric:* <metric>
- **G3 (→M3):** <Goal 3> — *Metric:* <metric>

## 🚧 Challenges
- **C1:** <Challenge 1>
- **C2:** <Challenge 2>

## 🔧 Strategies
- **S1 (→C1):** <Strategy 1>
- **S2 (→C2):** <Strategy 2>

## 📂 Projects
- **PJT1 (→S1):** <Project 1>
- **PJT2 (→S2):** <Project 2>

## 🕰️ History
- **YYYY:** <Milestone 1>
- **YYYY:** <Milestone 2>

## 📒 Log
- *Add dated bullet entries here going forward…*
```

---

## Using This Prompt with Fabric

### Why the Original Prompt Doesn't Work Well with Fabric

The NetworkChuck prompt is designed as an **interactive coaching session** with:
- Back-and-forth questions
- Paraphrasing answers for confirmation
- Follow-up questions based on responses
- A conversational flow

Fabric patterns work best with **one-shot inputs** that produce immediate outputs, making the interactive coaching approach incompatible.

### Fabric-Adapted Telos Creation

For Fabric users, here are two approaches:

#### Method 1: Use the Telos Template with Fabric

```bash
# Use the fill-in-the-blank template approach
cat telos-template.md | fabric -p fill_telos_template

# Or provide your context and let Fabric fill it
echo "I'm a 35-year-old retail worker trying to break into cybersecurity. I'm self-taught, feeling overwhelmed, and need to support my family." | fabric -p create_telos_from_context
```

#### Method 2: One-Shot Telos Creation with Fabric

```bash
# Create Telos from your current situation
cat << EOF | fabric -p create_telos_rapid
Current Situation: [Describe your job, age, family, challenges, goals]
Frustrations: [What frustrates you most right now]
Skills: [What are you good at]
Dreams: [What would you do if money wasn't a concern]
EOF
```

### Custom Fabric Pattern for Telos

You can create your own Fabric pattern. Save this as `~/.config/fabric/patterns/create_telos`:

```system
You are a Telos creation assistant. Based on the user's input, create a complete Telos file in markdown format.

Structure the output with these sections:
- Problems (personal and scaled)
- Missions (action-oriented)
- Narratives (short, conversational, 30-second)
- Goals (SMART format)
- Challenges (honest obstacles)
- Strategies (practical solutions)
- History (key life events)
- Journal (template for future entries)

Be specific, actionable, and encourage brutal honesty. Use emojis for section headers like the NetworkChuck template.
```

### Recommended Fabric Workflow

1. **Use the template approach** for best results with Fabric
2. **Create your initial Telos** using the template and Fabric
3. **Use Fabric patterns** for ongoing analysis:
   ```bash
   cat my_telos.md | fabric -p analyze_telos
   cat my_telos.md | fabric -p find_blindspots
   cat my_telos.md | fabric -p suggest_goals
   ```

### Best of Both Worlds

- **Initial Creation**: Use the NetworkChuck prompt with ChatGPT/Claude for the interactive coaching experience
- **Ongoing Analysis**: Use Fabric patterns for regular analysis and updates
- **Integration**: Combine both approaches for a comprehensive Telos practice

---

## How to Use This Prompt

### Step 1: Copy the Entire Prompt
Select everything from the "📝 TELOS File Rapid-Build Prompt" title down to the end of the template and copy it.

### Step 2: Paste into Your AI Assistant
Paste the entire prompt into ChatGPT, Claude, or any other AI assistant.

### Step 3: Follow the Coach's Questions
The AI will act as a TELOS Coach and guide you through each section:
- It will ask specific questions for each section
- It will paraphrase your answers for confirmation
- It will keep the process moving quickly

### Step 4: Get Your Complete Telos File
After answering all the questions, the AI will output a complete, formatted Telos file that you can save and use immediately.

### Step 5: Save and Maintain
Save the output as a markdown file (e.g., `my_telos.md`) and update it regularly with new journal entries.

## Tips for Best Results

### Be Honest and Specific
- Don't worry about impressing anyone - this is for you
- Specific problems lead to powerful missions
- Honest challenges create effective strategies

### Follow the Flow
- Let the AI guide you through the sections in order
- Don't skip ahead - each section builds on the previous ones
- Keep answers concise and focused

### Use Action Verbs for Missions
- Start missions with words like: **Protect**, **Build**, **Educate**, **Create**, **Transform**, **Connect**
- Make them concrete and actionable
- Connect each mission directly to a problem

### Make Goals SMART
- **Specific** - Clear and defined outcomes
- **Measurable** - Quantifiable metrics
- **Achievable** - Realistic but challenging
- **Relevant** - Connected to your missions
- **Time-bound** - Specific deadlines

### Don't Overthink
- The process is designed to be quick (7-10 minutes)
- Your first instinct is usually the right one
- You can always refine and update later

## After You Create Your Telos File

### Immediate Next Steps
1. **Save the file** as `telos.md` or `my_telos.md`
2. **Read it aloud** to check how it sounds
3. **Make any quick edits** that feel necessary
4. **Start your first journal entry** with today's date

### Ongoing Maintenance
- **Daily**: Add brief journal entries
- **Weekly**: Review goals and update progress
- **Monthly**: Do a full review and refine sections
- **Quarterly**: Major reassessment and updates

### Using AI with Your Telos
Once you have your Telos file, you can use it with AI for:
- **Personal analysis**: "Here's my Telos file. What are my blind spots?"
- **Decision making**: "Based on my Telos, should I take this opportunity?"
- **Problem solving**: "Help me think through this challenge using my Telos context"

## Why This Method Works

### Structured Approach
- The 9-section structure ensures comprehensive coverage
- Each section builds logically on previous ones
- The template format ensures consistency

### Coaching Style
- The AI acts as a guide, not just a tool
- Questions are designed to elicit honest responses
- The paraphrasing step ensures accuracy

### Speed and Momentum
- 7-10 minute timeframe prevents overthinking
- Quick pace maintains energy and focus
- Immediate output provides instant gratification

### Proven Results
- Thousands of people have used this method successfully
- The specific questions have been refined through experience
- The template format works well with AI analysis

---

**Ready to start? Copy the prompt above and create your Telos File in the next 10 minutes!**
