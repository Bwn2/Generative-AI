The repository is a small Jac-language project (files with `.jac`) focused on a Farmer's Companion demo.

Key things for an AI coding agent to know:

- Big picture
  - Language/runtime: Jac (see `.jac` files at repo root: `main.jac`, `first.jac`) with small helper in `crop_advice` that imports a by-LLM model.
  - Purpose: interactive CLI-style crop yield estimator and an LLM-backed `crop_advice` function. The code is intended to run as scripts with `with entry { ... }` blocks.

- Important files
  - `main.jac` — user-facing CLI demo: `hello_farmer`, `base_yield`, `yield_estimate` and interactive `with entry { ... }` blocks.
  - `first.jac` — tiny example showing `with entry` usage.
  - `crop_advice` — declares an LLM-backed function: `def crop_advice(...) by llm()` that imports `byllm.llm.Model` and configures `Model(model_name="gemini/gemini-2.5-flash")`.

- Project-specific conventions and patterns
  - Interactive scripts use `with entry { ... }` as the program entrypoint — preserve these blocks when refactoring or extracting logic to keep CLI behavior unchanged.
  - Lowercasing inputs before comparisons: `crop.lower()` and `fert.lower()` are used widely — follow this pattern for case-insensitive matches.
  - LLM integration is declared inline using `by llm()` (see `crop_advice`) — when changing LLM usage, update the import and `Model(...)` instantiation accordingly.

- How to run & developer workflows (discoverable hints)
  - There is no explicit build system. Treat `.jac` files as scripts run by the Jac runtime/tooling you use locally. Example local steps (adjust to your Jac install): run `jac main.jac` or use your Jac-compatible runner to execute files containing `with entry`.
  - A Python virtualenv exists at `testenv/` and `venv/`; these are only for optional Python tooling and do not affect Jac scripts.

- Integration & dependencies
  - `crop_advice` depends on `byllm.llm.Model` and a model name `gemini/gemini-2.5-flash`. Keep secrets/config out of source; if adding keys or env config, expect to wire them into the LLM instantiation.

- Small examples to follow when editing
  - Preserve interactive prompts and `input(...)` usage in `with entry` blocks. Example from `main.jac`:
    - crop = input("Enter your crop (maize/beans/wheat/potatoes/onions/cabages/tomatoes): ");
    - est = yield_estimate(crop, rain, fert);

- When adding tests or refactors
  - Extract pure functions (e.g., `base_yield`, `yield_estimate`) for unit testing — they take primitive types and return numeric results; tests can call them directly.
  - Keep LLM-call wrappers small and isolated (like `crop_advice`) so they can be mocked in tests.

- Files and locations to look at when confused
  - `main.jac`, `first.jac`, `crop_advice` (root-level file). Python venvs: `testenv/`, `venv/`.

Ask me to clarify or expand any section (example run commands for your local Jac runtime, or to merge existing rules if you add AGENT.md or README.md later).
