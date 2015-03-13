" unite source for `repository files`
" LICENSE: MIT
" AUTHOR: pekepeke <pekepekesamurai@gmail.com>

" global variables {{{1
let g:unite_source_repo_files_rule = get(g:, 'unite_source_repo_files_rule', {})
call unite#util#set_default('g:unite_source_repo_files_max_candidates', 100)
let g:unite_source_repo_files_ignore_pattern = get(g:, 'unite_repo_files_ignore_pattern',
\'\%(^\|/\)\.$\|\~$\|\.\%(o\|exe\|dll\|bak\|DS_Store\|zwc\|pyc\|sw[po]\|class\)$'.
\'\|\%(^\|/\)\%(\.hg\|\.git\|\.bzr\|\.svn\|tags\%(-.*\)\?\)\%($\|/\)')
" \'\|\.\%(\|jpg\|png\|gif\|jpeg\|tiff\|eps\|ocx\|prn\|obj\)$'.
let g:unite_repo_files_debug = 0

" static values {{{1
let s:has_vimproc = unite#util#has_vimproc()
let s:source = {
\   'name': 'repo_files',
\   'max_candidates': g:unite_source_repo_files_max_candidates,
\   'ignore_pattern' : g:unite_source_repo_files_ignore_pattern,
\   'hooks': {},
\ }

" source {{{1
function! s:source.on_init(args, context) "{{{2
  let s:buffer = {
        \ }
endfunction

function! s:source.gather_candidates(args, context) " {{{2
  let directory = unite#util#path2project_directory(expand('%'))

  let command = ""
  let is_use_system = 0

  for name in keys(g:unite_source_repo_files_rule)
    if name =~ "^_"
      continue
    endif
    let item = g:unite_source_repo_files_rule[name]
    if s:has_located(directory, item)
      let command = s:get_command(item, directory)
      let is_use_system = s:is_use_system(item)
      break
    endif
  endfor

  if empty(command)
    let name = '_'
    while 1
      if !has_key(g:unite_source_repo_files_rule, name)
        break
      endif
      let item = g:unite_source_repo_files_rule[name]
      let command = s:get_command(item, directory)
      if !empty(command)
        let is_use_system = s:is_use_system(item)
        break
      endif
      let name .= '_'
    endwhile
  endif

  if empty(command)
    call unite#util#print_error('Not a repository.')
    return []
  endif

  call unite#print_source_message(
        \ 'command : ' . command, self.name)
  let cwd = getcwd()

  if s:has_vimproc

    call unite#print_source_message(
          \ 'directory: ' . directory, self.name)

    let a:context.is_async = 1
    let continuation = {
          \   'files' : [],
          \   'rest' : [directory],
          \   'directory' : directory,
          \   'end' : 0,
          \ }

    lcd `=directory`

    let save_term = $TERM
    try
      " Disable colors.
      let $TERM = 'dumb'

      if has_key(item, 'with_plineopen3') && item.with_plineopen3
        let a:context.source__proc = vimproc#plineopen3(
              \ vimproc#util#iconv(command, &encoding, 'char'), 1)
      else
        let a:context.source__proc = vimproc#pgroup_open(
              \ command
              \ )
      endif
    finally
      let $TERM = save_term
    endtry
    lcd `=cwd`

    " Close handles.
    call a:context.source__proc.stdin.close()

    let a:context.__continuation = continuation

    return []
  endif
  lcd `=directory`
  let result = is_use_system ? system(command) : unite#util#system(command)
  lcd `=cwd`

  if is_use_system || unite#util#get_last_status() == 0
    let lines = split(result, '\r\n\|\r\|\n')
    return filter(map(lines, 's:create_candidate(v:val, directory)'), 'len(v:val) > 0')
  endif

  call unite#util#print_error(printf('can not exec command : %s', command))
  return []
endfunction

