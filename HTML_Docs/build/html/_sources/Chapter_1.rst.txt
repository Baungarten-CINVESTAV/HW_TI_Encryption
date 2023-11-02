.. _Chapter_1:

==============================================
CSAW Competition: AI Hardware Attack Challenge
==============================================

-----------------------
Competition Description
-----------------------

Using generative AI (e.g. ChatGPT, Bard, or similar), you will work to insert a hardware vulnerability, such as a trojan or backdoor, into an open-source digital design of your choice (e.g. OpenTitan, Ariane, a design from OpenCores, etc.). The result must be simulatable and synthesizable, and you will need to be able to demonstrate the effects of the added security vulnerability (e.g., HW-CWE). An additional award track will be for designs which are compatible with the Efabless ChipIgnite platform (for instance, a crypto accelerator with an inserted back-door). A successful submission will need to include all the prompts and responses from the language model, a document describing both the method used for inserting the vulnerability and the method of exploiting it, and makefiles for simulating and synthesizing the design. You may instruct the AI to directly edit files or perform the edits as the AI describes. You may need to perform 'prompt injection'. Points will be awarded for subtle yet powerful exploits, e.g., those that allow system compromise from userspace, those that leak encryption keys, etc.

----------------
Judging criteria
----------------

- Usefulness of the open-source design: More popular/more broadly applicable designs are worth more.
- Method for adding the vulnerability: All prompts and logs must be kept and provided, and the more that the LLM did, the better, including changing of scripts and testbenches outside the hardware design itself.
- The severity of the vulnerability: E.g., theoretical CVSS score.
- The stealth of the vulnerability: How well does it hide in the overall design? Extra points for showing that it can hide from existing security scanners/functional tests/test benches.
- The vulnerability demonstration: It must be possible to observe the claimed impact of your vulnerability (e.g., via simulation).
- All entries must be completely open-source (using Apache license or compatible) but need not fully rely on open-source platforms (e.g., you can use ModelSim, Vitis, Synopsys, etc.).

More information about the CSAW "AI Hardware Attack Challenge" can be found at the following links:

- https://www.csaw.io/ai-hardware-attack-challenge
- https://docs.google.com/document/d/1rdY2FmQ4RNywyKR_gQqXOXsVIvZ6ZU2D74iBBj8ZYRk/edit?pli=1
- https://gist.github.com/JBlocklove/a2a8b37b60a02a8ff70e40ef3531cba1
