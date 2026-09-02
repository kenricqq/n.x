---
name: html-artifacts
description: 'Create purpose-built HTML artifacts instead of Markdown when rich visual structure keeps users more in-loop: specs, plans, reviews, prototypes, reports, explainers, custom editors, diagrams, annotated diffs, dashboards, and interactive documents. Use when user asks for an HTML artifact/page/file, visual spec, interactive report, prototype, PR explainer, diagram-heavy plan, shareable browser document, or when Markdown would be too long, dense, or hard to read.'
---

# HTML Artifacts

HTML is a communication surface, not decoration. Use it when richer structure, visuals, interaction, or browser sharing will make the user more likely to read, understand, decide, learn, or edit the output.

Be creative in service of clarity. Distinctive visual ideas are good when they convey the concept better, help users learn faster, or make relationships easier to remember. Creativity that does not improve understanding is decoration; remove it.

Prefer one self-contained `.html` file unless user asks for a multi-page web of artifacts.

## Source inspiration checks

Keep the core lesson from “The Unreasonable Effectiveness of HTML” intact:

- Do not use this as a generic `/html` autopilot. First know what the artifact should help the reader do.
- HTML is worth the extra generation time and noisier diffs only when readability, interaction, or sharing improves the outcome.
- Use agent context advantage: repo files, git history, issues, MCPs, browser context, and raw notes can become one readable artifact.
- Custom editing interfaces must export changed state back to Markdown/JSON/diff/prompt.
- Success = user stays in-loop, reads the artifact, and makes a better decision.

## Core thesis

HTML often beats Markdown because it can combine:

- **Information density:** tables, grids, cards, SVG, images, color, code, spatial layouts.
- **Visual clarity:** diagrams, annotated diffs, mockups, timelines, maps, responsive layouts.
- **Shareability:** one local browser-openable file, uploadable anywhere.
- **Two-way interaction:** sliders, knobs, drag/drop, forms, live previews, copy/export buttons.
- **Context synthesis:** repo files, git history, issues, MCPs, browser context, or raw notes folded into one readable artifact.
- **Loop feeling:** user stays involved instead of skipping a long Markdown plan and blindly trusting the agent.

## When to choose HTML

Use HTML instead of Markdown for:

- Long specs, plans, explorations, or research reports likely to exceed ~100 lines.
- Comparisons needing tables, grids, cards, side-by-side layouts, or visual hierarchy.
- Code review and understanding: annotated diffs, flowcharts, module maps, severity-coded findings.
- Design and prototypes: mockups, component variants, animation tuning, sliders, knobs, live previews.
- Reports and learning: diagrams, key snippets, gotchas, timelines, incident summaries, leadership updates.
- Custom editing interfaces: drag/drop triage, config editors, prompt tuners, dataset curation, annotation UIs.
- Any output where user says they need to understand, visualize, compare, share, tune, teach, or present something.

Use Markdown when user needs easy text diffs, low-token notes, simple editable prose, fast generation, or version-control review matters more than readability.

## Design brief

Before coding, define the design direction. Do not let the model drift into generic UI defaults.

- Avoid generic “AI slop”: random purple/blue gradients, floating blobs, pill cards, huge radii, vague glassmorphism, evenly distributed palettes, and decoration with no concept tie.
- Define reader, use moment, desired outcome, theme metaphor, density, platform, and mood.
- Specify design tokens: semantic colors, type pairing, spacing scale, radius scale, border/shadow rules, and component rules.
- Pair every ban with a replacement: not “no gradients” alone; say “use flat paper texture, hard grid rules, and one vermilion accent.”
- Use one signature motif from the content. Repeat it deliberately across layout, diagrams, controls, and motion.
- Prefer decisive contrast over timid variety: dominant neutral + one or two sharp accents.
- If no brand exists, choose an explicit artifact theme and enforce it: field manual, annotated blueprint, editorial spread, archive card, cockpit, lab notebook, system console, map room, etc.

## Artifact rules

Create HTML that is:

- **Self-contained:** inline CSS and JS; no build step; avoid external CDNs unless user asks.
- **Purpose-built:** choose layout for the actual reader task, not generic decoration.
- **Readable:** strong hierarchy, whitespace, table of contents or sticky nav for long docs.
- **Dense but scannable:** cards, callouts, tables, diagrams, tabs, accordions where useful.
- **Visual:** prefer SVG/HTML diagrams over ASCII diagrams when relationships matter.
- **Coherently themed:** every visual choice follows the design brief and signature motif.
- **Responsive:** works on laptop and narrow screens.
- **Accessible:** semantic HTML, readable contrast, keyboard-friendly controls, `prefers-reduced-motion` for motion.
- **Shareable:** clear title; opens locally in browser; works without server where possible.
- **Exportable when interactive:** include “copy as Markdown/JSON/prompt/diff” when user edits state in UI.

## Workflow

