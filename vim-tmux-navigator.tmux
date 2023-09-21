#!/usr/bin/env bash

version_pat='s/^tmux[^0-9]*([.0-9]+).*/\1/p'

is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
    | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"
tmux_version="$(tmux -V | sed -En "$version_pat")"
tmux setenv -g tmux_version "$tmux_version"

#echo "{'version' : '${tmux_version}', 'sed_pat' : '${version_pat}' }" > ~/.tmux_version.json

default_pane_resize="5"

# tmux show-option "q" (quiet) flag does not set return value to 1, even though
# the option does not exist. This function patches that.
get_tmux_option() {
  local option=$1
  local default_value=$2
  local option_value=$(tmux show-option -gqv "$option")
  if [ -z $option_value ]; then
    echo $default_value
  else
    echo $option_value
  fi
}

pane_navigation_bindings() {
  tmux bind-key -n h if-shell "$is_vim" "send-keys C-h" "select-pane -L"
  tmux bind-key -n C-h if-shell "$is_vim" "send-keys C-h" "select-pane -L"
  tmux bind-key -n j if-shell "$is_vim" "send-keys C-j" "select-pane -D"
  tmux bind-key -n C-j if-shell "$is_vim" "send-keys C-j" "select-pane -D"
  tmux bind-key -n k if-shell "$is_vim" "send-keys C-k" "select-pane -U"
  tmux bind-key -n C-k if-shell "$is_vim" "send-keys C-k" "select-pane -U"
  tmux bind-key -n l if-shell "$is_vim" "send-keys C-l" "select-pane -R"
  tmux bind-key -n C-l if-shell "$is_vim" "send-keys C-l" "select-pane -R" 

  tmux if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
    "bind-key -n '\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
  tmux if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
    "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
  tmux if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
    "bind-key -n '\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"
  tmux if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
    "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

  tmux bind-key -T copy-mode-vi h select-pane -L
  tmux bind-key -T copy-mode-vi C-h select-pane -L
  tmux bind-key -T copy-mode-vi j select-pane -D
  tmux bind-key -T copy-mode-vi C-j select-pane -D
  tmux bind-key -T copy-mode-vi k select-pane -U
  tmux bind-key -T copy-mode-vi C-k select-pane -U
  tmux bind-key -T copy-mode-vi l select-pane -R
  tmux bind-key -T copy-mode-vi C-l select-pane -R
  tmux bind-key -T copy-mode-vi \\ select-pane -l
  tmux bind-key -T copy-mode-vi C-\\ select-pane -l
}

window_move_bindings() {
  tmux bind-key -r "<" swap-window -d -t -1
  tmux bind-key -r ">" swap-window -d -t +1
}

pane_resizing_bindings() {
  local pane_resize=$(get_tmux_option "@pane_resize" "$default_pane_resize")
  tmux bind-key -r H resize-pane -L "$pane_resize"
  tmux bind-key -r J resize-pane -D "$pane_resize"
  tmux bind-key -r K resize-pane -U "$pane_resize"
  tmux bind-key -r L resize-pane -R "$pane_resize"
}

pane_split_bindings() {
  tmux bind-key "|" split-window -h -c "#{pane_current_path}"
  tmux bind-key "\\" split-window -fh -c "#{pane_current_path}"
  tmux bind-key "-" split-window -v -c "#{pane_current_path}"
  tmux bind-key "_" split-window -fv -c "#{pane_current_path}"
  tmux bind-key "%" split-window -h -c "#{pane_current_path}"
  tmux bind-key '"' split-window -v -c "#{pane_current_path}"
}

improve_new_window_binding() {
  tmux bind-key "c" new-window -c "#{pane_current_path}"
}

main() {
  pane_navigation_bindings
  window_move_bindings
  pane_resizing_bindings
  pane_split_bindings
  improve_new_window_binding
}
main
