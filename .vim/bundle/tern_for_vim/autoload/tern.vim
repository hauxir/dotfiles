if !has('python') && !has('python3')
  echo 'tern requires python support'
  finish
endif

let s:plug = expand("<sfile>:p:h:h")
let s:script = s:plug . '/script/tern.py'
if has('python')
  execute 'pyfile ' . fnameescape(s:script)
elseif has('python3')
  execute 'py3file ' . fnameescape(s:script)
endif

if !exists('g:tern#command')
  let g:tern#command = ["node", expand('<sfile>:h') . '/../node_modules/tern/bin/tern', '--no-port-file']
endif

if !exists('g:tern#arguments')
  let g:tern#arguments = []
endif

function! tern#PreviewInfo(info)
  pclose
  new +setlocal\ previewwindow|setlocal\ buftype=nofile|setlocal\ noswapfile|setlocal\ wrap
  exe "normal z" . &previewheight . "\<cr>"
  call append(0, type(a:info)==type("") ? split(a:info, "\n") : a:info)
  wincmd p
endfunction

function! tern#Complete(findstart, complWord)
  if a:findstart
    if has('python')
      python tern_ensureCompletionCached()
    elseif has('python3')
      python3 tern_ensureCompletionCached()
    endif
    return b:ternLastCompletionPos['start']
  elseif b:ternLastCompletionPos['end'] - b:ternLastCompletionPos['start'] == len(a:complWord)
    return b:ternLastCompletion
  else
    let rest = []
    for entry in b:ternLastCompletion
      if stridx(entry["word"], a:complWord) == 0
        call add(rest, entry)
      endif
    endfor
    return rest
  endif
endfunction

function! tern#LookupType()
  if has('python')
    python tern_lookupType()
  elseif has('python3')
    python3 tern_lookupType()
  endif
  return ''
endfunction

function! tern#LookupArgumentHints()
  if g:tern_show_argument_hints == 'no'
    return
  endif
  let fname = get(matchlist(getline('.')[:col('.')-2],'\([a-zA-Z0-9_]*\)([^()]*$'),1)
  let pos   = match(getline('.')[:col('.')-2],'[a-zA-Z0-9_]*([^()]*$')
  if pos >= 0
    if has('python')
      python tern_lookupArgumentHints(vim.eval('fname'),int(vim.eval('pos')))
    elseif has('python3')
      python3 tern_lookupArgumentHints(vim.eval('fname'),int(vim.eval('pos')))
    endif
  else
    if has('python')
      python tern_lookupType()
    elseif has('python3')
      python3 tern_lookupType()
    endif
  endif
  return ''
endfunction

if has('python')
  command! TernDoc py tern_lookupDocumentation()
  command! TernDocBrowse py tern_lookupDocumentation(browse=True)
  command! TernType py tern_lookupType()
  command! TernDef py tern_lookupDefinition("edit")
  command! TernDefPreview py tern_lookupDefinition("pedit")
  command! TernDefSplit py tern_lookupDefinition("split")
  command! TernDefTab py tern_lookupDefinition("tabe")
  command! TernRefs py tern_refs()
  command! TernRename exe 'py tern_rename("'.input("new name? ",expand("<cword>")).'")'
elseif has('python3')
  command! TernDoc py3 tern_lookupDocumentation()
  command! TernDocBrowse py3 tern_lookupDocumentation(browse=True)
  command! TernType py3 tern_lookupType()
  command! TernDef py3 tern_lookupDefinition("edit")
  command! TernDefPreview py3 tern_lookupDefinition("pedit")
  command! TernDefSplit py3 tern_lookupDefinition("split")
  command! TernDefTab py3 tern_lookupDefinition("tabe")
  command! TernRefs py3 tern_refs()
  command! TernRename exe 'py3 tern_rename("'.input("new name? ",expand("<cword>")).'")'
endif

if !exists('g:tern_show_argument_hints')
  let g:tern_show_argument_hints = 'no'
endif

if !exists('g:tern_show_signature_in_pum')
  let g:tern_show_signature_in_pum = 0
endif

if !exists('g:tern_map_keys')
  let g:tern_map_keys = 0
endif

if !exists('g:tern_map_prefix')
  let g:tern_map_prefix = '<LocalLeader>'
endif

if !exists('g:tern_request_timeout')
  let g:tern_request_timeout = 1
endif

function! tern#DefaultKeyMap(...)
  let prefix = len(a:000)==1 ? a:1 : "<LocalLeader>"
  execute 'nnoremap <buffer> '.prefix.'td' ':TernDoc<CR>'
  execute 'nnoremap <buffer> '.prefix.'tb' ':TernDocBrowse<CR>'
  execute 'nnoremap <buffer> '.prefix.'tt' ':TernType<CR>'
  execute 'nnoremap <buffer> '.prefix.'td' ':TernDef<CR>'
  execute 'nnoremap <buffer> '.prefix.'tpd' ':TernDefPreview<CR>'
  execute 'nnoremap <buffer> '.prefix.'tsd' ':TernDefSplit<CR>'
  execute 'nnoremap <buffer> '.prefix.'ttd' ':TernDefTab<CR>'
  execute 'nnoremap <buffer> '.prefix.'tr' ':TernRefs<CR>'
  execute 'nnoremap <buffer> '.prefix.'tR' ':TernRename<CR>'
endfunction

function! tern#Enable()
  if stridx(&buftype, "nofile") > -1 || stridx(&buftype, "nowrite") > -1
    return
  endif
  let b:ternProjectDir = ''
  let b:ternLastCompletion = []
  let b:ternLastCompletionPos = {'row': -1, 'start': 0, 'end': 0}
  let b:ternBufferSentAt = -1
  let b:ternInsertActive = 0
  setlocal omnifunc=tern#Complete
  if g:tern_map_keys
    call tern#DefaultKeyMap(g:tern_map_prefix)
  endif
  augroup TernAutoCmd
    autocmd! * <buffer>
    if has('python')
      autocmd BufLeave <buffer> :py tern_sendBufferIfDirty()
    elseif has('python3')
      autocmd BufLeave <buffer> :py3 tern_sendBufferIfDirty()
    endif

    if g:tern_show_argument_hints == 'on_move'
      autocmd CursorMoved,CursorMovedI <buffer> call tern#LookupArgumentHints()
    elseif g:tern_show_argument_hints == 'on_hold'
      autocmd CursorHold,CursorHoldI <buffer> call tern#LookupArgumentHints()
    endif
    autocmd InsertEnter <buffer> let b:ternInsertActive = 1
    autocmd InsertLeave <buffer> let b:ternInsertActive = 0
  augroup END
endfunction

augroup TernShutDown
  autocmd VimLeavePre * call tern#Shutdown()
augroup END

function! tern#Disable()
  augroup TernAutoCmd
    autocmd! * <buffer>
  augroup END
endfunction

function! tern#Shutdown()
  if has('python')
    py tern_killServers()
  elseif has('python3')
    py3 tern_killServers()
  endif
endfunction
