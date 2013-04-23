" Vim indent file
" Language: Java
" Previous Maintainer: Toby Allsopp <toby.allsopp@peace.com>
" Current Maintainer: Hong Xu <hong@topbug.net>
" Homepage: http://www.vim.org/scripts/script.php?script_id=3899
"           https://github.com/xuhdev/indent-java.vim
" Last Change:  2012 Jan 20
" Version: 1.0
" License: Same as Vim.
" Copyright (c) 2012 Hong Xu
" Before 2012, this file was maintained by Toby Allsopp.

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

" Indent Java anonymous classes correctly.
setlocal cindent cinoptions& cinoptions+=j1

" Lines starting with "extends", "implements", or "throws" to indent automatically
setlocal indentkeys& indentkeys+=0=extends indentkeys+=0=implements indentkeys+=0=throws

" Set the function to do the work.
setlocal indentexpr=GetJavaIndent()

let b:undo_indent = "set cin< cino< indentkeys< indentexpr<"

" Only define the function once.
if exists("*GetJavaIndent")
  finish
endif

let s:keepcpo= &cpo
set cpo&vim

" Separate calling function from the function which does computation so we
" can call it from another context
function GetJavaIndent()
  return GetJavaIndentWrapped(v:lnum)
endfunction

function! GetJavaIndentWrapped(lnum)
  let currentLineNum = a:lnum
  let currentLineText = getline(currentLineNum)

  " Find start of previous line
  let prevLineNum = prevnonblank(currentLineNum - 1)
  let prevLineText = getline(prevLineNum)

  " Find start of previous non-comment line
  let prevNonCommentLineNum = PrevNonCommentLine(currentLineNum - 1)
  let prevNonCommentLineText = getline(prevNonCommentLineNum)

  " Java is just like C; use the built-in C indenting and then correct a few
  " specific cases.
  let defaultIndent = cindent(currentLineNum)

  " If we're in the middle of a comment then just trust cindent
  if IsCommentLine(currentLineNum) && !IsBlockCommentOpenText(currentLineText) && !IsSingleLineCommentText(currentLineText)
    return defaultIndent
  endif

  " If the previous code line is an annotation, we should use the same indent
  if IsAnnotationText(prevNonCommentLineText)
    return indent(prevNonCommentLineNum)
  endif

  " Annotations on classes indent too far after a comment
  if IsAnnotationText(currentLineText) && IsCommentLine(prevLineNum) && !IsOpenBraceText(prevNonCommentLineText)
    return indent(prevNonCommentLineNum)
  endif

  " The line under "throws" should be indented properly
  if IsMethodDetailLine(prevNonCommentLineNum) && !IsMethodDetailLine(currentLineNum)

    " Make sure we indent based on the function definition
    let prevNonDetailLine = PrevNonMethodDetailLine(prevNonCommentLineNum)
    if EndsInCloseParen(RemoveTrailingCommentsText(getline(prevNonDetailLine)))
      let prevNonDetailIndent = indent(GetMatchingEndIndentLine(prevNonDetailLine))
    else
      let prevNonDetailIndent = indent(PrevNonMethodDetailLine(prevNonCommentLineNum))
    endif

    " We add an indent if we are not on an open brace line
    if IsOpenBraceText(currentLineText)
      return prevNonDetailIndent
    else
      return prevNonDetailIndent + &sw
    endif
  endif

  " The line under "implements" or "extends" should be indented properly
  if IsClassDetailLine(prevNonCommentLineNum) && !IsClassDetailLine(currentLineNum)
    let strippedText = RemoveTrailingCommentsText(currentLineText)
    if !IsClassDetailLine(strippedText) && IsListPartText(strippedText)
      let computedIndent = GetIndentOfClassDetailGivenLine(currentLineNum)
      if computedIndent < 0
        return defaultIndent
      else
        return computedIndent
      endif
    endif

    " We add an indent if we are not on an open brace line
    let PrevNonClassDetailLine(prevNonCommentLineNum)) + &sw
    if IsOpenBraceText(currentLineText)
      return prevNonDetailIndent
    else
      return prevNonDetailIndent + &sw
    endif
  endif

  " Aligns single and multi-line "throws"
  if IsMethodDetailLine(currentLineNum)
    let strippedText = RemoveTrailingCommentsText(currentLineText)

    if !IsLegalMethodDetailText(strippedText) && IsListPartText(strippedText)
      let computedIndent = GetIndentOfMethodDetailGivenLine(currentLineNum)
      if computedIndent < 0
        return defaultIndent
      else
        return computedIndent
      endif
    endif

    " Ensure "throws" aligns with the function definition
    if EndsInCloseParen(RemoveTrailingCommentsText(prevNonCommentLineText))
      return indent(GetMatchingEndIndentLine(prevNonCommentLineNum)) + &sw
    endif

    return indent(PrevNonMethodDetailLine(prevNonCommentLineNum)) + &sw
  endif

  " Aligns single and multi-line "implements" and "extends"
  if IsClassDetailLine(currentLineNum)
    let strippedText = RemoveTrailingCommentsText(currentLineText)
    if !IsLegalClassDetailText(strippedText) && IsListPartText(strippedText)
      let computedIndent = GetIndentOfClassDetailGivenLine(currentLineNum)
      if computedIndent < 0
        return defaultIndent
      else
        return computedIndent
      endif
    endif

    return indent(PrevNonClassDetailLine(prevNonCommentLineNum)) + &sw
  endif

  " When the line starts with a }, try aligning it with the matching {,
  " skipping over "throws", "extends" and "implements" clauses.
  if IsCloseBraceText(currentLineText)
    let matchLineNum = GetMatchingIndentLine(currentLineNum)
    if matchLineNum < currentLineNum
      let matchLineNum = PrevNonCommentLine(matchLineNum)
      if IsMethodDetailLine(matchLineNum)
        let matchLineNum = PrevNonMethodDetailLine(matchLineNum)
      elseif IsClassDetailLine(matchLineNum)
        let matchLineNum = PrevNonClassDetailLine(matchLineNum)
      endif
      return indent(matchLineNum)
    endif
  endif

  return defaultIndent
