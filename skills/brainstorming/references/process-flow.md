# Brainstorming Process Flow

Moved verbatim from `SKILL.md` (private-ai-harness 5.0.0) to keep the skill
under the 20,000-byte limit Claude Code applies when it re-attaches skills
after compaction. Read it at the step that points here.

```dot
digraph brainstorming {
    "Explore project context" [shape=box];
    "Everything in request?" [shape=diamond];
    "Do it, say what you did" [shape=doublecircle];
    "Look, then first message:\necho+findings+question" [shape=box];
    "Converse + play back\n(offer recon/spike/visuals)" [shape=box];
    "Size the work" [shape=diamond];
    "Short design doc,\nuser approves" [shape=box];
    "Propose 2-3 approaches" [shape=box];
    "Present design sections" [shape=box];
    "User approves design?" [shape=diamond];
    "Write design doc" [shape=box];
    "Spec self-review\n(fix inline)" [shape=box];
    "Run spec-quality-gate" [shape=box];
    "Gate passes?" [shape=diamond];
    "Builder check\n(answer/settle/ask once)" [shape=box];
    "User reviews spec?" [shape=diamond];
    "Invoke writing-plans skill" [shape=doublecircle];

    "Explore project context" -> "Everything in request?";
    "Everything in request?" -> "Do it, say what you did" [label="yes"];
    "Everything in request?" -> "Look, then first message:\necho+findings+question" [label="no"];
    "Look, then first message:\necho+findings+question" -> "Converse + play back\n(offer recon/spike/visuals)";
    "Converse + play back\n(offer recon/spike/visuals)" -> "Size the work";
    "Size the work" -> "Do it, say what you did" [label="quick, clear"];
    "Size the work" -> "Short design doc,\nuser approves" [label="small change"];
    "Short design doc,\nuser approves" -> "Invoke writing-plans skill";
    "Size the work" -> "Propose 2-3 approaches" [label="feature/project"];
    "Propose 2-3 approaches" -> "Present design sections";
    "Present design sections" -> "User approves design?";
    "User approves design?" -> "Present design sections" [label="no, revise"];
    "User approves design?" -> "Write design doc" [label="yes"];
    "Write design doc" -> "Spec self-review\n(fix inline)";
    "Spec self-review\n(fix inline)" -> "Run spec-quality-gate";
    "Run spec-quality-gate" -> "Gate passes?";
    "Gate passes?" -> "Write design doc" [label="FAIL — fix spec"];
    "Gate passes?" -> "Builder check\n(answer/settle/ask once)" [label="PASS"];
    "Builder check\n(answer/settle/ask once)" -> "User reviews spec?";
    "User reviews spec?" -> "Write design doc" [label="changes requested"];
    "User reviews spec?" -> "Invoke writing-plans skill" [label="approved"];
}
```
