#!/usr/bin/env sh

: "${GLYPHBOOK_CATALOG:?Set GLYPHBOOK_CATALOG to the icons.json path}"

icons_get() {
  (
  if [ "$#" -ne 2 ]; then
    printf 'usage: icons_get CATEGORY NAME\n' >&2
    return 2
  fi

  category=$1
  name=$2
  icons_catalog=$GLYPHBOOK_CATALOG

  case $category in
    application)
      jq -er --arg name "$name" 'first(.icons[] | select(any(.applications[]?; . == $name)))' "$icons_catalog"
      ;;
    website)
      name=$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')
      case $name in
        *://*) name=${name#*://} ;;
      esac
      name=${name%%/*}
      name=${name%%\?*}
      name=${name%%\#*}
      name=${name##*@}
      name=${name%%:*}
      jq -er --arg host "$name" '
        first(.icons[] | select(any(.domains[]?; . == $host))) //
        ([.icons[] | select(any(.domains[]?; . as $domain | ($domain | startswith("*.")) and ($domain[2:] as $suffix | $host | endswith("." + $suffix))))]
          | max_by(.domains[] | select(startswith("*.")) | length)) //
        first(.icons[] | select(any(.domains[]?; . == "*")))
      ' "$icons_catalog"
      ;;
    default|directory|extension|file|editor-filetype|lsp|os)
      case $category in
        default|extension|editor-filetype|lsp|os) name=$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]') ;;
      esac
      case $category in
        default) field=defaults ;;
        directory) field=directories ;;
        extension) field=extensions ;;
        file) field=files ;;
        editor-filetype) field=editorFiletypes ;;
        lsp) field=lsp ;;
        os) field=operatingSystems ;;
      esac
      jq -er --arg field "$field" --arg name "$name" 'first(.icons[] | select(any(.[$field][]?; . == $name)))' "$icons_catalog"
      ;;
    *)
      printf 'unknown icon category: %s\n' "$category" >&2
      return 2
      ;;
  esac
  )
}

icons_list() {
  (
  if [ "$#" -ne 1 ]; then
    printf 'usage: icons_list CATEGORY\n' >&2
    return 2
  fi

  case $1 in
    application) jq -r '.icons[].applications[]?' "$GLYPHBOOK_CATALOG" | LC_ALL=C sort -u ;;
    website) jq -r '.icons[].domains[]? | select(. != "*")' "$GLYPHBOOK_CATALOG" | LC_ALL=C sort -u ;;
    default|directory|extension|file|editor-filetype|lsp|os)
      case $1 in
        default) field=defaults ;;
        directory) field=directories ;;
        extension) field=extensions ;;
        file) field=files ;;
        editor-filetype) field=editorFiletypes ;;
        lsp) field=lsp ;;
        os) field=operatingSystems ;;
      esac
      jq -r --arg field "$field" '.icons[] | .[$field][]?' "$GLYPHBOOK_CATALOG" | LC_ALL=C sort -u
      ;;
    *)
      printf 'unknown icon category: %s\n' "$1" >&2
      return 2
      ;;
  esac
  )
}

icons_get_file() {
  (
  if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    printf 'usage: icons_get_file PATH [FILETYPE]\n' >&2
    return 2
  fi

  name=${1##*/}
  exact=$(icons_get file "$name" 2>/dev/null || true)
  if [ -n "$exact" ]; then
    printf '%s\n' "$exact"
    return
  fi

  suffix=${name#*.}
  while [ "$suffix" != "$name" ]; do
    icon=$(icons_get extension "$suffix" 2>/dev/null || true)
    if [ -n "$icon" ]; then
      printf '%s\n' "$icon"
      return
    fi
    case $suffix in
      *.*) suffix=${suffix#*.} ;;
      *) break ;;
    esac
  done

  if [ "$#" -eq 2 ]; then
    filetype=$(icons_get editor-filetype "$2" 2>/dev/null || true)
    if [ -n "$filetype" ]; then
      printf '%s\n' "$filetype"
      return
    fi
  fi

  icons_get default file
  )
}
