# Changelog for `langchain-hs`

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to the
[Haskell Package Versioning Policy](https://pvp.haskell.org/).

## Unreleased

## 0.0.2.0 - 2025-05-04

### Added

- Added `OpenAI` LLM integration.
- Added `DirectoryLoader` for loading Documents from a directory.
- Added `HuggingFace` LLM integration.
- Added docusaurus documentation.
- Added `OpenAI` embeddings integration.
- Added GHC CI matrix build.
- Added `TokenBufferMemory` Memory integration.
- Added `RetrievalQA` chain.
- Added `CalculatorTool` tool.

### Fixed 

- Fixed `loadAndSplit` function for `PdfLoader`.
- Minor documentation fixes.
- Fixed `WebScraper` to only scrape textual content.
- Made langchain-hs buildable till stack-lts-19.33
- Fixed `React` agent.

### Changed

- Generalized LLMParams to accept different type per LLM. 