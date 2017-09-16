function! asyncomplete#sources#clang#get_source_options(...) abort
    return extend(extend({
        \     'name': 'clang',
        \     'completor': function('asyncomplete#sources#clang#completor'),
        \     'whitelist': ['c', 'cpp', 'objc', 'objcpp']
        \ }, a:0 >= 1 ? a:1 : {}), {'refresh_pattern': '\k\+$'})
endfunction

function! asyncomplete#sources#clang#completor(opts, ctx) abort
    let config = get(a:opts, 'config', {})
    let clang_path = get(config, 'clang_path', 'clang')

    if !executable(clang_path)
        return
    endif

    let clang_args = s:collect_clang_args(a:ctx, config)

    let tmp_file = s:write_buf_to_tmp_file(a:ctx)
    let start_col = s:find_start_col(a:ctx)

    let cmd = [clang_path] + clang_args + ['-fsyntax-only',
        \ '-Xclang', '-code-completion-macros', '-Xclang', '-code-completion-at',
        \ '-Xclang', printf('%s:%d:%d', tmp_file, a:ctx['lnum'], start_col), tmp_file]

    let matches = []

    call async#job#start(cmd, {
        \     'on_stdout': function('s:handler', [a:opts, a:ctx, start_col, matches]),
        \     'on_exit': function('s:handler', [a:opts, a:ctx, start_col, matches])
        \ })
endfunction

function! s:handler(opts, ctx, start_col, matches, job_id, data, event) abort
    if a:event == 'stdout'
        for line in a:data
            let comp_item = matchstr(line, '^COMPLETION: \zs\S\+')

            if empty(comp_item)
                continue
            endif

            call add(a:matches, {
                \     'word': comp_item, 'menu': printf('[%s]', a:opts['name']),
                \     'dup': 0, 'icase': 1
                \ })
        endfor
    elseif a:event == 'exit'
        call asyncomplete#complete(a:opts['name'], a:ctx, a:start_col, a:matches)
    endif
endfunction

let s:file_type_lang_mappings = {
    \     'cpp': 'c++',
    \     'objc': 'objective-c',
    \     'objcpp': 'objective-c++',
    \ }

function! s:collect_clang_args(ctx, config) abort
    let args = []

    let file_type = a:ctx['filetype']

    let lang = get(s:file_type_lang_mappings, file_type, 'c')
    call extend(args, ['-x', lang])

    let clang_args = get(a:config, 'clang_args', {})
    if has_key(clang_args, file_type)
        call extend(args, clang_args[file_type])
    elseif has_key(clang_args, 'default')
        call extend(args, clang_args['default'])
    endif

    let clang_complete_file = findfile('.clang_complete', '.;')
    if !empty(clang_complete_file)
        let work_dir = fnamemodify(clang_complete_file, ':p:h')
        call extend(args, ['-working-directory',  work_dir])
        call extend(args, readfile(clang_complete_file))
    endif

    return args
endfunction

let s:tmp_files = {}

function! s:write_buf_to_tmp_file(ctx) abort
    let file_path = a:ctx['filepath']

    if has_key(s:tmp_files, file_path)
        let tmp_file = s:tmp_files[file_path]
    else
        let tmp_file = tempname()
        let s:tmp_files[file_path] = tmp_file
    endif

    call writefile(getbufline(a:ctx['bufnr'], 1, '$'), tmp_file)

    return tmp_file
endfunction

function! s:find_start_col(ctx) abort
    let cur_col = a:ctx['col']
    let text_len = len(matchstr(a:ctx['typed'], '\k\+$'))
    return cur_col - text_len
endfunction
