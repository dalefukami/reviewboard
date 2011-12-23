
let s:rb_buffer_id = -1
let g:rb_window_height = 8
let s:rb_buffer_name       = '[ReviewBoard]'

function! s:RBWindowOpen() range

    " Save the current buffer number.
    let s:rb_buffer_last       = bufnr('%')
    let s:rb_buffer_last_winnr = winnr()
    let l:win_size = g:yankring_window_height

    let g:rb_filename = expand("%:p")

    if bufwinnr(s:rb_buffer_id) == -1
        " Special consideration was involved with these sequence
        " of commands.  
        "     First, split the current buffer.
        "     Second, edit a new file.
        "     Third record the buffer number.
        " If a different sequence is followed when the yankring
        " buffer is closed, Vim's alternate buffer is the yanking
        " instead of the original buffer before the yankring 
        " was shown.
        let cmd_mod = ''
        if v:version >= 700
            let cmd_mod = 'keepalt '
        endif
        exec 'silent! ' . cmd_mod . 'botright' . ' ' . l:win_size . 'split ' 

        " Using :e and hide prevents the alternate buffer
        " from being changed.
        exec ":e " . escape(s:rb_buffer_name, ' ')
        " Save buffer id
        let s:rb_buffer_id = bufnr('%') + 0
    else
        " If the buffer is visible, switch to it
        exec bufwinnr(s:rb_buffer_id) . "wincmd w"
    endif

    " Mark the buffer as scratch
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal nowrap
    setlocal nonumber
    setlocal nobuflisted
    setlocal noreadonly
    setlocal modifiable

    " Setup buffer variables
    let b:line_number = a:firstline
    let b:num_lines = a:lastline - a:firstline + 1
    let b:filename = g:rb_filename

    nnoremap <buffer> <silent> <Leader>s :call <SID>RBSaveComment()<CR>
endfunction



let g:filediff_ids = {}
let g:request_id = 0
let g:review_id = 0
let g:base_path = '/home/dale/www/cyclops/' "XXX User defined...alternatively, search for git root
let g:rb_command = '/home/dale/projects/reviewboard/bin/reviewboard.rb'

function! s:RBSaveComment()
    let l:content = join(getline(0,'$'),"\n")
    let l:diff_filename = substitute(b:filename, "^".g:base_path, "", "")
    echo "got filename". l:diff_filename
    let l:filediff_id = g:filediff_ids["".l:diff_filename]
    let l:command_options = "-q ".g:request_id." -r ".g:review_id." -l ".b:line_number." -c \"".l:content."\" -n ".b:num_lines." -f ".l:filediff_id." -d 1 --dest" "XXX Note that dest is hardcoded default for now
    echo "Run with options: [".l:command_options."]"
    echo system( g:rb_command." comment ". l:command_options )
endfunction

command! -range -nargs=? RBWindowOpen  <line1>,<line2>call s:RBWindowOpen(<args>)
map <Leader>rb :RBWindowOpen<CR>

sign define comment text=cc texthl=Search
function! s:RBLabelComments()
    let l:diff_json = system(g:rb_command." diff -q ".g:request_id)
    silent let b:comments = eval(l:diff_json)
    silent let b:comment_signs = {}
    for l:comment in b:comments
        echo l:comment
        for i in range(1, l:comment['num_lines'])
            "Sign ids must be numbers
            let l:sign_id = l:comment['id']+(i*1000000)
            let l:line_number = l:comment['first_line']+i-1
            echo l:sign_id
            echo l:line_number
            let b:comment_signs[l:line_number] = l:sign_id
            echo b:comment_signs
            echo ":sign place ".l:sign_id." line=".l:line_number." name=comment file=" .expand("%:p")
            exec ":sign place ".l:sign_id." line=".l:line_number." name=comment file=" .expand("%:p")
        endfor
    endfor
endfunction

command! RBLabelComments call s:RBLabelComments()
map <Leader>cc :RBLabelComments<CR>

function! s:RBDisplayComment()
    let l:current_line = line(".")
    for l:comment in b:comments
        for i in range(1, l:comment['num_lines'])
            let l:line_number = l:comment['first_line']+i-1
            if l:line_number == l:current_line
                call s:RBWindowOpen()
                silent %d
                let @c = l:comment['text']
                put! c
            endif
        endfor
    endfor
endfunction
command! RBDisplayComment call s:RBDisplayComment()


function! s:RBChooseReview(...)
    if a:0 < 1
        call s:RBWindowOpen()

        let l:json = system(g:rb_command." request -u dale")
        silent let b:reviews = eval(l:json)
        for l:review in b:reviews
            call append('$', "[".l:review['id']."] ".l:review['summary'])
        endfor

        nnoremap <buffer> <silent> <CR>  :call <SID>RBOpenRequest()<CR>
    else
        call <SID>RBOpenRequest(a:1)
    endif
endfunction

command! -nargs=? RBChooseReview  call s:RBChooseReview(<args>)


function! s:RBOpenRequest(...)
    if a:0 < 1
        let l:line = getline('.')
        let l:matches = matchlist(l:line, '^\[\([0-9]\+\)\]')
        let l:request_id = l:matches[1]
    else
        let l:request_id = a:1
    endif

    let g:request_id = l:request_id

    call s:RBLoadFileDiffs()
    call s:RBLoadCurrentDraft()

    call s:RBReturnToWindow()

    call s:RBListFiles()
endfunction


function! s:RBLoadFileDiffs()
    let l:json = system(g:rb_command." file_diffs -q ".g:request_id)
    silent let b:filediffs = eval(l:json)
    let g:filediff_ids = {}
    for l:filediff in b:filediffs
        let g:filediff_ids[ l:filediff['dest_file'] ] = l:filediff['id']
    endfor
endfunction
command! RBLoadFileDiffs  call s:RBLoadFileDiffs()

function! s:RBLoadCurrentDraft()
    let g:review_id = + system(g:rb_command." draft_id -q ".g:request_id)
endfunction

function! s:RBListFiles()
    call s:RBWindowOpen()

    for [l:file_name, l:file_id] in items(g:filediff_ids)
        call append('$', l:file_name)
    endfor

    nnoremap <buffer> <silent> <CR> :call <SID>RBOpenFile("edit")<CR>
    nnoremap <buffer> <silent> s :call <SID>RBOpenFile("split")<CR>
    nnoremap <buffer> <silent> v :call <SID>RBOpenFile("vsplit")<CR>
endfunction
command! RBListFiles  call s:RBListFiles()

function! s:RBOpenFile(command)
    let l:file_name = g:base_path . getline('.')

    call s:RBReturnToWindow()

    exec a:command." ".l:file_name
    call s:RBLabelComments()
endfunction

function! s:RBReturnToWindow()
    bdelete
    if bufwinnr(s:rb_buffer_last) != -1
        " If the buffer is visible, switch to it
        exec s:rb_buffer_last_winnr . "wincmd w"
    endif
endfunction

