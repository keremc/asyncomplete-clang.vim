function! asyncomplete#sources#clang#get_source_options(opts) abort
    return extend({
        \     'refresh_pattern': '\k\+$'
        \ }, a:opts)
endfunction

function! asyncomplete#sources#clang#completor(opts, ctx) abort
    let config = get(a:opts, 'config', {})
    let clang_path = get(config, 'clang_path', 'clang')

    if !executable(clang_path)
        return
    endif

    let clang_args = get(config, 'clang_args', {'default': [], 'c': ['-std=c11'], 'cpp': ['-std=c++11']})
    let clang_args_for_ctx = s:get_clang_args_for_ctx(a:ctx, clang_args)

    let tmp_file = s:write_to_tmp_file()

    let cmd = [clang_path] + clang_args_for_ctx + ['-fsyntax-only', '-Xclang', '-code-completion-macros', '-Xclang', '-code-completion-at=' . tmp_file . ':' . a:ctx['lnum'] . ':' . a:ctx['col'], tmp_file]

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
                \ 'menu': printf('[%s]', a:opts['name']),
                \ 'dup': 0, 'icase': 1})
        endfor
    elseif a:event == 'exit'
        let cur_column = a:ctx['col']
        let text_length = len(matchstr(a:ctx['typed'], '\k\+$'))
        let start_column = cur_column - text_length

        call asyncomplete#complete(a:opts['name'], a:ctx, start_column,
            \ a:matches)
    endif
endfunction

function! s:get_clang_args_for_ctx(ctx, clang_args) abort
    let lang = a:ctx['filetype'] == 'c' ? 'c' : 'c++'
    let default_args = a:clang_args['default']
    let ft_specific_args = a:clang_args[a:ctx['filetype']]
    return ['-x', lang] + default_args + ft_specific_args
endfunction

function! s:write_to_tmp_file() abort
    let file = tempname()
    call writefile(getline(1, '$'), file)
    return file
endfunction
