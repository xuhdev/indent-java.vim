" Vim indent file
" Language: Java
" Previous Maintainer: Toby Allsopp <toby.allsopp@peace.com>
" Current Maintainer: Hong Xu <hong@topbug.net>
" Homepage: http://www.vim.org/scripts/script.php?script_id=3899
"           https://github.com/xuhdev/indent-java.vim
" Last Change:  2013 May 14
" Version: 1.0
" License: Same as Vim.
" Copyright (c) 2012 Hong Xu
" Before 2012, this file was maintained by Toby Allsopp.

" Only load this indent file when no other was loaded.
if exists("b:java_indent")
  finish
endif
let b:java_indent = 1

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

function! GetJavaIndent(...)
  " Lets us call this function with or without arguments
  if len(a:000) > 0
    let currentLineNum = a:1
  else
    let currentLineNum = v:lnum
  endif
  let currentLineText = getline(currentLineNum)

  " Find start of previous line
  let prevLineNum = prevnonblank(currentLineNum - 1)
  let prevLineText = getline(prevLineNum)

  " Find start of previous non-comment line
  let prevNonCommentLineNum = s:PrevNonCommentLine(currentLineNum - 1)
  let prevNonCommentLineText = getline(prevNonCommentLineNum)

  " Java is just like C; use the built-in C indenting and then correct a few
  " specific cases.
  let defaultIndent = cindent(currentLineNum)

  " If we're in the middle of a comment then just trust cindent
  if s:IsCommentLine(currentLineNum)
        \ && !s:IsBlockCommentOpenText(currentLineText)
        \ && !s:IsSingleLineCommentText(currentLineText)
    return defaultIndent
  endif

  " If the previous code line is an annotation, we should use the same indent
  if s:IsAnnotationText(prevNonCommentLineText)
    return indent(prevNonCommentLineNum)
  endif

  " Annotations indent too far after a comment
  if s:IsAnnotationText(currentLineText) && s:IsCommentLine(prevLineNum)

    " We run into an issue when a comment is the first line in the file
    if prevNonCommentLineNum == 1 && s:IsCommentLine(prevNonCommentLineNum)
      return 0
    endif

    return indent(s:GetBeginningOfComment(prevLineNum))
  endif

  " When the line starts with a }, try aligning it with the matching {,
  " skipping over "throws", "extends" and "implements" clauses.
  if s:IsCloseBraceText(currentLineText)
    let matchLineNum = s:GetMatchingIndentLine(currentLineNum)
    if matchLineNum < currentLineNum
      let matchLineNum = s:PrevNonCommentLine(matchLineNum)
      if s:IsMethodDetailLine(matchLineNum)
        let matchLineNum = s:PrevNonMethodDetailLine(matchLineNum)
      elseif s:IsClassDetailLine(matchLineNum)
        let matchLineNum = s:PrevNonClassDetailLine(matchLineNum)
      endif
      return indent(matchLineNum)
    endif
  endif

  " The line under "throws" should be indented properly
  if s:IsMethodDetailLine(prevNonCommentLineNum) && !s:IsMethodDetailLine(currentLineNum)

    " Make sure we indent based on the function definition
    let prevNonDetailLine = s:PrevNonMethodDetailLine(prevNonCommentLineNum)
    if s:EndsInCloseParen(s:RemoveTrailingCommentsText(getline(prevNonDetailLine)))
      let prevNonDetailIndent = indent(s:GetMatchingEndIndentLine(prevNonDetailLine))
    else
      let prevNonDetailIndent = indent(s:PrevNonMethodDetailLine(prevNonCommentLineNum))
    endif

    " We add an indent if we are not on an open brace line
    if s:IsOpenBraceText(currentLineText)
      return prevNonDetailIndent
    else
      return prevNonDetailIndent + &sw
    endif
  endif

  " The line under "implements" or "extends" should be indented properly
  if s:IsClassDetailLine(prevNonCommentLineNum) && !s:IsClassDetailLine(currentLineNum)
    let strippedText = s:RemoveTrailingCommentsText(currentLineText)

    if s:IsListPartText(strippedText)
      let computedIndent = s:GetIndentOfClassDetailGivenLine(currentLineNum)
      if computedIndent < 0
        return defaultIndent
      else
        return computedIndent
      endif
    endif

    " We add an indent if we are not on an open brace line
    let prevNonDetailIndent = indent(s:PrevNonClassDetailLine(prevNonCommentLineNum))
    if s:IsOpenBraceText(currentLineText)
      return prevNonDetailIndent
    else
      return prevNonDetailIndent + &sw
    endif
  endif

  " Aligns single and multi-line "implements" and "extends"
  if s:IsClassDetailLine(currentLineNum)
    let strippedText = s:RemoveTrailingCommentsText(currentLineText)
    if !s:IsLegalClassDetailText(strippedText) && s:IsListPartText(strippedText)
      let computedIndent = s:GetIndentOfClassDetailGivenLine(currentLineNum)
      if computedIndent < 0
        return defaultIndent
      else
        return computedIndent
      endif
    endif

    return indent(s:PrevNonClassDetailLine(prevNonCommentLineNum)) + &sw
  endif

  " Aligns single and multi-line "throws"
  if s:IsMethodDetailLine(currentLineNum)
    let strippedText = s:RemoveTrailingCommentsText(currentLineText)
    if !s:IsLegalMethodDetailText(strippedText) && s:IsListPartText(strippedText)
      let computedIndent = s:GetIndentOfMethodDetailGivenLine(currentLineNum)
      if computedIndent < 0
        return defaultIndent
      else
        return computedIndent
      endif
    endif

    return indent(s:PrevNonClassDetailLine(prevNonCommentLineNum)) + &sw
  endif

  return defaultIndent
