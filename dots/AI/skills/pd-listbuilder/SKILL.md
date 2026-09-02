---
name: pd-listbuilder
description: >
  Build targeted outbound prospect lists for any business or service offer. Walks the user through defining their ICP, choosing custom scoring triggers (LinkedIn activity, employee count, tech stack, funding, content presence, etc.), then researches and builds a scored CSV/Excel prospect list with decision-maker contacts. Use this skill whenever someone says "build me a list", "find prospects", "prospect list", "lead list", "outbound list", "find me leads", "cold email list", "build a hit list", "/list", "/prospects", "/leads", "/build-list", mentions Apollo/Instantly/Prospect/Smartlead and wants contacts, uploads a CSV to enrich, or asks to find people to sell to. Also trigger when someone describes their ICP and wants to find matching companies. This is NOT for writing outreach messages (use outbound-dm-writer for that) — this is for building the list of people to reach out to.
---

# PD List Builder

Build targeted prospect lists for any business. The user defines who they're looking for and what signals matter — you research, score, and deliver a ready-to-import CSV.

The philosophy: a great prospect list isn't just names and emails. It's a scored, prioritized hit list where every row has been researched and every score is backed by real signals you verified. The scoring triggers are what make this powerful — they're custom to the user's specific offer, so the highest-scored prospects are the ones most likely to buy.

## The Flow

**Step 1** → Intake (what they sell, who they sell to)
**Step 2** → Trigger Selection (what signals indicate a good prospect)
**Step 3** → Research & Build (find companies + decision-makers)
**Step 4** → Score & Export (scored CSV/Excel file)

---

## STEP 1: INTAKE

Ask these questions to understand their offer and who they're targeting. Group questions naturally — don't make it feel like a form.

"Let's build your prospect list. First, tell me about your business so I can find the right people."

**What to learn:**

- What do you sell? (service, product, offer — keep it brief)
- Who's your ideal client? (industry, company size, role of the buyer)
- Any geographic focus? (US only, global, specific regions)
- How many prospects do you want? (default: 20-30 companies, which usually yields 40-80 contacts)
- Do you have any example companies that are a perfect fit? (helps calibrate)

After their answers, restate the ICP clearly:

"Got it. I'm looking for: [company type] with [size/characteristics], targeting [decision-maker role]. Let me help you pick your scoring triggers before I start researching."

---

## STEP 2: TRIGGER SELECTION

This is what makes the list powerful. Triggers are specific, verifiable signals that indicate a prospect is a good fit. Present example triggers organized by category and let the user pick which ones matter for their offer.

"Triggers are the signals that tell you someone is likely to buy. The more triggers a prospect hits, the higher they score on your list. Here are common triggers — pick the ones that matter for your offer, or tell me your own."

### Example Triggers by Category

**LinkedIn Signals**

- Decision-maker active on LinkedIn (posts regularly) — shows they value visibility/content
- Decision-maker has 1K+ LinkedIn followers — personal brand mindset
- Company page has 500+ followers — established presence
- Decision-maker recently changed roles (new in position) — new leaders make changes
- Decision-maker posted about [specific topic] recently — intent signal

**Company Signals**

- Employee count in target range (e.g., 10-100) — right size for the offer
- Recently raised funding (Seed, Series A) — has budget and growth pressure
- Founded in last 3 years — younger companies are more agile
- Uses specific tech stack (e.g., Salesforce, HubSpot, Shopify) — compatibility signal
- Hiring for specific roles (e.g., "marketing manager") — investing in that area

**Content & Marketing Signals**

- Has a blog but posts infrequently — needs content help
- Has a YouTube channel under 5K subs — underperforming, room to grow
- Has a podcast — already invests in long-form content
- No social media presence — blank slate, needs help
- Running paid ads (Meta, Google) — already spending on growth

**Industry-Specific Signals**

- Competitor is doing [X] well — creates urgency ("they're winning, you're not")
- Specific certification or compliance need — regulatory pressure
- Seasonal business approaching peak season — timing play
- eCommerce with 50+ products — scale makes the offer more valuable

**Custom Signals**

- "I want to check if they [specific thing]" — any verifiable signal works

After the user picks their triggers, assign point values together:

"Here's your scoring system. Each trigger is worth points based on how strong a buying signal it is. Let me know if you'd adjust any of these."