endfunction

"
" SIMPLE REGEX CLASSIFICATION FUNCTIONS
"

function! IsAnnotationText(text)
  return a:text =~ '^\s*@'
endfunction

function! IsBlockCommentOpenText(text)
  return a:text =~ '^\s*\/\*'
endfunction

function! IsBlockCommentCloseText(text)
  return RemoveTrailingCommentsText(a:text) =~ '\*\/\s*$'
endfunction

function! IsSingleLineCommentText(text)
  return a:text =~ '^\s*\/\/' || a:text =~ '^\s*\/\*.*\*\/\s*$'
endfunction

function! IsOpenBraceText(text)
  return a:text =~ '^\s*{'
endfunction

function! IsCloseBraceText(text)
  return a:text =~ '^\s*[})\]]'
endfunction

function! EndsInCloseParen(text)
  return a:text =~ ')\s*$'
endfunction

" This function determines if the given line is a part of a list, eg:
" ex1: item1, item2
" ex2: item1,
" ex3: item2 {
function! IsListPartText(text)
  return a:text =~ '^\s*\([a-zA-Z0-9$_]\+\s*\)\(,\s*[a-zA-Z0-9$_]\+\s*\)*'
endfunction

function! IsLegalClassDetailText(text)
  let singleDetail = '^\s*\(implements\|extends\)\s\+\([a-zA-Z0-9$_]\+\),\?\s*$'
  let multiDetail  = '^\s*\(implements\|extends\)\s\+\([a-zA-Z0-9$_]\+\s*,\s*\)*\s*$'
  let fullDetail   = '^\s*\(implements\|extends\)\s\+\([a-zA-Z0-9$_]\+\s*,\s*\)\+\([a-zA-Z0-9$_]\+\)\s*{\?\s*$'
  return a:text =~ singleDetail || a:text =~ multiDetail || a:text =~ fullDetail