endfunction

"
" SIMPLE REGEX CLASSIFICATION FUNCTIONS
"

function s:IsAnnotationText(text)
  return a:text =~ '^\s*@'
endfunction

function s:IsBlockCommentOpenText(text)
  return a:text =~ '^\s*\/\*'
endfunction

function s:IsBlockCommentCloseText(text)
  return s:RemoveTrailingCommentsText(a:text) =~ '\*\/\s*$'
endfunction

function s:IsSingleLineCommentText(text)
  return a:text =~ '^\s*\/\/' || a:text =~ '^\s*\/\*.*\*\/\s*$'
endfunction

function s:IsOpenBraceText(text)
  return a:text =~ '^\s*{'
endfunction

function s:IsCloseBraceText(text)
  return a:text =~ '^\s*[})\]]'
endfunction

function s:EndsInCloseParen(text)
  return a:text =~ ')\s*$'
endfunction

" This function determines if the given line is a part of a list, eg:
" ex1: item1, item2
" ex2: item1,
" ex3: item2 {
function s:IsListPartText(text)
  return a:text =~ '^\s*\([a-zA-Z0-9$_]\+\s*,\s*\)*[a-zA-Z0-9$_]\+\s*\(,\s*\)\?\({\s*\)\?$'
endfunction

function s:IsLegalClassDetailText(text)
  return a:text =~ '^\s*\(implements\|extends\)\s\+\([a-zA-Z0-9$_]\+\s*,\s*\)*\([a-zA-Z0-9$_]\+\)'
endfunction

function s:IsLegalMethodDetailText(text)
  return a:text =~ '^\s*throws\s\+\([a-zA-Z0-9$_]\+\s*,\s*\)*\([a-zA-Z0-9$_]\+\)'
endfunction

"
" CONTEXT-AWARE CLASSIFICATION FUNCTIONS
"

" Scrolls backwards looking for the start or end of a comment block
" If it finds the end of a comment block, we are outside a comment
" If it finds the start of a comment block, we are inside a comment
function s:IsCommentLine(lnum)
  let currentLineNum = a:lnum
  let currentLineText = getline(currentLineNum)

  if s:IsSingleLineCommentText(currentLineText)
    return 1
  elseif s:IsBlockCommentCloseText(currentLineText)
    return 1
  endif

  while currentLineNum > 0
    if !s:IsSingleLineCommentText(currentLineText)
      if s:IsBlockCommentCloseText(currentLineText)
        return 0
      elseif s:IsBlockCommentOpenText(currentLineText)
        return 1
      endif
    endif

    let currentLineNum = currentLineNum - 1
    let currentLineText = getline(currentLineNum)
  endwhile

  return 0
endfunction

" Tests for both single-line and multi-line "implements" and "extends"
function s:IsClassDetailLine(lnum)
  let currentLineNum = a:lnum
  let currentLineText = s:RemoveTrailingCommentsText(getline(currentLineNum))
  let concattedText = currentLineText

  while currentLineNum > 1
    if s:IsLegalClassDetailText(concattedText)
      return 1
    elseif !s:IsListPartText(currentLineText)
      return 0
    else
      let currentLineNum = s:PrevNonCommentLine(currentLineNum - 1)
      let currentLineText = s:RemoveTrailingCommentsText(getline(currentLineNum))
      let concattedText = printf("%s %s", currentLineText, concattedText)
    endif
  endwhile

  return 0
endfunction

" Tests for both single-line and multi-line "throws"
function s:IsMethodDetailLine(lnum)
  let currentLineNum = a:lnum
  let currentLineText = s:RemoveTrailingCommentsText(getline(currentLineNum))
  let concattedText = currentLineText

  while currentLineNum > 1
    if s:IsLegalMethodDetailText(concattedText)
      return 1
    elseif !s:IsListPartText(currentLineText)
      return 0
    else
      let currentLineNum = s:PrevNonCommentLine(currentLineNum - 1)
      let currentLineText = s:RemoveTrailingCommentsText(getline(currentLineNum))
      let concattedText = printf("%s %s", currentLineText, concattedText)
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
function s:GetIndentOfClassDetailGivenLine(lnum)
  let currentLineNum = a:lnum
  let currentLineText = s:RemoveTrailingCommentsText(getline(currentLineNum))
  let concattedText = currentLineText

  while currentLineNum > 1
    if s:IsLegalClassDetailText(concattedText)
      let start = match(currentLineText,'\(implements\|extends\).*$')
      return matchend(currentLineText, '\(implements\|extends\)\s*', start)
    elseif !s:IsListPartText(currentLineText)
      return -1
    else
      let currentLineNum = s:PrevNonCommentLine(currentLineNum - 1)
      let currentLineText = s:RemoveTrailingCommentsText(getline(currentLineNum))
      let concattedText = currentLineText . " " . concattedText
    endif
  endwhile

  return -1
