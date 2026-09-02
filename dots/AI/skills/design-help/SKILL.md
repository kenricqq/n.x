---
name: design-help
description: Shape a product's design direction through a hands-on interview grounded in product meaning, visual references, and project constraints. Use when the user wants to define a design system, visual direction, brand feel, or UI principles before implementation.
---

# Design Help

Read [article.md](article.md) before starting.

Do not implement UI. Establish design direction first.

## 1. Gather evidence

Inspect available product, design, and code context:

- `PRODUCT.md`, `DESIGN.md`, README, or product brief
- existing tokens, typography, colors, and representative screens
- references or inspiration supplied by the user
- platform, accessibility, performance, and implementation constraints

Do not ask questions answerable from existing evidence.

## 2. Interview

Ask one question at a time. For every question:

1. State relevant evidence already found.
2. Ask for one decision.
3. Give a recommended answer and why.
4. Wait for the user's response.

Resolve decisions in this order:

1. Who is this for?
2. What problem does it solve?
3. What should using it feel like?
4. What should it represent?
5. Which references capture that direction?
6. What specifically should be borrowed from each reference?
7. Which visual clichés or competitors should it avoid?
8. What typography, color, layout, imagery, and motion support the direction?
9. What accessibility, platform, and performance constraints bound the system?

Never treat adjectives such as “premium,” “bold,” or “minimal” as decisions. Translate each into observable design choices.

## 3. Produce the direction

When answers are resolved, produce:

- product meaning
- audience and usage context
- desired emotional register
- visual references and borrow/reject notes
- typography direction
- color strategy
- spacing and layout principles
- component and interaction principles
- motion principles
- accessibility constraints
- explicit anti-patterns
- unresolved decisions

Offer to persist the result as `DESIGN.md`. Write it only after user confirmation.

## Completion gate

Finish when another designer or agent could make consistent design decisions from the output without inventing missing direction.
