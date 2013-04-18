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

" Separate calling function from the function which does computation, so we
" can call it from another context
function GetJavaIndent()
  return GetJavaIndentWrapped(v:lnum)
endfunction

function! GetJavaIndentWrapped(lnum)
  let currentLineNum = a:lnum
  let currentLineText = getline(currentLineNum)

  " find start of previous line, in case it was a continuation line
  let prevLineNum = PrevNonCommentLine(currentLineNum - 1)
  let prevLineText = getline(prevLineNum)

  " Java is just like C; use the built-in C indenting and then correct a few
  " specific cases.
  let defaultIndent = cindent(currentLineNum)
  echo "defaultIndent " defaultIndent

  " If we're in the middle of a comment then just trust cindent
  if IsComment(currentLineText)
    return defaultIndent
  endif

  " If the previous line starts with '@', we should have the same indent as
  " the previous one
  if IsAnnotation(prevLineText)
    return indent(prevLineNum)
  endif

  " Annotations should not be more indented than the previous comment line
  if IsAnnotation(currentLineText) && IsComment(prevLineText)
    return indent(prevLineNum)
  endif

  " Align "throws" lines for methods
  if IsMethodDetail(currentLineText)
    if IsMethodDetail(prevLineText)
      return indent(prevLineNum)
    else
      " We want "throws" to be indented more than function defintion
      " lines but less than their arguments
      let prevIndent = indent(prevLineNum)
      if prevIndent <= defaultIndent
        return prevIndent + &sw
      else
        return prevIndent - &sw
      endif
    endif
  endif

  " Aligns "implements" and "extends" lines for classes
  if IsClassDetail(currentLineText)
    if IsClassDetail(prevLineText)
      return indent(prevLineNum)
    else
      " We want "implements" and "extends" to be indented
      " more than class defintion lines
      let prevIndent = indent(prevLineNum)
      if prevIndent <= defaultIndent
        return prevIndent + &sw
      else
        return prevIndent - &sw
      endif
    endif
  endif

  " NOTE: The following algorithm works differently than the previous one. It
  " does not attempt to line up the next line after a "throw" with the end of
  " the "throw" word itself

  " The line under "throws" should be indented properly
  if IsMethodDetail(prevLineText)
    if EndsInComma(prevLineText)
      return defaultIndent
    else
      return indent(prevLineNum) - &sw
    endif
  endif

  " BUG: Multiline "throw" statements cause the following line/block to be
  " indented improperly

  " When the line starts with a }, try aligning it with the matching {,
  " skipping over "throws", "extends" and "implements" clauses.
  if IsCloseBrace(currentLineText)
    let matchLineNum = GetMatchingIndentLine(currentLineNum)
    if  matchLineNum < currentLineNum
      let matchLineNum = PrevNonCommentLine(matchLineNum)
      let matchLineNum = PrevNonDetailLine(matchLineNum)
      return indent(matchLineNum)
    endif
  endif

  " Below a line starting with "}" never indent more.  Needed for a method
  " below a method with an indented "throws" clause.
  if IsCloseBrace(prevLineText) && indent(prevLineNum) < defaultIndent
    return indent(prevLineNum)
  endif

  return defaultIndent
endfunction

function! IsAnnotation(text)
  return a:text =~ '^\s*@'
endfunction

function! IsComment(text)
  return a:text =~ '^\s*\/\*' || a:text =~ '^\s*//' || a:text =~ '^\s*\*'
endfunction

function! EndsInComma(text)
  return a:text =~ ',\s*$'
endfunction

function! IsClassDetail(text)
  return a:text =~ '^\s*\(extends\|implements\)\>'
endfunction

function! IsMethodDetail(text)
  return a:text =~ '^\s*throws\>'
endfunction

function! IsOpenBrace(text)
  return a:text =~ '{[^}]*$'
endfunction

function! IsCloseBrace(text)
  return a:text =~ '^\s*}\s*\(//.*\|/\*.*\)\=$'
endfunction

" Works on lines starting with a match-able character eg. }, ), ], etc.
function! GetMatchingIndentLine(lnum)
  call cursor(currentLineNum, 1)
  silent normal %
  return line('.')
endfunction

function! PrevNonCommentLine(lnum)
  let currentLineNum = prevnonblank(a:lnum)
  let currentLineText = getline(currentLineNum)
  while currentLineNum > 1 && IsComment(currentLineText)
    let currentLineNum = prevnonblank(currentLineNum - 1)
    let currentLineText = getline(currentLineNum)
  endwhile
  return currentLineNum
endfunction

" Includes lines ending in commas so that it matches multiline "throws",
" "implements", and "extends"
function! PrevNonDetailLine(lnum)
  let currentLineNum = prevnonblank(a:lnum)
  let currentLineText = getline(currentLineNum)
  while currentLineNum > 1 && (  IsMethodDetail(currentLineText)
    || IsClassDetail(currentLineText)
    || EndsInComma(currentLineText)
    )
    let currentLineNum = prevnonblank(currentLineNum - 1)
    let currentLineText = getline(currentLineNum)
  endwhile
  return currentLineNum
endfunction

let &cpo = s:keepcpo
unlet s:keepcpo

" vi: sw=2 et