| Trigger            | Points | Why            |
| ------------------ | ------ | -------------- |
| [User's trigger 1] | [3-5]  | [Brief reason] |
| [User's trigger 2] | [3-5]  | [Brief reason] |
| ...                | ...    | ...            |

**Max score = sum of all trigger points.**

Define score ranges:

- **HOT:** Top 30% of possible score — highest priority
- **WARM:** Middle range — worth reaching out
- **COLD:** Below middle — lower priority but still in ICP

Get the user's approval on the scoring system before researching.

---

## STEP 3: RESEARCH & BUILD

### Clarify Research Scope

Before starting, confirm:

- Target niche / search terms
- Number of companies to find
- Any companies to exclude or include

### Find Companies

Use web search strategically:

- `"[industry] [company type] [year]"` on Crunchbase, TechCrunch, Product Hunt
- `"[niche] startups funded"` for venture-backed companies
- G2, Capterra for SaaS categories
- Industry directories and lists
- YC, Techstars portfolio pages if relevant
- `"[niche] companies [location]"` for geo-targeted searches

### For Each Company, Research & Verify

**Company data (required for every row):**

- Company name and website (verify the URL — don't guess)
- Industry/type
- HQ location
- Employee count
- Any trigger-specific data (funding, tech stack, content presence, etc.)

**Decision-maker data (required for every row):**

- First name + last name (split for outreach tools)
- Role/title
- LinkedIn profile URL (verify it's real, not a search page)
- Email (if publicly findable)
- Any trigger-specific data (LinkedIn followers, posting activity, etc.)

**Structure: One person per row.** A company with 2 co-founders and a CMO = 3 rows with company data repeated. This is how outreach tools work — you're reaching out to people, not companies.

### Verify Triggers

For every trigger the user selected, actually verify it for each prospect. Don't guess. Don't skip. The score is only useful if the underlying data is real.

- If you can verify a trigger → award the points
- If you can't verify → don't award points, note "unverified" in the breakdown
- If a trigger is clearly NOT met → 0 points for that trigger

Put the full breakdown in the score_breakdown field like: `"LinkedIn:5 + Funding:4 + Blog:3 = 12"`

---

## STEP 4: SCORE & EXPORT

### Generate the Files

Compile all researched data into JSON, then use the bundled script:

```bash
python scripts/generate_list.py --input data.json --output-dir /path/to/output --filename "prospect-list" --hot-threshold [N] --warm-threshold [N]
```

The input JSON format:

```json
{
	"triggers": [{ "name": "Trigger Name", "points": 5, "why": "Reason this matters" }],
	"columns": [{ "header": "Column Name", "field": "field_name", "width": 20, "type": "text" }],
	"rows": [
		{
			"company_name": "Example Corp",
			"website": "https://example.com",
			"field_name": "value",
			"...": "..."
		}
	]
}
```

**Column types:** `"text"`, `"number"`, `"url"`, `"score"`

The script handles formatting, color-coding, summary sheet, scoring guide, hyperlinks, and CSV export automatically.

### Default Columns (always include)

These columns appear on every list. Add trigger-specific columns after them:

| Field             | Header          | Type   |
| ----------------- | --------------- | ------ |
| company_name      | Company Name    | text   |
| website           | Website         | url    |
| industry          | Industry / Type | text   |
| hq_location       | HQ Location     | text   |
| employee_count    | Employee Count  | number |
| prospect_score    | Prospect Score  | score  |
| score_breakdown   | Score Breakdown | text   |
| person_first_name | First Name      | text   |
| person_last_name  | Last Name       | text   |
| role              | Role / Title    | text   |
| person_linkedin   | LinkedIn        | url    |
| person_email      | Email           | text   |

Add additional columns based on the user's triggers (e.g., "YouTube Channel", "Funding Stage", "Last LinkedIn Post", "Tech Stack").

### Quality Standards

- Never fabricate data. Use "Unknown" for data you can't find.
- Verify LinkedIn URLs — must be actual profile URLs.
- Verify company websites — actually search, don't guess.
- De-duplicate — never include the same person twice.
- Score honestly — don't inflate. The whole point is prioritization.
- Every trigger column should have a real value or "Not found" — never leave blank.

### Token Efficiency

This skill involves a lot of web research. To keep token usage reasonable:

- Research in batches of 5 companies at a time
- Don't over-explain findings — just fill in the data fields
- Use the script for all formatting — don't manually build spreadsheets
- If the user wants 50+ companies, suggest splitting into two runs
