# RunningBehind — Building with AI

RunningBehind was built primarily through prompting — Claude Code writing Swift while I focused on product decisions, scope discipline, and shipping. This was a deliberate choice, and a different kind of practice than the Grant Management System, where I went deep on architecture and data modeling. Here, the goal was: define a narrow feature set, get to the App Store, and learn what it takes to maintain a shipped product.

## Why this approach

I'd spent months on projects where I lingered in design details — refining data models, debating inheritance vs. composition, rebuilding things to be more elegant. That's valuable work, and I'm glad I did it. But I also wanted to practice the other side: scoping tightly, shipping, and then living with the consequences.

RunningBehind was the right vehicle for that. The problem is well-defined (departure calculation for someone with time blindness), the feature set is small enough to ship as a v1, and the user — someone close to me — could give real feedback immediately.

## How the prompting worked

The workflow was iterative: I described what I wanted in terms of user behavior, not implementation. "When time passes without the user leaving, the required pace should climb and the UI should shift from green to amber to red." Claude Code wrote the Swift. I reviewed, tested in the simulator, and refined.

What I was practicing:

- **Describing intent clearly enough that the output was usable.** Vague prompts produce vague code; over time vague code produces weird bugs.
- **Recognizing at a higher level when generated code was wrong.** The compiler catches syntactic errors, but there are still conceptual and structural confusions to notice. How does confusion smell?
- **Scope discipline.** A temptation with AI-assisted coding is that everything is cheaper to build at first, so you keep adding features. It takes another kind of discipline to say no.

## What I learned

**Prompting is a kind of management, not programming.** The skill takes discretion, taste, judgement -- it takes a sense of what is possible and what is worthwhile.

**Shipping changes your relationship to the work.** Once RunningBehind was on a real device and someone was using it, the questions changed. Not "is this elegant?" but "does this actually help?" and "can they depend on it daily, when they really need it most?" 

## The user story

Someone close to me lives with time blindness. They don't struggle with *knowing* when to leave — they struggle with *feeling* the difference between "plenty of time" and "already late." I built RunningBehind to translate time into something physical: a walking pace that changes as time passes. When the number climbs from 1.3 mph to 4.9 mph, you feel that in your body in a way that "15 minutes remaining" never achieves.

They use it daily. The feedback loop — real person, real departures, real consequences — has been the most valuable part of the project.

## Current status

RunningBehind is feature-complete for v1 and in testing. The plan is to ship to the App Store once I have a support website live (this portfolio). After that, the practice shifts to maintenance: bug reports, OS updates, user feedback, and deciding what's worth adding vs. what's scope creep.
