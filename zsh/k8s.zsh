# --- Kubernetes (extras beyond the OMZ kubectl plugin: k, kgp, kgd, kdp, kpf, ...) ---
alias kctx='kubectl config get-contexts'
alias kns='kubectl get ns'
alias kw='kubectl get events -A --field-selector type=Warning --sort-by=.metadata.creationTimestamp | tail -n 50'
alias ke='kubectl get events -A --sort-by=.metadata.creationTimestamp | tail -n 50'

kc() {
  [[ -z "$1" ]] && { echo "Usage: kc <context>"; return 1 }
  kubectl config use-context "$1" >/dev/null && kubectl config current-context
}

ksetns() {
  [[ -z "$1" ]] && { echo "Usage: ksetns <namespace>"; return 1 }
  kubectl config set-context --current --namespace="$1" >/dev/null && kubectl config view --minify | grep namespace:
}

kcur() {
  local ctx ns
  ctx="$(kubectl config current-context 2>/dev/null)"
  ns="$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)"
  echo "${ctx:-no-context} / ${ns:-default}"
}
