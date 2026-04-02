# SSH into a host and open multiple Zellij sessions in a split Zellij layout.
# Usage:
#   zjss host                    -> 2x2 split, sessions: 0 1 2 3
#   zjss host a b                -> side-by-side split, sessions: a b
#   zjss host a b c d            -> 2x2 split, sessions: a b c d
zjss() {
    local host="${1:?usage: zjss host [session1 session2 ...] (2 or 4 sessions)}"
    shift
    local sessions=("${@:-0 1 2 3}")
    if [[ ${#sessions[@]} -eq 1 ]]; then
        sessions=(${=sessions[1]})
    fi
    local n=${#sessions[@]}
    if [[ $n -ne 2 && $n -ne 4 ]]; then
        echo "zjss: provide 2 or 4 session names (got $n)"
        return 1
    fi

    local layout local_session rows cols wrapper
    layout=$(mktemp "${XDG_RUNTIME_DIR:-/tmp}/zjss-layout-XXXXXX.kdl")
    local_session="zjss-${host%%.*}-$RANDOM"
    rows=${LINES:-24} cols=${COLUMNS:-80}

    wrapper="${ZSHKIT_DIR:-$HOME/repos/zshkit}/zjss-wrapper.sh"
    if [[ ! -x "$wrapper" ]]; then
        echo "zjss: wrapper not found at $wrapper (set ZSHKIT_DIR in ~/.zshrc.local if your clone is elsewhere)" >&2
        return 1
    fi

    local H='$HOME'
    local P='$PATH'
    local cmd1="PATH=${H}/.local/bin:/opt/homebrew/bin:/usr/local/bin:${P} exec -a zjss-pane-${sessions[1]} zellij attach --create ${sessions[1]}"
    local cmd2="PATH=${H}/.local/bin:/opt/homebrew/bin:/usr/local/bin:${P} exec -a zjss-pane-${sessions[2]} zellij attach --create ${sessions[2]}"
    local cmd3="PATH=${H}/.local/bin:/opt/homebrew/bin:/usr/local/bin:${P} exec -a zjss-pane-${sessions[3]:-2} zellij attach --create ${sessions[3]:-2}"
    local cmd4="PATH=${H}/.local/bin:/opt/homebrew/bin:/usr/local/bin:${P} exec -a zjss-pane-${sessions[4]:-3} zellij attach --create ${sessions[4]:-3}"

    if [[ $n -eq 2 ]]; then
        cat <<EOF > "$layout"
layout {
    pane split_direction="vertical" {
        pane command="$wrapper" {
            args "$host" "$cmd1"
        }
        pane command="$wrapper" {
            args "$host" "$cmd2"
        }
    }
}
EOF
    else
        cat <<EOF > "$layout"
layout {
    pane split_direction="vertical" {
        pane split_direction="horizontal" {
            pane command="$wrapper" {
                args "$host" "$cmd1"
            }
            pane command="$wrapper" {
                args "$host" "$cmd2"
            }
        }
        pane split_direction="horizontal" {
            pane command="$wrapper" {
                args "$host" "$cmd3"
            }
            pane command="$wrapper" {
                args "$host" "$cmd4"
            }
        }
    }
}
EOF
    fi

    _tab_title_set "${(j:,:)sessions} @ ${host%%.*}"

    if [[ -n "${ZJSS_DEBUG:-}" ]]; then
        echo "zjss: generated layout at $layout" >&2
        cat "$layout" >&2
    fi

    local rc=0 has_active_zellij=0 launch_mode=""
    if zellij action current-tab-info >/dev/null 2>&1; then
        has_active_zellij=1
        launch_mode="active-zellij-session"
    else
        launch_mode="standalone-session"
    fi

    if [[ -n "${ZJSS_DEBUG:-}" ]]; then
        echo "zjss: ZELLIJ=${ZELLIJ:-<unset>}" >&2
        echo "zjss: ZELLIJ_SESSION_NAME=${ZELLIJ_SESSION_NAME:-<unset>}" >&2
        echo "zjss: launch_mode=$launch_mode" >&2
        echo "zjss: local_session=$local_session" >&2
        if (( has_active_zellij )); then
            echo "zjss: launch_cmd=zellij action new-tab --layout \"$layout\" --name \"zjss: ${host%%.*}\"" >&2
        else
            echo "zjss: launch_cmd=zellij --session \"$local_session\" --new-session-with-layout \"$layout\"" >&2
        fi
    fi

    if (( has_active_zellij )); then
        zellij action new-tab --layout "$layout" --name "zjss: ${host%%.*}"
        rc=$?
    else
        zellij --session "$local_session" --new-session-with-layout "$layout"
        rc=$?
    fi

    if (( rc != 0 )); then
        echo "zjss: zellij launch failed (mode=$launch_mode, rc=$rc)" >&2
        echo "zjss: host=$host sessions=${(j:,:)sessions}" >&2
        echo "zjss: layout file was $layout" >&2
        if [[ -z "${ZJSS_DEBUG:-}" ]]; then
            echo "zjss: rerun with ZJSS_DEBUG=1 to print the generated layout and session detection details." >&2
        fi
    fi

    if (( rc == 0 )) || [[ -z "${ZJSS_DEBUG:-}" ]]; then
        rm -f "$layout"
    else
        echo "zjss: preserving layout file for debugging." >&2
    fi
    _zshkit_reset_terminal_input_modes
    return $rc
}
