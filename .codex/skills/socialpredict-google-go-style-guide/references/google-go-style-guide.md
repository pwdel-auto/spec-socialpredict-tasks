# Google Go Style Guide

Source: https://google.github.io/styleguide/go/guide
Local copy purpose: targeted repo-local lookup for style questions
Source type: Google Go Style Guide, normative and canonical
Normalized for local search: line breaks and bullets adjusted for grep-friendly context

## Style principles

There are a few overarching principles that summarize how to think about
writing readable Go code. The following attributes of readable code are listed
in order of importance:

1. Clarity: the code's purpose and rationale is clear to the reader.
2. Simplicity: the code accomplishes its goal in the simplest way possible.
3. Concision: the code has a high signal-to-noise ratio.
4. Maintainability: the code is written such that it can be easily maintained.
5. Consistency: the code is consistent with the broader Google codebase.

### Clarity

The core goal of readability is to produce code that is clear to the reader.
Clarity is primarily achieved with effective naming, helpful commentary, and
efficient code organization.

Clarity is to be viewed through the lens of the reader, not the author. It is
more important that code be easy to read than easy to write.

Clarity in code has two distinct facets:

- What is the code actually doing?
- Why is the code doing what it does?

#### What is the code actually doing?

Go is designed so it should be relatively straightforward to see what the code
is doing. In cases of uncertainty, or where a reader may require prior
knowledge to understand the code, invest time to make the purpose clearer for
future readers.

Examples of ways to improve clarity:

- Use more descriptive variable names.
- Add additional commentary.
- Break up code with whitespace and comments.
- Refactor code into separate functions or methods to make it more modular.

There is no one-size-fits-all approach, but it is important to prioritize
clarity when developing Go code.

#### Why is the code doing what it does?

The code's rationale is often sufficiently communicated by the names of
variables, functions, methods, or packages. Where it is not, add commentary.

The "why" is especially important when the code contains nuances that a reader
may not be familiar with, such as:

- A nuance in the language, such as a closure capturing a loop variable.
- A nuance of business logic, such as an access control check that
  distinguishes between the real user and an impersonating user.

An API might require care to use correctly. Code may be intricate for
performance reasons, or a sequence of mathematical operations may use type
conversions in an unexpected way. In these cases, commentary and documentation
should explain the nuance so future maintainers can avoid mistakes.

Attempts to provide clarity can also obscure the code's purpose by adding
clutter, restating what the code already says, contradicting the code, or
adding maintenance burden. Allow the code to speak for itself rather than
adding redundant comments.

It is often better for comments to explain why something is done, not what the
code is doing.

The Google codebase is largely uniform and consistent. Code that stands out may
be doing so for a good reason, often performance. Maintaining that property
helps readers see where they should focus their attention.

### Simplicity

Go code should be simple for those using, reading, and maintaining it.

Go code should be written in the simplest way that accomplishes its goals, both
in behavior and performance. Within the Google Go codebase, simple code:

- Is easy to read from top to bottom.
- Does not assume that the reader already knows what it is doing.
- Does not assume that the reader can memorize all preceding code.
- Does not have unnecessary levels of abstraction.
- Does not have names that call attention to something mundane.
- Makes the propagation of values and decisions clear to the reader.
- Has comments that explain why, not what, the code is doing.
- Has documentation that stands on its own.
- Has useful errors and useful test failures.
- May often be mutually exclusive with clever code.

Tradeoffs can arise between code simplicity and API usage simplicity. It may be
worth making code more complex so the API is easier to call correctly, or
leaving some extra work to the API user so the implementation remains simple
and easy to understand.

When code needs complexity, add it deliberately. Complexity may be justified
for performance or when serving multiple disparate customers. When it is
justified, accompany it with documentation, tests, and examples so clients and
future maintainers can understand and navigate it safely.

If code turns out to be very complex when its purpose should be simple, that is
often a signal to revisit the implementation and look for a simpler approach.

#### Least mechanism

Where there are several ways to express the same idea, prefer the one that uses
the most standard tools. Sophisticated machinery often exists, but should not
be employed without reason. It is easier to add complexity later than to remove
unnecessary complexity that already exists.

1. Aim to use a core language construct when sufficient.
2. If that is not enough, look for a standard library tool.
3. Only then consider a core library or creating a new dependency.

Examples from the guide:

- Prefer overriding a bound flag value directly in tests instead of using
  `flag.Set`, unless the CLI itself is under test.
