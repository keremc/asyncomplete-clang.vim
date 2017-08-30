function! asyncomplete#sources#clang#get_source_options(opts) abort
    return extend({
        \     'refresh_pattern': '\k\+$'
        \ }, a:opts)
endfunction

function! asyncomplete#sources#clang#completor(opts, ctx) abort
    let config = s:get_config(a:opts)
    let clang_path = config['clang_path']

    if !executable(clang_path)
        return
    endif

    let clang_args = s:get_clang_args(a:ctx, config['clang_args'])

    let tmp_file = s:write_to_tmp_file()

    let cur_column = a:ctx['col']
    let text_length = len(matchstr(a:ctx['typed'], '\k\+$'))
    let start_column = cur_column - text_length

    let cmd = [clang_path] + clang_args +
        \ ['-fsyntax-only', '-Xclang', '-code-completion-macros', '-Xclang',
        \ printf('-code-completion-at=%s:%d:%d', tmp_file, a:ctx['lnum'],
        \     start_column), tmp_file]

    let matches = []

    call async#job#start(cmd, {
        \     'on_stdout': function('s:handler', [a:opts, a:ctx, start_column, matches]),
        \     'on_exit': function('s:handler', [a:opts, a:ctx, start_column, matches])
        \ })
endfunction

function! s:handler(opts, ctx, start_column, matches, job_id, data, event) abort
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
        call asyncomplete#complete(a:opts['name'], a:ctx, a:start_column,
            \ a:matches)
    endif
endfunction

function! s:get_config(opts) abort
    let config = deepcopy(get(a:opts, 'config', {}))
    let config['clang_path'] = get(config, 'clang_path', 'clang')
    let config['clang_args'] = get(config, 'clang_args', {})
    let config['clang_args']['common'] = get(config['clang_args'], 'common', [])
    let config['clang_args']['c'] = get(config['clang_args'], 'c', ['-std=c11'])
    let config['clang_args']['cpp'] = get(config['clang_args'], 'cpp', ['-std=c++11'])

    let config['clang_path'] = get(b:, 'asyncomplete_clang_path', config['clang_path'])

    if exists('b:asyncomplete_clang_args')
        for key in keys(b:asyncomplete_clang_args)
            let config['clang_args'][key] = b:asyncomplete_clang_args[key]
        endfor
    endif

    return config
endfunction

function! s:get_clang_args(ctx, clang_args) abort
    let lang = a:ctx['filetype'] == 'c' ? 'c' : 'c++'
    let common_args = a:clang_args['common']
    let lang_specific_args = a:clang_args[a:ctx['filetype']]
    return ['-x', lang] + common_args + lang_specific_args
endfunction

function! s:write_to_tmp_file() abort
    let file = tempname()
    call writefile(getline(1, '$'), file)
    return file
endfunction
