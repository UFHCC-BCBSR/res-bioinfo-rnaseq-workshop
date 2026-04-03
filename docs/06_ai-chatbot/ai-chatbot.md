# AI Chatbot Tips for Bioinformatics

AI chatbots are genuinely useful tools for bioinformatics work, and we encourage you to use them throughout this workshop. This page covers which tools to use, what they are good at, and where to be careful.

## Which Tool to Use

For UF affiliates, we recommend using [UF's NaviGator AI](https://chat.ai.it.ufl.edu/), which is hosted by the University of Florida and keeps your data within UF's systems. When prompted to select a model, use **claude-sonnet-4-6** — it is currently the strongest general-purpose model available on the platform for tasks like coding, explanation, and debugging.

## What AI Chatbots Are Good At

**Use them freely for:**

- **Explaining concepts** — ask it to explain what TMM normalization is, what a design matrix does, or why we use empirical Bayes moderation. It is excellent at this.
- **Debugging error messages** — paste in an R error or a SLURM job failure and ask what it means. This is one of the most practical uses in a workshop setting.
- **Writing boilerplate code** — SLURM script headers, R package installation, ggplot2 syntax. It is very reliable for standard, well-documented patterns.
- **Rephrasing documentation** — if a help page or paper is hard to understand, ask the chatbot to explain it in plain language.
- **Suggesting next steps** — if you are stuck and not sure what to try, describing your problem to a chatbot often surfaces approaches you hadn't considered.

## Where to Be Careful

**Always double-check:**

- **Cluster-specific details** — file paths, module names, partition names, and HiPerGator-specific commands may be outdated or just wrong. Always verify against the [UF Research Computing documentation](https://docs.rc.ufl.edu/).
- **R code before running it** — read through any code it generates before executing it, especially if it involves writing or deleting files.
- **Statistical interpretations** — it can sound confident while being subtly incorrect about the details of a statistical method. Use it as a starting point, not a final answer.
- **Package versions and function arguments** — R packages change over time and the chatbot's knowledge has a cutoff date. When in doubt, check the function documentation with `?functionname`.

**Do not rely on it for:**

- **Biological interpretation of your results** — it has no knowledge of your specific experiment, organism, or research question.
- **Citations and paper details** — AI chatbots frequently hallucinate paper titles, authors, and findings. Always verify any reference it gives you independently.
- **Anything recently published** — its knowledge has a cutoff date and it will not know about methods or tools released after that point.

## A Good Habit

When you use a chatbot to help solve a problem, take a moment to make sure you understand what it gave you before moving on. The goal is to use it as a learning tool, not just a way to get code that you run without understanding. If it gives you something that works but you are not sure why, ask it to explain.
