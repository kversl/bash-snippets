#!/bin/bash
bn=${1%.*}
pandoc "$bn".md \
-f markdown_github+yaml_metadata_block+footnotes+inline_notes+tex_math_dollars \
  -s \
  -o "$bn".odt


#  --reference-docx edgar.docx \
# 02:05
# 
# Formate:
# commonmark (CommonMark Markdown)
# creole (Creole 1.0)
# docbook (DocBook)
# docx (Word docx)
# epub (EPUB)
# fb2 (FictionBook2 e-book)
# gfm (GitHub-Flavored Markdown), or the deprecated and less accurate markdown_github; use markdown_github only if you need extensions not supported in gfm.
# haddock (Haddock markup)
# html (HTML)
# jats (JATS XML)
# json (JSON version of native AST)
# latex (LaTeX)
# markdown (Pandoc’s Markdown)
# markdown_mmd (MultiMarkdown)
# markdown_phpextra (PHP Markdown Extra)
# markdown_strict (original unextended Markdown)
# mediawiki (MediaWiki markup)
# muse (Muse)
# native (native Haskell)
# odt (ODT)
# opml (OPML)
# org (Emacs Org mode)
# rst (reStructuredText)
# t2t (txt2tags)
# textile (Textile)
# tikiwiki (TikiWiki markup)
# twiki (TWiki markup)
# vimwiki (Vimwiki)