endfunction

function s:GetIndentOfMethodDetailGivenLine(lnum)
  let currentLineNum = a:lnum
  let currentLineText = s:RemoveTrailingCommentsText(getline(currentLineNum))
  let concattedText = currentLineText

  while currentLineNum > 1
    if s:IsLegalMethodDetailText(concattedText)
      let start = match(currentLineText,'throws.*$')
      return matchend(currentLineText, 'throws\s*', start)
    elseif !s:IsListPartText(currentLineText)
      return -1
    else
      let currentLineNum = s:PrevNonCommentLine(currentLineNum - 1)
      let currentLineText = s:RemoveTrailingCommentsText(getline(currentLineNum))
      let concattedText = currentLineText . " " . concattedText
    endif
  endwhile

  return -1
endfunction

"
" TEXT MANIPULATION FUNCTIONS
"

" Finds parts of lines ending in // or /* ... */ and removes them recursively
function s:RemoveTrailingCommentsText(text)
  let stripped = substitute(a:text, '\(\/\/.*\)\|\(\/\*.*\*\/\s*\)$', '', '')
  if strlen(a:text) == strlen(stripped)
    return stripped
  else
    return s:RemoveTrailingCommentsText(stripped)
  endif
endfunction

"
" LINE REVERSE-FIND FUNCTIONS
"

" Works on single-line and multi-line comments
function s:GetBeginningOfComment(lnum)
  let currentLineNum = a:lnum

  if s:IsSingleLineCommentText(getline(currentLineNum))
    return currentLineNum
  endif

  while currentLineNum > 0 && !s:IsBlockCommentOpenText(getline(currentLineNum))
    let currentLineText = getline(currentLineNum)
    let currentLineNum = currentLineNum - 1
  endwhile

  return currentLineNum
endfunction

" Works on lines starting with a match-able character eg. }, ), ], etc.
function s:GetMatchingIndentLine(lnum)
  call cursor(a:lnum, 1)
  silent normal %
  return line('.')
endfunction

" Works on lines ending with a match-able character eg. }, ), ], etc.
function s:GetMatchingEndIndentLine(lnum)
  let stripped = s:RemoveTrailingCommentsText(getline(a:lnum))
  let stripped = substitute(stripped, '\s*$', '', '')
  call cursor(a:lnum, len(stripped))
  silent normal %
  return line('.')
endfunction

function s:PrevNonCommentLine(lnum)
  let currentLineNum = prevnonblank(a:lnum)
  let currentLineText = getline(currentLineNum)
  while currentLineNum > 1 && s:IsCommentLine(currentLineNum)
    let currentLineNum = prevnonblank(currentLineNum - 1)
    let currentLineText = getline(currentLineNum)
  endwhile
  return currentLineNum
endfunction

function s:PrevNonMethodDetailLine(lnum)
  let currentLineNum = prevnonblank(a:lnum)
  let currentLineText = s:RemoveTrailingCommentsText(getline(currentLineNum))
  while currentLineNum > 1 && s:IsMethodDetailLine(currentLineNum)
    let currentLineNum = prevnonblank(currentLineNum - 1)
    let currentLineText = s:RemoveTrailingCommentsText(getline(currentLineNum))
  endwhile

  return currentLineNum
endfunction

function s:PrevNonClassDetailLine(lnum)
  let currentLineNum = prevnonblank(a:lnum)
  let currentLineText = s:RemoveTrailingCommentsText(getline(currentLineNum))
  while currentLineNum > 1 && s:IsClassDetailLine(currentLineNum)
    let currentLineNum = prevnonblank(currentLineNum - 1)
    let currentLineText = s:RemoveTrailingCommentsText(getline(currentLineNum))
  endwhile

  return currentLineNum
endfunction

function s:IsClassDefinitionLine(lnum)
  let  currentLineNum = a:lnum
  let currentLineText = s:RemoveTrailingCommentsText(getline(currentLineNum))
  let concattedText = currentLineText

  while currentLineNum > 0
    if IsLegalClassDefinitionText(concattedText)
      return 1
    elseif ContainsSemicolon(currentLineText)
          \ || ContainsCloseBrace(currentLineText)
          \ || s:IsAnnotationText(currentLineText)
      return 0
    endif
  endwhile

  return 0
endfunction

let &cpo = s:keepcpo
unlet s:keepcpo

" vi: sw=2 et
