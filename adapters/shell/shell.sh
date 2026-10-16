#!/usr/bin/env sh

: "${GLYPHBOOK_CATALOG:?Set GLYPHBOOK_CATALOG to the icons.json path}"

icons_resolver_enabled() {
  [ -n "${GLYPHBOOK_RESOLVER:-}" ] && [ -r "${GLYPHBOOK_INDEX:-}" ] && [ -r "${GLYPHBOOK_RECORDS:-}" ]
}

icons_resolver() {
  "$GLYPHBOOK_RESOLVER" --index "$GLYPHBOOK_INDEX" --records "$GLYPHBOOK_RECORDS" "$@"
}

icons_get() {
  (
  if [ "$#" -ne 2 ]; then
    printf 'usage: icons_get CATEGORY NAME\n' >&2
    return 2
  fi

  category=$1
  name=$2
  icons_catalog=$GLYPHBOOK_CATALOG

  if icons_resolver_enabled; then
    case $category in
      website) icons_resolver website "$name" ;;
      default|directory|extension|file|editor-filetype|lsp|os|application) icons_resolver get "$category" "$name" ;;
      *)
        printf 'unknown icon category: %s\n' "$category" >&2
        return 2
        ;;
    esac
    return
  fi

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
        reduce .icons[] as $icon (
          { exact: null, wildcard: null, wildcardLength: 0, fallback: null };
          reduce ($icon.domains[]?) as $domain (
            .;
            if $domain == $host and .exact == null then .exact = $icon
            elif $domain == "*" then .fallback = $icon
            elif ($domain | startswith("*.")) then
              ($domain[2:]) as $suffix
              | if ($host | endswith("." + $suffix)) and ($suffix | length) > .wildcardLength then
                  .wildcard = $icon | .wildcardLength = ($suffix | length)
                else .
                end
            else .
            end
          )
        ) | .exact // .wildcard // .fallback
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
    *)
      if icons_resolver_enabled; then
        case $1 in
          application|website|default|directory|extension|file|editor-filetype|lsp|os)
            icons_resolver list "$1"
            return
            ;;
          *)
            printf 'unknown icon category: %s\n' "$1" >&2
            return 2
            ;;
        esac
      fi
      ;;
  esac

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
  filetype=${2-}
  if icons_resolver_enabled; then
    if [ "$#" -eq 2 ]; then
      icons_resolver file "$name" "$filetype"
    else
      icons_resolver file "$name"
    fi
    return
  fi
  jq -er --arg name "$name" --arg filetype "$filetype" '
    def suffixes($name):
      ($name | split(".")) as $parts
      | if ($parts | length) < 2 then []
        else [range(1; $parts | length) as $index | $parts[$index:] | join(".") | ascii_downcase]
        end;
    reduce .icons[] as $icon (
      { files: {}, extensions: {}, filetypes: {}, defaults: {} };
      reduce ($icon.files[]?) as $matcher (.;
        if .files | has($matcher) then . else .files[$matcher] = $icon end)
      | reduce ($icon.extensions[]? | ascii_downcase) as $matcher (.;
          if .extensions | has($matcher) then . else .extensions[$matcher] = $icon end)
      | reduce ($icon.editorFiletypes[]? | ascii_downcase) as $matcher (.;
          if .filetypes | has($matcher) then . else .filetypes[$matcher] = $icon end)
      | reduce ($icon.defaults[]? | ascii_downcase) as $matcher (.;
          if .defaults | has($matcher) then . else .defaults[$matcher] = $icon end)
    ) as $maps
    | $maps.files[$name]
      // first(suffixes($name)[] as $suffix | $maps.extensions[$suffix] | select(. != null))
      // (if $filetype == "" then null else $maps.filetypes[($filetype | ascii_downcase)] end)
      // $maps.defaults.file
  ' "$GLYPHBOOK_CATALOG"
  )
}
