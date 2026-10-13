# --- Kubernetes (extras beyond the OMZ kubectl plugin: k, kgp, kgd, kdp, kpf, ...) ---
alias kk='k9s'
alias kctx='kubectl config get-contexts'
alias kns='kubectl get ns'
alias kgn='kubectl get nodes -o wide'
alias kdn='kubectl describe node'
alias kapply='kubectl apply -f'
alias kdel='kubectl delete -f'
alias klog='kubectl logs -f'
alias klogp='kubectl logs -f --previous'
alias kexec='kubectl exec -it'
alias krollout='kubectl rollout status'
alias krestart='kubectl rollout restart'
alias ktop='kubectl top pods'
alias ktopn='kubectl top nodes'
alias kw='kubectl get events -A --field-selector type=Warning --sort-by=.metadata.creationTimestamp | tail -n 50'
alias ke='kubectl get events -A --sort-by=.metadata.creationTimestamp | tail -n 50'
alias kdrain='kubectl drain --ignore-daemonsets --delete-emptydir-data'
alias kcordon='kubectl cordon'
alias kuncordon='kubectl uncordon'

# --- Terraform ---
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'

# --- Kubernetes helpers ---
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

klogs() { stern "${1:?Usage: klogs <pod-pattern>}" --tail=50 --since=5m }
