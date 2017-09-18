let s:cur_file = expand('<sfile>:p')
let s:clang_completer_path = fnamemodify(s:cur_file, ':h:h:h:h') . '/bin/clang_completer'

let s:job_id = -1

let s:last_req_id = -1
let s:req_info = {}

function! asyncomplete#sources#clang#get_source_options(...) abort
    return extend(extend({
        \     'name': 'clang',
        \     'completor': function('asyncomplete#sources#clang#completor'),
        \     'whitelist': ['c', 'cpp', 'objc', 'objcpp']
        \ }, a:0 >= 1 ? a:1 : {}), {'refresh_pattern': '\k\+$'})
endfunction

function! asyncomplete#sources#clang#completor(opts, ctx) abort
    if !executable('python2') && !filereadable(s:clang_completer_path)
        return
    endif

    if s:job_id == -1
        let s:job_id = async#job#start(['python2', '-u', s:clang_completer_path], {
            \     'on_stdout': function('s:handler')
            \ })
    endif

    call async#job#send(s:job_id, json_encode({
        \     'id': s:last_req_id + 1,
        \     'path': a:ctx['filepath'],
        \     'line': a:ctx['lnum'],
        \     'col': s:find_start_col(a:ctx),
        \     'buf': join(getbufline(a:ctx['bufnr'], 1, '$'), "\n")
        \ }) . "\n")

    let s:last_req_id = s:last_req_id + 1
    let s:req_info[s:last_req_id] = [a:opts, a:ctx]
endfunction

function! s:handler(job_id, data, ev) abort
    let resp = json_decode(a:data[0])

    let resp_id = resp['id']
    let comps = resp['comps']

    let info = s:req_info[resp_id]
    let opts = info[0]
    let ctx = info[1]

    let matches = map(comps, {_, v -> {'word': v}})

    call asyncomplete#complete(opts['name'], ctx, resp['col'], matches)
endfunction

let s:ft_lang_mappings = {
    \     'cpp': 'c++',
    \     'objc': 'objective-c',
    \     'objcpp': 'objective-c++',
    \ }

function! s:find_start_col(ctx) abort
    let cur_col = a:ctx['col']
    let text_len = len(matchstr(a:ctx['typed'], '\k\+$'))
    return cur_col - text_len
endfunction
