for file in ~/.{path,bash_prompt,exports,aliases,functions,extra,work}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file"
done;
unset file;

shopt -s nocaseglob;
shopt -s histappend;
shopt -s cdspell;

for option in autocd globstar; do
    shopt -s "$option" 2>/dev/null;
done;
