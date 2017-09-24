let s:cur_file = expand('<sfile>:p')
let s:clang_completer_path = fnamemodify(s:cur_file, ':h:h:h:h') . '/bin/clang_completer'

let s:job_id = 0

let s:last_req_id = -1
let s:req_info = []

let s:ft_lang_mappings = {
  \   'cpp': 'c++',
  \   'objc': 'objective-c',
  \   'objcpp': 'objective-c++'
  \ }

function! asyncomplete#sources#clang#get_source_options(...) abort
  return extend(extend({
    \   'name': 'clang',
    \   'completor': function('asyncomplete#sources#clang#completor'),
    \   'whitelist': ['c', 'cpp', 'objc', 'objcpp']
    \ }, a:0 >= 1 ? a:1 : {}), {'refresh_pattern': '\k\+$'})
endfunction

function! s:init() abort
  if !executable('python2') || !filereadable(s:clang_completer_path)
    return v:false
  endif

  if s:job_id <= 0
    let s:job_id = async#job#start(['python2', '-u', s:clang_completer_path], {
      \   'on_stdout': function('s:handle')
      \ })
  endif
  if s:job_id <= 0
    return v:false
  endif

  if !exists('#asyncomplete_clang#BufWritePost#<buffer>')
    augroup asyncomplete_clang
      autocmd BufWritePost <buffer> call <SID>on_save()
    augroup END
  endif

  return v:true
endfunction

function! asyncomplete#sources#clang#completor(opts, ctx) abort
  if !s:init()
    return
  endif

  let start_col = s:find_start_col(a:ctx)

  call s:send_req('comp', {
    \   'path': a:ctx['filepath'],
    \   'line': a:ctx['lnum'],
    \   'col': start_col,
    \   'buf': join(getline(1, '$'), "\n")
    \ }, [a:opts, a:ctx, start_col])
endfunction

function! s:handle(job_id, data, ev) abort
  let resp = json_decode(a:data[0])
  let resp_id = resp['id']
  let resp_type = resp['type']
  let info = s:req_info[resp_id]

  if resp_type == 'comp'
    let comps = resp['comps']

    if empty(comps)
      return
    endif

    let opts = info[0]
    let ctx = info[1]
    let start_col = info[2]

    call asyncomplete#complete(opts['name'], ctx, start_col, comps)
  endif
endfunction

function! s:on_save() abort
  call s:send_req('parse', {
    \   'path': expand('%:p')
    \ }, [])
endfunction

function! s:send_req(type, data, info) abort
  let s:last_req_id = s:last_req_id + 1
  call add(s:req_info, a:info)
  call async#job#send(s:job_id, json_encode(extend(a:data, {
    \   'id': s:last_req_id,
    \   'type': a:type
    \ })) . "\n")
endfunction

function! s:find_start_col(ctx) abort
  let cur_col = a:ctx['col']
  let text_len = len(matchstr(a:ctx['typed'], '\k\+$'))
  return cur_col - text_len
endfunction
