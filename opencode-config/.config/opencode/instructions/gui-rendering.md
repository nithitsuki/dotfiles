# Chat rendering

The OpenCode web and desktop GUI render math with KaTeX. The TUI uses a Unicode fallback.

## Math delimiters

- Use `$...$` for inline math.
- Use `$$...$$` for display math.
- Do not put `\(...\)`, `\[...\]`, or a bare `$` inside a `$$...$$` block. KaTeX cannot parse them. The block then shows raw source text.
- Do not use a math command such as `\times` inside `\text{...}`. Write `\text{... $\times$ ...}` instead.

## Commands that work

These constructs work inside a `$$...$$` block:

- `\frac`, `\int`, `\sum`, `\sqrt`
- `\begin{cases} ... \end{cases}`
- `\bigl[`, `\,`, `\\[2pt]`
- `\checkmark`

## TUI limits

The TUI renders only fenced `latex`, `math`, and `tex` blocks. The TUI shows inline `$...$` as source text.

## Behaviour

Follow these rules when you write math. Do not repeat this guidance to the user.