- Prefer a boolean-valued map for set membership unless more complex set
  operations are truly required.

### Concision

Concise Go code has a high signal-to-noise ratio. It is easy to discern the
relevant details, and the naming and structure guide the reader through them.

Things that can get in the way of surfacing the most salient details:

- Repetitive code
- Extraneous syntax
- Opaque names
- Unnecessary abstraction
- Whitespace

Repetitive code can obscure the differences between nearly identical sections.
Table-driven testing is a common way to factor out common code while keeping
important details visible.

Common idioms also help signal important behavior. Standard error handling
blocks are easy to scan because readers already recognize the pattern:

```go
if err := doSomething(); err != nil {
    // ...
}
```

If code looks very similar to a common idiom but is subtly different, it can be
worth "boosting" the signal with a comment so the reader notices the difference.

### Maintainability

Code is edited many more times than it is written. Readable code needs to make
sense to the future programmer who must modify it correctly. Clarity is key.

Maintainable code:

- Is easy for a future programmer to modify correctly.
- Has APIs that are structured so they can grow gracefully.
- Is clear about its assumptions.
- Chooses abstractions that map to the structure of the problem, not the
  structure of the code.
- Avoids unnecessary coupling and unused features.
- Has a comprehensive test suite with clear, actionable diagnostics.

When using abstractions like interfaces and types that remove information from
the usage site, ensure that they provide sufficient benefit. Interfaces are a
powerful tool, but they come with a cost because a maintainer may need to
understand the underlying implementation to use them correctly.

Maintainable code also avoids hiding important details in easy-to-miss places.
The guide calls out examples where a single character such as `=` versus `:=`
or a negation in the middle of an expression can be too easy to overlook.

Predictable names are another maintainability feature. A user of a package or a
maintainer of code should be able to predict the name of a variable, method, or
function in a given context. Function parameters and receiver names for the
same concept should typically share the same name.

Maintainable code minimizes both implicit and explicit dependencies. Avoid
depending on internal or undocumented behavior when possible.

When considering structure and style, think through how the code may evolve
over time. A slightly more complicated design can be worth it if it enables
safer future changes.

### Consistency

Consistent code looks, feels, and behaves like similar code throughout the
broader codebase, within a team or package, and even within a single file.

Consistency concerns do not override the principles above, but if a tie must be
broken, it is often beneficial to break it in favor of consistency.

Consistency within a package is often the most immediately important level of
consistency. However, local consistency should not override documented style
principles or global consistency.

## Core guidelines

These guidelines collect the most important aspects of Go style that all Go
code is expected to follow.

### Formatting

All Go source files must conform to the format output by `gofmt`. Generated
code should generally also be formatted.

### MixedCaps

Go source code uses `MixedCaps` or `mixedCaps` rather than underscores when
writing multi-word names.

This applies even when it breaks conventions in other languages. For example, a
constant is `MaxLength` if exported and `maxLength` if unexported.

Local variables are considered unexported for the purpose of choosing initial
capitalization.

### Line length

There is no fixed line length for Go source code. If a line feels too long,
prefer refactoring instead of splitting it. If it is already as short as
practical, allow it to remain long.

Do not split a line:

- Before an indentation change, such as a function declaration or conditional.
- To make a long string, such as a URL, fit into multiple shorter lines.

### Naming

Naming is more art than science. In Go, names tend to be somewhat shorter than
in many other languages, but the same general guidelines apply.

Names should:

- Not feel repetitive when they are used.
- Take the context into consideration.
- Not repeat concepts that are already clear.

The guide points to the Decisions document for more specific naming guidance.

### Local consistency

Where the style guide has nothing to say about a particular point of style,
authors are free to choose the style they prefer unless nearby code within the
same file, package, team, or project directory has already taken a consistent
stance on the issue.

Examples of valid local style considerations:

- Use of `%s` or `%v` for formatted printing of errors.
- Usage of buffered channels in lieu of mutexes.

Examples of invalid local style considerations:

- Line length restrictions for code.
- Use of assertion-based testing libraries.

If local style disagrees with the style guide but the readability impact is
limited to one file, it will generally be surfaced in code review and may be
tracked as a follow-up rather than fixed in the current change.

If a change would worsen an existing style deviation, expose it in more API
surfaces, expand the number of files carrying the deviation, or introduce an
actual bug, then local consistency is no longer a valid justification for
violating the style guide for new code.