endfunction

function! IsLegalMethodDetailText(text)
  let singleDetail = '^\s*throws\s\+\([a-zA-Z0-9$_]\+\),\?\s*$'
  let multiDetail  = '^\s*throws\s\+\([a-zA-Z0-9$_]\+\s*,\s*\)*\s*$'
  let fullDetail   = '^\s*throws\s\+\([a-zA-Z0-9$_]\+\s*,\s*\)*\([a-zA-Z0-9$_]\+\)\s*{\?\s*$'
  return a:text =~ singleDetail || a:text =~ multiDetail || a:text =~ fullDetail
endfunction

"
" CONTEXT-AWARE CLASSIFICATION FUNCTIONS
"

" Scrolls backwards looking for the start or end of a comment block
" If it finds the end of a comment block, we are outside a comment
" If it finds the start of a comment block, we are inside a comment
function! IsCommentLine(lnum)
  let currentLineNum = a:lnum
  let currentLineText = getline(currentLineNum)

  if IsSingleLineCommentText(currentLineText)
    return 1
  elseif IsBlockCommentCloseText(currentLineText)
    return 1
  endif

  while currentLineNum > 1
    if !IsSingleLineCommentText(currentLineText)
      if IsBlockCommentCloseText(currentLineText)
        return 0
      elseif IsBlockCommentOpenText(currentLineText)
        return 1
      endif
    endif

    let currentLineNum = currentLineNum - 1
    let currentLineText = getline(currentLineNum)
  endwhile

  return 0
endfunction

" Tests for both single-line and multi-line "implements" and "extends"
function! IsClassDetailLine(lnum)
  let currentLineNum = a:lnum
  let currentLineText = RemoveTrailingCommentsText(getline(currentLineNum))
  let concattedText = currentLineText

  while currentLineNum > 1
    if IsLegalClassDetailText(concattedText)
      return 1
    elseif !IsListPartText(currentLineText)
      return 0
    else
      let currentLineNum = PrevNonCommentLine(currentLineNum - 1)
      let currentLineText = RemoveTrailingCommentsText(getline(currentLineNum))
      let concattedText = currentLineText . " " . concattedText
    endif
  endwhile

  return 0
endfunction

" Tests for both single-line and multi-line "throws"
function! IsMethodDetailLine(lnum)
  let currentLineNum = a:lnum
  let currentLineText = RemoveTrailingCommentsText(getline(currentLineNum))
  let concattedText = currentLineText

  while currentLineNum > 1
    if IsLegalMethodDetailText(concattedText)
      return 1
    elseif !IsListPartText(currentLineText)
      return 0
    else
      let currentLineNum = PrevNonCommentLine(currentLineNum - 1)
      let currentLineText = RemoveTrailingCommentsText(getline(currentLineNum))
      let concattedText = currentLineText . " " . concattedText
    endif
  endwhile

  return 0
endfunction

"
" CONTEXT-AWARE INDENTATION FUNCTIONS
"

" Assuming you are in the middle of a class detail line, looks backwards for the
" first occurrence of "implements" or "extends" and returns the indentation of
" the first word after it
function! GetIndentOfClassDetailGivenLine(lnum)
  let currentLineNum = a:lnum
  let currentLineText = RemoveTrailingCommentsText(getline(currentLineNum))
  let concattedText = currentLineText

  while currentLineNum > 1
    if IsLegalClassDetailText(concattedText)
      let start = match(currentLineText,'\(implements\|extends\)\s\+\([a-zA-Z0-9$_]\+\s*\)\(,\s*[a-zA-Z0-9$_]\+\s*\)*{\?\s*$')
      return matchend(currentLineText, '\(implements\|extends\)\s*', start)
    elseif !IsListPartText(currentLineText)
      return -1
    else
      let currentLineNum = PrevNonCommentLine(currentLineNum - 1)
      let currentLineText = RemoveTrailingCommentsText(getline(currentLineNum))
      let concattedText = currentLineText . " " . concattedText
    endif
  endwhile

  return -1
