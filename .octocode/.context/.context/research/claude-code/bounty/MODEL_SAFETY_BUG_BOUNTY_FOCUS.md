# Model Safety Bug Bounty Focus

Reference program: [Model Safety Bug Bounty Program](https://support.claude.com/en/articles/12119250-model-safety-bug-bounty-program)

## Purpose Of This Document

This document defines what we are focusing on when we evaluate findings against Anthropic's Model Safety Bug Bounty scope.

It is a focus guide, not a vulnerability report.

## Primary Focus

Based on the program description, our focus is:

1. **Universal jailbreaks**
   - Techniques that reliably produce policy-violating model behavior across many prompts.
   - Not narrow one-off prompt tricks.
2. **Classifier bypass quality**
   - Whether safeguards (including Constitutional Classifiers) are consistently bypassed.
   - Whether the bypass is robust and repeatable.
3. **High-impact harmful output classes**
   - Emphasis on the harmful biological-information category called out by the program.
   - We focus on depth, specificity, and consistency of unsafe output under the tested method.
4. **Reproducibility and evidence**
   - Clear prompt pattern/attack method.
   - Multiple successful examples.
   - Failure modes and boundary conditions.

## What We Are Explicitly Not Focusing On In This Track

The bug bounty page separates model-safety jailbreak research from technical product security bugs.

So for this track, we are **not** focusing on:

- CSRF / XSS / SQL injection
- privilege escalation in application infrastructure
- directory traversal or system misconfiguration findings
- generic app pentest findings unrelated to universal jailbreak behavior

Those belong to responsible disclosure, not this model-safety bounty scope.

## Quality Bar For Candidate Findings

A candidate is strong when it is:

- **generalized**: works across broad prompt families
- **stable**: reproducible across runs
- **high signal**: produces meaningful policy-violating content, not borderline behavior
- **novel**: not a known/duplicate low-value variation
- **well-documented**: includes exact steps, prompts, outputs, and limits

## Submission-Ready Checklist

- Attack pattern described in a reusable way
- At least several distinct prompt contexts tested
- Success/failure rate documented
- Output severity documented
- Clear explanation of why this is universal vs narrow
- Minimal ambiguity for triage reviewers

## Confidentiality Notes

Program participation has confidentiality constraints.  
Do not publish restricted details from private program materials without explicit permission.

## Scope Reminder

This focus document aligns to the public program page and should be used to keep testing and reporting effort targeted at model-safety jailbreak criteria.

## Reference

- Anthropic Claude Help Center: [Model Safety Bug Bounty Program](https://support.claude.com/en/articles/12119250-model-safety-bug-bounty-program)
