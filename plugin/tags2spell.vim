" See http://ctags.sourceforge.net/FORMAT
function! s:filter_tags(tags_list)
    let tags_set = {}

    for item in a:tags_list
        " Skip pseudo-tags
        if match(item, '^!_TAG_') == 0
            continue
        endif

        " Tag name is first part of line, up to first <Tab>
        " Strip-off non-alphanumeric characters from the beginning and end of the tag name
        let tag_match = matchlist(item, '^[^[:alnum:]]*\(.\{-1,}\)[^[:alnum:]]\{-}\t')

        let tags_set[tag_match[1]] = ''
    endfor

    return sort(keys(tags_set))
endfunction

function! s:tags_2_spell(bang, ...)
    let overwrite = a:bang
    let make_rare = 0

    if a:0 == 3 && a:1 ==? '-rare'
        let make_rare = 1
        let out_file = a:2
        let in_file = a:3
    elseif a:0 == 2
        let out_file = a:1
        let in_file = a:2
    else
        echomsg 'Usage: Tags2Spell[!] [-rare] <out> <in>'
        return
    endif

    let tag_file = expand(fnamemodify(in_file, ':p'))
    let dic_file = expand(fnamemodify(out_file . '.' . &encoding . '.add.dic', ':p'))
    let aff_file = expand(fnamemodify(out_file . '.' . &encoding . '.add.aff', ':p'))
    let spl_file = expand(fnamemodify(out_file . '.' . &encoding . '.add', ':p'))

    if !overwrite && (filereadable(dic_file) || filereadable(aff_file))
        echomsg "Tags2Spell: output file already exists, use '!' to overwrite"
        return
    endif

    if !filereadable(tag_file)
        echomsg 'Tags2Spell: input file "' . tag_file . '" not found'
        return
    endif

    let tags = readfile(tag_file)

    let tags = s:filter_tags(tags)

    if make_rare
        call map(tags, 'v:val . ''/?''')
    endif

    " First line needs to be count of words
    call writefile([len(tags)] + tags, dic_file)

    let affix = ['MIDWORD _:']
    if make_rare
        let affix += ['RARE ?']
    endif

    call writefile(affix, aff_file)

    execute 'silent mkspell! ' . spl_file
endfunction

command! -bang -nargs=+ -complete=file Tags2Spell call s:tags_2_spell(<bang>0, <f-args>)
