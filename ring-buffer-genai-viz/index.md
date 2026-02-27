A GenAI experiment to create an interactive animation of a ring buffer using counting semaphores and a mutex. Claude Opus and  Soneet, ChatGPT and Qwen3-Coder-Next implementations were created.

![Screenshot of Ring Buffer Simulator created using Opus 4.6](https://angrave.github.io/tealeaves/ring-buffer-genai-viz/RingBuffer-Opus.png)


The initial prompt was deliberately simple. I made no attempt to craft a careful specification or discuss the intended pedagogical insights.

<tt>Hi, I need a little web demo for my systems programming class. I want to demonstrate a fixed size ring buffer that uses counting semaphores to stop the buffer from underflow or overflow. Please can you create a little animated demo that shows two counting semaphores to keep track of the number of items and number of spaces available. As an option let's have a mutex lock to ensure that if there's more than one producer or one consumer that there are no race conditions.  Please create a single html file for his interactive demo.</tt>

After creating the initial demo, except for Sonnet because it was good enough, most models were given one round of feedback to improve the initial attempt. The feedback was a couple of sentences - to represent a typical 15 minutes of my time available to create a quick lecture demo rather a publication-quality level demonstration. None of them were perfect (especially in terms of showcasing multiple producers or consumers and the utility of  the lock). Overall the Opus demo was the best, though the mutex lock would have been better labeled as unlocked and locked rather than "1" or "0" and the brightness contrast was insufficient in the original version. Qwen3-Coder-Next version deadlocked initially but worked sufficiently after pointing this out. Qwen also asked a few useful design questions before creating code. My least favorite and the least useful was the ChatGPT version.

* Opus 4.6 (Medium effort):  [live demo](https://angrave.github.io/tealeaves/ring-buffer-genai-viz/ringbuffer-opus4_6.html) 
* Sonnet 4.6: [live demo](https://angrave.github.io/tealeaves/ring-buffer-genai-viz/ringbuffer-Sonnet4-6.html)
* ChatGPT 5.2 Instant: [live demo](https://angrave.github.io/tealeaves/ring-buffer-genai-viz/ringbuffer-chatgpt5_2instant.html) (copy-pasting into ChatGPT website)
* Qwen3-Coder-Next: [live demo](https://angrave.github.io/tealeaves/ring-buffer-genai-viz/ringbuffer-Qwen3-Coder-next.html) (fp8 running on a 128GB Spark)

None of the html content was WCAG compliant, so later, in a new session I asked each model to fix their code. This was more challenging than the original prompt. I have not performed a WCAG review of the output.

<tt>Make a new file postfix '-wcag.html' of the existing file. Take the current html in this directory and ensure it is WCAG 2.1 AA Compliant and the web application is accessible with a screen reader. </tt>

Note to self - In the future I should include an accessibility requirement in the original prompt.

* Opus 4.6 (Medium effort): [Live Demo](https://angrave.github.io/tealeaves/ring-buffer-genai-viz/ringbuffer-opus4_6-wcag.html)
* Sonnet 4.6: [Live Demo](https://angrave.github.io/tealeaves/ring-buffer-genai-viz/ringbuffer-Sonnet4-6-wcag.html)
* ChatGPT 5.2 Instant: [Live Demo](https://angrave.github.io/tealeaves/ring-buffer-genai-viz/ringbuffer-chatgpt5_2instant-wcag.html)
* Qwen3-Coder-Next: [Live Demo](https://angrave.github.io/tealeaves/ring-buffer-genai-viz/ringbuffer-Qwen3-Coder-next-wcag.html)

This commentary and source code for all of these demos is published on [GitHub](https://github.com/angrave/tealeaves/edit/gh-pages/ring-buffer-genai-viz/).

The number of accessibility changes were significant. I'm not qualified to perform a full review of all of these changes but it is interesting to at least see the summary of these models.

Sonnet changes (17 minutes of processing!) -
<tt>
WCAG 2.1 AA Changes Applied

  Color Contrast Fixes

  All text colors that failed the 4.5:1 ratio for normal/small text were replaced:
  - #475569 → #94a3b8 (panel titles, descriptions, labels, comments, stats)
  - #334155 → #64748b (ring indicator, log timestamps, op hints, formula text)
  - #64748b → #94a3b8 (subtitle, legend, stat labels where used for small text)
  - Form field borders: #334155 → #7a8fa8 (meets 3:1 non-text contrast)

  Focus & Motion

  - :focus-visible with outline: 3px solid #a78bfa on all interactive elements (buttons, selects, range inputs, checkboxes)
  - @media (prefers-reduced-motion: reduce) block disables all animations and transitions for users who prefer it
  - .code-line.dimmed opacity: 0.22 → 0.55 (inactive mutex lines are now readable)

  Screen Reader Support

  - Skip link (Skip to main content) as first body element
  - <header>, <main id="main-content">, <section> landmarks throughout
  - <h2> headings for all panel titles (semantic structure for navigation)
  - for= attributes on all <label> elements (form field association)
  - role="log" aria-live="polite" on the operation log
  - role="progressbar" hidden element for the fill bar with aria-valuenow/min/max
  - role="status" aria-live="polite" on blocked thread lists and status bar
  - aria-pressed on the Auto-Demo toggle button
  - aria-hidden="true" on all decorative emoji, arrows, token dots, pointer rows, ring indicator
  - Hidden live-status spans inside semaphore widgets that update when values change
  - #ariaAnnounce hidden live region that announces each pseudocode step as it executes ("Executing: sem_wait(spaces)" / "Blocked at:
  sem_wait(spaces)")
  - Cell aria-label dynamically updated with state + pointer info (e.g. "Slot 3: filled with value 5, head pointer here")
</tt>

Opus required 2 minutes. Summary of changes-
<tt>
 Structure & Semantics
  - Added role="main", <section> elements with aria-label, and heading hierarchy (<h2 class="sr-only">) for screen reader navigation
  - Skip-to-content link (Skip to controls) for keyboard users

  Screen Reader Support
  - aria-live="assertive" announcement region for state changes (produce, consume, blocked, reset)
  - aria-live="polite" on semaphore values and log region (role="log")
  - Canvas has role="img" with a dynamically updated aria-label describing buffer state, filled slots, and pointer positions
  - aria-current="step" on the active pseudocode line
  - aria-pressed toggle state on the Auto button

  Keyboard Navigation
  - Visible :focus-visible outlines (3px solid yellow) on all interactive elements (WCAG 2.4.7)
  - Keyboard shortcuts: P=Produce, C=Consume, R=Reset, A=Auto
  - Log area is focusable (tabindex="0") for scrolling

  Color Contrast
  - Brightened muted text colors (#888 -> #aaa/#bbb, #666 -> #999, #8b949e -> #9ca5b0) to meet 4.5:1 ratio against dark backgrounds
  - Increased select border contrast (#333 -> #555)

  Motion & Animations
  - @media (prefers-reduced-motion: reduce) disables pulse/blink CSS animations and canvas animation loop
  - Canvas blocked banner uses static opacity when reduced motion is preferred

  Form Labels
  - Proper <label> elements for speed slider, buffer size select, and mutex checkbox
  - aria-describedby on mutex checkbox for extra context
  - aria-valuetext on speed slider updated dynamically
</tt>
Qwen3-Coder-Next (5 minutes processing) summary -
<tt>
- ARIA labels on all interactive elements (buttons, inputs, semaphores, buffer slots)
- aria-live regions for dynamic content updates
- Keyboard navigation (Tab focus, arrow keys for range slider)
- Focus management with visible outlines
- Screen reader announcements for simulation events
- Semantic HTML with proper roles and labels
- High contrast for status indicators
</tt>

I didn't keep a copy of ChatGPT's summary.
