A GenAI experiment to create an interactive animation of a ring buffer using counting semaphores and a mutex

Claude4.6, Sonnet and Qwen3-Coder-Next implementations were created.

The initial prompt was -

Hi, I need a little web demo for my systems programming class. I want to demonstrate a fixed size ring buffer that uses counting semaphores to stop the buffer from underflow or overflow. Please can you create a little animated demo that shows two counting semaphores to keep track of the number of items and number of spaces available. As an option let's have a mutex lock to ensure that if there's more than one producer or one consumer that there are no race conditions.  Please create a single html file for his interactive demo.

After creating the initial demo the model was given one round of feedback to improve the initial attempt. The feedback was a couple of sentences.

* [Claude4.6]
* [Sonnet4.6]()
* [ChatGPT]()
* [Qwen3-Coder-Next]()