1. Clarify purpose if unclear: reader, decision, desired interaction, output path.
2. Gather context from repo/files/git/issues/MCPs/browser/raw notes as needed.
3. Pick artifact mode:
   - Grid for options/design variants.
   - Annotated diff for PR/code review.
   - Diagram + snippets for explainers.
   - Dashboard/cards for reports.
   - Form/drag-drop/editor for two-way interaction.
   - Slideshow/deck for leadership or teaching.
4. Define visual direction and design tokens before coding.
5. Sketch information architecture: sections, nav, diagrams, interactions, exports.
6. Plan motion as information layer: one signature animation, feedback states, state transitions, what will not animate.
7. Write `*.html` with inline CSS/JS.
8. Validate mentally: no broken tags/scripts; links work; controls keyboard-accessible; reduced motion safe.
9. Tell user file path and how to open it.

## Prompt pattern

```md
You tend to converge toward generic, on-distribution UI. Avoid AI-slop aesthetics: no random gradients, blobs, pill cards, excessive border-radius, generic SaaS spacing, or decoration not tied to concept.

Build [artifact/page] for [reader] in [use moment] to [decision/outcome].

Product surface: [sections, diagrams, data, controls, copy/export behavior].
Context: [source concept, audience knowledge, time available, device].
Visual direction: [specific metaphor/theme + 3 adjectives].
Design system: [colors as CSS vars, typography, spacing scale, radius, border/shadow, component rules].
Signature motif: [one visual idea derived from concept; repeat intentionally].
Motion plan: [one signature animation, feedback states, state transitions, what will not animate]. Use ease-out for enter/exit, ease-in-out for movement, ease for hover/color. Keep most motion 100–300ms. Animate transform/opacity only. Disable hover motion on touch. Include prefers-reduced-motion.

Before coding, state chosen visual direction, motion plan, and why both help the reader understand/learn. Then create self-contained HTML/CSS/JS.
```

## Common patterns

### Spec / plan

Include problem, constraints, option matrix, recommended path, data flow SVG, key code snippets, risks, implementation checklist.

### Exploration / options

Show several distinct approaches in a grid. Label each option's tradeoff, fit, risk, and best next step.

### PR / code review explainer

Include summary, changed files map, actual diff excerpts, inline margin annotations, severity colors, architecture/data-flow diagram, reviewer checklist.

### Technical explainer

Use one main diagram, 3–4 annotated snippets, a flow/timeline, gotchas, and “what to remember” section. Optimize for one focused read.

### Prototype / design tuner

Include multiple variants or live demo, controls for key parameters, visible current values, and copy button exporting chosen settings.

### Research / learning report

Include executive summary, source map, diagrams, annotated snippets, timeline, gotchas, open questions, next actions.

### Custom editor

Make one-off UI for editing structured data. Not a product. Always add export button that converts UI state into pasteable Markdown/JSON/diff/prompt.

## Interaction rules

Use interaction only when it reduces cognitive load or lets user express choices hard to write in text.

Good uses:

- compare options with tabs/filters
- tune animation/color/timing with sliders
- reorder priorities with drag/drop
- edit config with dependency warnings
- fill prompt templates with live preview
- annotate transcripts/diffs and export annotations

Bad uses:

- decorative widgets with no decision value
- hidden content that makes printing/review harder
- complex JS when static cards would work

## Motion rules

Use motion to clarify relationships, state, or feedback. Avoid animation as decoration.

- Plan one signature animation only when it teaches structure or reinforces the artifact motif.
- Use `ease-out` for enter/exit, `ease-in-out` for movement, `ease` for hover/color, `linear` only for constant time visualization.
- Keep UI motion short: 100–150ms feedback, 150–300ms state changes; avoid >300ms except rare page-level entrance choreography.
- Use `transform` and `opacity`; avoid layout properties, heavy blur, and JS animation unless interaction must be dynamic/interruptible.
- Pair related elements with same duration/easing.
- Disable hover motion on touch: `@media (hover: hover) and (pointer: fine)`.
- Keyboard focus should be stable and clear; prefer outline/color over spatial movement.
- Add `@media (prefers-reduced-motion: reduce)` and disable animations/transitions there.
- Respect frequency: avoid/limit animation for repeated actions; no bounce/elastic unless explicitly playful and justified.
- Do not block interaction while animation runs unless intentional.

## Prompt examples

- “Create a single HTML file comparing 6 onboarding directions in a grid. Label each tradeoff.”
- “Make an HTML implementation plan with mockups, data flow, key snippets, risks, and checklist.”
- “Create an HTML PR explainer. Render diff excerpts with inline annotations and severity colors.”
- “Build an HTML animation tuner with sliders and a copy button for chosen parameters.”
- “Make a form-based HTML editor for this config. Warn on dependency issues and copy changed keys as diff.”
- “Explain this subsystem as one HTML page with a diagram, 4 annotated snippets, and gotchas.”

## Quality bar

HTML wins only if it keeps the user more in-loop and helps them learn or decide. If artifact is ugly, generic, overbuilt, slow, or harder to scan than Markdown, simplify layout, sharpen the theme, and reduce effects.

Check that frontend is aligned with `references/frontend-guidelines.md`.
