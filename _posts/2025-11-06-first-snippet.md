---
layout: post
title: "First Snippet: Clean Cargo"
date: 2025-11-06
---

Here’s a handy Zsh alias to clean up Cargo builds:

```zsh
alias cargo-clean='rm -rf target && cargo clean'
