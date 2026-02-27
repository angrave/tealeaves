A GenAI experiment to create an interactive animation of a ring buffer using counting semaphores and a mutex. Claude Opus and  Soneet, ChatGPT and Qwen3-Coder-Next implementations were created.

![Screenshot of Ring Buffer Simulator created using Opus 4.6](https://angrave.github.io/tealeaves/ring-buffer-genai-viz/RingBuffer-Opus.png)


The initial prompt was deliberately simple. I made no attempt to craft a careful specification or discuss the intended pedagogical insights.

<tt>Hi, I need a little web demo for my systems programming class. I want to demonstrate a fixed size ring buffer that uses counting semaphores to stop the buffer from underflow or overflow. Please can you create a little animated demo that shows two counting semaphores to keep track of the number of items and number of spaces available. As an option let's have a mutex lock to ensure that if there's more than one producer or one consumer that there are no race conditions.  Please create a single html file for his interactive demo.</tt>

After creating the initial demo, except for Sonnet because it was good enough, most models were given one round of feedback to improve the initial attempt. The feedback was a couple of sentences - to represent a typical 15 minutes of my time available to create a quick lecture demo rather a publication-quality level demonstration. None of them were perfect (especially in terms of showcasing multiple producers or consumers and the utility of  the lock). Overall the Opus demo was the best, though the mutexlock would have been better labeled as unlocked and locked rather than "1" or "0" and the brightness contrast was insufficient in the original version. Qwen3-Coder-Next version deadlocked initially but worked sufficiently after pointing this out. Qwen also asked a few useful design questions before creating code. My least favorite and the least useful was the ChatGPT version.

* Opus 4.6 (Medium effort) [live demo](https://angrave.github.io/tealeaves/ring-buffer-genai-viz/ringbuffer-opus4_6.html) 
* Sonnet 4.6 [live demo](https://angrave.github.io/tealeaves/ring-buffer-genai-viz/ringbuffer-Sonnet4-6.html)
* ChatGPT 5.2 Instant [live demo](https://angrave.github.io/tealeaves/ring-buffer-genai-viz/ringbuffer-chatgpt5_2instant.html) (copy-pasting into ChatGPT website)
* Qwen3-Coder-Next [live demo](https://angrave.github.io/tealeaves/ring-buffer-genai-viz/ringbuffer-Qwen3-Coder-next.html) (fp8 running on a 128GB Spark)

The source code is [here](https://github.com/angrave/tealeaves/edit/gh-pages/ring-buffer-genai-viz/).

None of the html content was WCAG compliant, so later, in a new session I asked each model to fix their code. This was more challenging than the original prompt. All models took longer than expected (>10 minutes) to fulfill this request. I have not performed a WCAG review of the output.

<tt>Make a new file postfix '-wcag.html' of the existing file. Take the current html in this directory and ensure it is WCAG 2.1 AA Compliant and the web application is accessible with a screen reader. </tt>

Note to self - In the future I should include an accessibility requirement in the original prompt.

* [Opus 4.6[](](https://angrave.github.io/tealeaves/ring-buffer-genai-viz/ringbuffer-opus4_6-wcag.html) (Medium effort).
* [Sonnet 4.6](https://angrave.github.io/tealeaves/ring-buffer-genai-viz/ringbuffer-Sonnet4-6-wcag.html)
* [ChatGPT 5.2 Instant](https://angrave.github.io/tealeaves/ring-buffer-genai-viz/ringbuffer-chatgpt5_2instant-wcag.html)
* [Qwen3-Coder-Next](https://angrave.github.io/tealeaves/ring-buffer-genai-viz/ringbuffer-Qwen3-Coder-next-wcag.html)
