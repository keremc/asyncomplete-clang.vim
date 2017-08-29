function! asyncomplete#sources#clang#get_source_options(opts) abort
    return extend({
        \     'refresh_pattern': '\k\+$'
        \ }, a:opts)
endfunction

function! asyncomplete#sources#clang#completor(opts, ctx) abort
    let config = get(a:opts, 'config', {})
    let clang_path = get(config, 'clang_path', 'clang')
    let clang_args = get(config, 'clang_args', ['-x', 'c++', '-std=c++11'])

    if !executable(clang_path)
        return
    endif

    let tmp_file = s:write_to_tmp_file()

    let cmd = [clang_path] + clang_args + ['-fsyntax-only', '-Xclang', '-code-completion-macros', '-Xclang', '-code-completion-at=' . tmp_file . ':' . a:ctx['lnum'] . ':' . a:ctx['col'], tmp_file]

    let matches = []

    call async#job#start(cmd, {
        \     'on_stdout': function('s:handler', [a:opts, a:ctx, matches]),
        \     'on_exit': function('s:handler', [a:opts, a:ctx, matches])
        \ })
endfunction

function! s:handler(opts, ctx, matches, job_id, data, event) abort
    if a:event == 'stdout'
        for line in a:data
            let completion_item = matchstr(line, '^COMPLETION: \zs.*\ze :')
            if empty(completion_item)
                continue
            endif

            call add(a:matches, {
                \ 'word': completion_item,
                \ 'dup': 1, 'icase': 1})
        endfor
    elseif a:event == 'exit'
        let cur_column = a:ctx['col']
        let text_length = len(matchstr(a:ctx['typed'], '\k\+$'))
        let start_column = cur_column - text_length

        call asyncomplete#complete(a:opts['name'], a:ctx, start_column,
            \ a:matches)
    endif
endfunction

function! s:write_to_tmp_file() abort
    let file = tempname()
    call writefile(getline(1, '$'), file)
    return file
endfunction