function! s:source.async_gather_candidates(args, context) "{{{2
  let stderr = a:context.source__proc.stderr
  if !stderr.eof
    " Print error.
    let errors = filter(stderr.read_lines(-1, 100),
          \ "v:val !~ '^\\s*$'")
    if !empty(errors)
      call unite#print_source_error(errors, self.name)
    endif
  endif

  let continuation = a:context.__continuation

  let stdout = a:context.source__proc.stdout
  if stdout.eof
    " Disable async.
    if stdout.eof
      call unite#print_source_message(
            \ 'Directory traverse was completed.', self.name)
    else
      call unite#print_source_message(
            \ 'Scanning directory.', self.name)
    endif
    let a:context.is_async = 0
    let continuation.end = 1
  endif

  let candidates = []

  let filenames = map(filter(
        \ stdout.read_lines(-1, 100), 'v:val != ""'),
        \ "fnamemodify(unite#util#iconv(v:val, 'char', &encoding), ':p')")
  let filenames = filter(filenames, 'v:val !~? a:context.source.ignore_pattern')
  let candidates = map(filenames, 's:create_candidate(v:val, continuation.directory)')

  let continuation.files += candidates
  " if stdout.eof
  "   " write cache
  " endif

  return deepcopy(candidates)
endfunction

function! s:source.hooks.on_close(args, context) " {{{2
  if has_key(a:context, 'source__proc')
    call a:context.source__proc.waitpid()
  endif
endfunction

" util functions {{{1
function! s:create_candidate(filename, directory) "{{{2
  if stridx(a:filename, a:directory) == -1
    let filename = a:directory . "/" . a:filename
  else
    let filename = a:filename
  endif
  let fpath = unite#util#substitute_path_separator(
        \ fnamemodify(filename, ':p'))
  let start = strlen(a:directory) + 1
  return {
        \   "word": strpart(fpath, start),
        \   "source": "repo_files",
        \   "kind": "file",
        \   "action__path": fpath,
        \   "action__directory": a:directory
        \ }
endfunction


function! s:has_located(directory, item) " {{{2
  if !exists('a:item.located')
    return 0
  endif

  let t = a:directory.'/'. a:item.located
  return isdirectory(t) || filereadable(t)
endfunction

function! s:get_command(item, directory) " {{{2
  let commands = type(a:item.command) == type([]) ? a:item.command : [a:item.command]
  for _cmd in commands
    if executable(_cmd)
      let command = _cmd
      break
    endif
  endfor
  if exists('command')
    return substitute(substitute(a:item.exec, '%c', command, ''), '%d', a:directory, '')
  endif
  return ''
endfunction

function! s:is_use_system(item) " {{{2
  return exists('a:item.use_system') && a:item.use_system
endfunction

function! s:log(...) "{{{2
  if !g:unite_repo_files_debug
    return
  endif
  if exists(':NeoBundle') && !neobundle#is_sourced('vimconsole.vim')
    NeoBundleSource vimconsole.vim
  endif
  if !exists(':VimConsoleOpen')
    return
  endif
  let args = copy(a:000)
  if empty(args)
    call vimconsole#log('repo_files')
    return
  endif
  let args[0] = strftime("%Y/%m/%d %T") . "> repo_files " . args[0]
  call call('vimconsole#log', args)
endfunction

function! s:variables_init() "{{{2
  for item in [
        \ {
        \   'name': 'git',
        \   'located' : '.git',
        \   'command' : 'git',
        \   'exec' : '%c ls-files --cached --others --exclude-standard',
        \ }, {
        \   'name': 'hg',
        \   'located' : '.hg',
        \   'command' : 'hg',
        \   'exec' : '%c manifest',
        \ }, {
        \   'name': 'bazaar',
        \   'located' : '.bzr',
        \   'command' : 'bzr',
        \   'exec' : '%c ls -R',
        \ }, {
        \   'name': '_',
        \   'located' : '.',
        \   'command' : 'ag',
        \   'exec' : '%c --noheading --nocolor --nogroup --nopager -g "" %d',
        \   'use_system' : 1,
        \ }, {
        \   'name': '__',
        \   'located' : '.',
        \   'command' : ['ack-grep', 'ack'],
        \   'exec' : '%c -f --no-heading --no-color --nogroup --nopager',
        \   'use_system' : 1,
        \   'with_plineopen3': 1,
        \ },
        \ ]
    if !exists('g:unite_source_repo_files_rule.' . item.name)
      let g:unite_source_repo_files_rule[item.name] = item
      unlet item["name"]
    endif
  endfor

endfunction

" define {{{1
call s:variables_init()

function! unite#sources#repo_files#define() " {{{2
  return [s:source]
endfunction

" __END__ {{{1