endfunction

" Assuming you are in the middle of a class detail line, looks backwards for the
" first occurrence of "throws" and returns the indentation of the first word
" after it
function! GetIndentOfMethodDetailGivenLine(lnum)
  let currentLineNum = a:lnum
  let currentLineText = RemoveTrailingCommentsText(getline(currentLineNum))
  let concattedText = currentLineText

  while currentLineNum > 1
    if IsLegalMethodDetailText(concattedText)
      let start = match(currentLineText, 'throws\s\+\([a-zA-Z0-9$_]\+\s*\)\(,\s*[a-zA-Z0-9$_]\+\s*\)*{\?\s*$')
      return matchend(currentLineText, 'throws\s*', start)
    elseif !IsListPartText(currentLineText)
      return -1
    else
      let currentLineNum = PrevNonCommentLine(currentLineNum - 1)
      let currentLineText = RemoveTrailingCommentsText(getline(currentLineNum))
      let concattedText = currentLineText . " " . concattedText
    endif
  endwhile

  return -1
endfunction

"
" TEXT MANIPULATION FUNCTIONS
"

" Finds parts of lines ending in // or /* ... */ and removes them recursively
function! RemoveTrailingCommentsText(text)
  let stripped = substitute(a:text, '\(\/\/.*\)\|\(\/\*.*\*\/\s*\)$', '', '')
  if strlen(a:text) == strlen(stripped)
    return stripped
  else
    return RemoveTrailingCommentsText(stripped)
  endif
endfunction

"
" LINE REVERSE-FIND FUNCTIONS
"

" Works on lines starting with a match-able character eg. }, ), ], etc.
function! GetMatchingIndentLine(lnum)
  call cursor(a:lnum, 1)
  silent normal %
  return line('.')
endfunction

" Works on lines ending with a match-able character eg. }, ), ], etc.
function! GetMatchingEndIndentLine(lnum)
  let stripped = RemoveTrailingCommentsText(getline(a:lnum))
  let stripped = substitute(stripped, '\s*$', '', '')
  call cursor(a:lnum, len(stripped))
  silent normal %
  return line('.')
endfunction

function! PrevNonCommentLine(lnum)
  let currentLineNum = prevnonblank(a:lnum)
  let currentLineText = getline(currentLineNum)
  while currentLineNum > 1 && IsCommentLine(currentLineNum)
    let currentLineNum = prevnonblank(currentLineNum - 1)
    let currentLineText = getline(currentLineNum)
  endwhile
  return currentLineNum
endfunction

function! PrevNonMethodDetailLine(lnum)
  let currentLineNum = prevnonblank(a:lnum)
  let currentLineText = RemoveTrailingCommentsText(getline(currentLineNum))
  while currentLineNum > 1 && IsMethodDetailLine(currentLineNum)
    let currentLineNum = prevnonblank(currentLineNum - 1)
    let currentLineText = RemoveTrailingCommentsText(getline(currentLineNum))
  endwhile

  return currentLineNum
endfunction

function! PrevNonClassDetailLine(lnum)
  let currentLineNum = prevnonblank(a:lnum)
  let currentLineText = RemoveTrailingCommentsText(getline(currentLineNum))
  while currentLineNum > 1 && IsClassDetailLine(currentLineNum)
    let currentLineNum = prevnonblank(currentLineNum - 1)
    let currentLineText = RemoveTrailingCommentsText(getline(currentLineNum))
  endwhile

  return currentLineNum
endfunction

let &cpo = s:keepcpo
unlet s:keepcpo

" vi: sw=2 et
