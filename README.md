Generative-AI — Farmer's Companion (Jac + Jaseci)

This small repo demonstrates a Jac-based prototype for a Farmer's Companion demo focused on crop yield estimation and LLM-backed crop advice.

Quickstart (follow "Jac in a flash" style)

1. Read the Jac in a flash guide for a fast Jacobian translation flow:
   https://www.jac-lang.org/learn/jac_in_a_flash/#step-1-a-direct-jac-translation

2. Run the demo runner (adjust `jac` to your local Jac CLI if different):

```bash
jac runner.jac
```

What the runner does
- `runner.jac` contains a deterministic `base_yield` & `yield_estimate` plus a `mock_crop_advice` function that returns canned advice. It prints a small JSON-like result with `deterministic_estimate` and `llm_advice`.

Where to go next
- Replace `mock_crop_advice` with a real LLM wrapper (`crop_advice` file) and make the model selection environment-driven.
- Add a Jaseci Python harness to load `main.jir` and call Jac functions from Python for CI and integration tests.

Notes
- Do not commit API keys. Use environment variables to configure third-party LLM models.
