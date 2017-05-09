" Vim syntax file
" Language: Restricted Python
" Maintainer: João Moreno <mail@joaomoreno.com>
" Last Change: 19 Feb 2009
" Filenames: *.repy
" Version: 1.1
"
" Based on python.vim by Dmitry Vasiliev <dima@hlabs.spb.ru>
" and on https://seattle.cs.washington.edu/wiki/PythonVsRepy
"
" Thanks:
" Seattle Project and Community: https://seattle.cs.washington.edu/

if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

ru! syntax/python.vim

syn clear pythonImport
syn keyword pythonImport include

syn clear pythonBuiltinFunc 
syn clear pythonBuiltinObj

if exists("python_highlight_builtins") && python_highlight_builtins != 0

  syn keyword pythonBuiltinObj	True False Ellipsis None NotImplemented
  syn keyword pythonBuiltinObj	__debug__ __doc__ __file__ _package__

  " additional keywords
  syn keyword pythonBuiltinObj  callargs callfunc mycontext socket
  syn keyword pythonBuiltinObj  lock

  syn keyword pythonBuiltinFunc	abs apply
  syn keyword pythonBuiltinFunc	basestring bool buffer bytearray bytes 
  syn keyword pythonBuiltinFunc	chr classmethod cmp coerce 
  syn keyword pythonBuiltinFunc	dict divmod 
  syn keyword pythonBuiltinFunc	file filter float format frozenset getattr
  syn keyword pythonBuiltinFunc	hasattr hex 
  syn keyword pythonBuiltinFunc	int intern isinstance
  syn keyword pythonBuiltinFunc	issubclass len list long map max
  syn keyword pythonBuiltinFunc	min object oct open ord
  syn keyword pythonBuiltinFunc	pow range
  syn keyword pythonBuiltinFunc	reduce repr
  syn keyword pythonBuiltinFunc	round set setattr
  syn keyword pythonBuiltinFunc	slice str sum tuple
  syn keyword pythonBuiltinFunc	type xrange zip

  " additional keywords
  syn keyword pythonBuiltinFunc listdir removefile sleep settimer canceltimer
  syn keyword pythonBuiltinFunc getruntime gethostbyname_ex getlock
  syn keyword pythonBuiltinFunc randomfloat exitall getmyip recvmess sendmess
  syn keyword pythonBuiltinFunc openconn waitforconn stopcomm

endif

syn keyword repyForbidden all any bin callable compile
syn keyword repyForbidden complex delattr dir enumerate
syn keyword repyForbidden eval execfile globals hash help
syn keyword repyForbidden id input iter locals next property
syn keyword repyForbidden raw_input reload reversed sorted
syn keyword repyForbidden staticmethod super unichr unicode vars
syn keyword repyForbidden __import__ import


if version >= 508 || !exists("did_python_syn_inits")
  if version <= 508
    let did_python_syn_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  HiLink repyForbidden Error
  
  delcommand HiLink
endif

let b:current_syntax = "repy"
