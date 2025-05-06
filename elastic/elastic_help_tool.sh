#!/bin/bash

# ================== READ ME ================== #
# Elastic Cluster Maintenance Script
# Uses curl with client cert.
#
# Modify variables as needed.
# ================== READ ME ================== #

# ====== Variables ====== #
ES_URL="http://localhost:9200"

# ====== Colors ====== #
RED='\033[0;31m' # Red text
NC='\033[0m'     # No Color (reset)

# ====== Auth State ====== #
CA_CERT=""
ES_CERT=""
ES_KEY=""
AUTH_FLAGS=""
INSECURE=false
USED_CERT=false

ES_USER=""
ES_PW=""

# ====== Help ====== #
show_help() {
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Required Authentication (choose one mode):"
    echo "  --insecure,      -x               Use insecure mode (no certs)"
    echo "     OR"
    echo "  --ca-cert,       -a <path>        Path to CA certificate"
    echo "  --es-cert,       -b <path>        Path to Elasticsearch client certificate"
    echo "  --es-key,        -c <path>        Path to Elasticsearch client private key"
    echo ""
    echo "Required Credentials:"
    echo "  --user,          -u <username>    Input username for Elasticsearch"
    echo "  --hardcode-user, -U <username>    Hardcode the Elasticsearch username"
    echo ""
    echo "Other:"
    echo "  --help,          -h               Show this help message and exit"
    echo ""
}

# ====== Show help if no arguments ====== #
if [[ $# -eq 0 || "$1" =~ ^(--help|-h)$ ]]; then
    show_help
    exit 0
fi

# ====== Parse CLI args ====== #
while [[ $# -gt 0 ]]; do
    case "${1,,}" in
        --ca-cert|-a)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo -e "${RED}Error: --ca-cert (-a) requires a file path.${NC}"
                exit 1
            fi
            CA_CERT="$2"
            AUTH_FLAGS+=" --CA_CERT $CA_CERT"
            USED_CERT=true
            shift 2
            ;;
        --es-cert|-b)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo -e "${RED}Error: --es-cert (-b) requires a file path.${NC}"
                exit 1
            fi
            ES_CERT="$2"
            AUTH_FLAGS+=" --cert $ES_CERT"
            USED_CERT=true
            shift 2
            ;;
        --es-key|-c)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo -e "${RED}Error: --es-key (-c) requires a file path.${NC}"
                exit 1
            fi
            ES_KEY="$2"
            AUTH_FLAGS+=" --key $ES_KEY"
            USED_CERT=true
            shift 2
            ;;
        --insecure|-x)
            AUTH_FLAGS="--insecure"
            INSECURE=true
            shift
            ;;
        --hardcode-user|-U|--user|-u)
            if [[ -z "$2" || "$2" == -* ]]; then
            echo -e "${RED}Error: --user (-u or -U) requires a username.${NC}"
            exit 1
            fi
            ES_USER="$2"
            shift 2
            ;;

        *)
            echo -e "${RED}Unknown argument:${NC} $1"
            shift
            ;;
    esac
done

# ====== Username Validation ====== #
if [[ -z "$ES_USER" ]]; then
    echo -e "\n${RED}Error: Username is required.${NC}"
    echo "Use either:"
    echo "  --hardcode-user (-U) to set a default"
    echo "  OR"
    echo "  --user (-u) to provide one at runtime"
    exit 1
fi

# ====== Validation ====== #
if [[ "$INSECURE" = true && "$USED_CERT" = true ]]; then
  echo -e "\n${RED}Error: --insecure cannot be combined with cert-based options.${NC}"
  echo "You must provide either:"
  echo "  --insecure (-x)"
  echo "        OR"
  echo "  One or more of: --ca-cert (-a)"
  echo "                  --es-cert (-b)"
  echo "                  --es-key  (-c)"
  exit 1
fi

if [[ "$INSECURE" = false && "$USED_CERT" = false ]]; then
  echo -e "\n${RED}Error: No authentication method provided.${NC}\n"
  echo "You must provide either:"
  echo "  --insecure (-x)"
  echo "        OR"
  echo "  One or more of: --ca-cert (-a)"
  echo "                  --es-cert (-b)"
  echo "                  --es-key  (-c)"
  exit 1
fi

if [[ -z "$ES_USER" ]]; then
    echo -e "\n${RED}Error: Username is required. Use --hardcode-user or -u <name>${NC}"
    exit 1
fi

# ====== Prompt for Password ====== #
prompt="Enter password for user $ES_USER: "
stty -echo
printf "%s" "$prompt"
while IFS= read -r -s -n1 char; do
    [[ $char == $'\0' || $char == $'\n' ]] && break
    ES_PW+="$char"
    printf '*'
done
stty echo
echo ""

# ====== Script ====== #
# https://patorjk.com/software/taag/#p=testall&f=Chunky&t=Elastic%0AAll-in-One%0AHelp%0ATool
# Font: Chunky
echo "
            _______ __               __   __       
           |    ___|  |.---.-.-----.|  |_|__|.----.
           |    ___|  ||  _  |__ --||   _|  ||  __|
           |_______|__||___._|_____||____|__||____|
                                                  
   _______ __ __        __               _______   
  |   _   |  |  |______|__|.-----.______|       |.-----.-----.
  |       |  |  |______|  ||     |______|   -   ||     |  -__|
  |___|___|__|__|      |__||__|__|      |_______||__|__|_____|
                                            
                  _______         __         
                 |   |   |.-----.|  |.-----. 
                 |       ||  -__||  ||  _  | 
                 |___|___||_____||__||   __| 
                                     |__|    
                  _______               __   
                 |_     _|.-----.-----.|  |  
                   |   |  |  _  |  _  ||  |  
                   |___|  |_____|_____||__|  
"

echo -e "\n** Welcome to the Elastic All-in-One Help Tool! **\n"
echo -e "     You may exit at any time with ${RED}<CTRL+C>${NC}\n"

echo -e "******************** ${RED}!!!${NC} ********************"
echo -e "   Please note that the ${RED}Maintenance${NC} options"
echo -e "       can cause ${RED}harm${NC} to your cluster!!!"
echo -e "******************** ${RED}!!!${NC} ********************\n"

# ====== Cluster Menu ====== #
cluster_menu() {
  echo "Cluster:"
  echo "1) Health"
  echo "2) Health Report"
  echo "3) Nodes"
  echo "4) Settings"

  read -r -p "Select an option: " cluster_choice

  case "$cluster_choice" in
  1) curl -XGET "$AUTH_FLAGS" -u $ES_USER:"$ES_PW" "$ES_URL/_cluster/health" ;;
  2) curl -XGET "$AUTH_FLAGS" -u $ES_USER:"$ES_PW" "$ES_URL/_cluster/health_report" ;;
  3) curl -XGET "$AUTH_FLAGS" -u $ES_USER:"$ES_PW" "$ES_URL/_nodes" ;;
  4) curl -XGET "$AUTH_FLAGS" -u $ES_USER:"$ES_PW" "$ES_URL/_cluster/settings" ;;
  *) echo "Invalid choice." ;;
  esac
}

# ====== Shards Menu ====== #
shards_menu() {
  echo "# ===== Shards ===== #"
  echo ""
  echo "1) Get all shards"
  echo "2) Get yellow shards"
  echo "3) Get red shards"
  read -r -p "Select an option: " shards_choice
  case "$shards_choice" in
  1) curl -XGET "$AUTH_FLAGS" -u $ES_USER:"$ES_PW" "$ES_URL/_cat/shards?v" ;;
  2) curl -XGET "$AUTH_FLAGS" -u $ES_USER:"$ES_PW" "$ES_URL/_cat/shards?v&health=yellow" ;;
  3) curl -XGET "$AUTH_FLAGS" -u $ES_USER:"$ES_PW" "$ES_URL/_cat/shards?v&health=red" ;;
  *) echo "Invalid choice." ;;
  esac
}

# ====== Indices Menu ====== #
indices_menu() {
  echo "# ===== Indices ===== #"
  echo ""
  echo "1) Index size (desc)"
  echo "2) Index shards (desc)"
  echo "3) Index name (desc)"
  read -r -p "Select an option: " indices_choice
  case "$indices_choice" in
  1) curl -XGET "$AUTH_FLAGS" -u $ES_USER:"$ES_PW" "$ES_URL/_cat/indices?v&s=store.size:desc" ;;
  2) curl -XGET "$AUTH_FLAGS" -u $ES_USER:"$ES_PW" "$ES_URL/_cat/indices?v&s=pri:desc" ;;
  3) curl -XGET "$AUTH_FLAGS" -u $ES_USER:"$ES_PW" "$ES_URL/_cat/indices?v&s=index:desc" ;;
  *) echo "Invalid choice." ;;
  esac
}

# ====== Messages Menu ====== #
messages_menu() {
  echo "# ===== Messages ===== #"
  echo ""
  echo "1) Local messages"
  echo "2) Remote messages"
  echo "3) Cross-cluster messages"
  read -r -p "Select an option: " messages_choice

  case "$messages_choice" in
  1)
    echo ""
    echo "Can be comma-separated, or use wildcard (*)"
    read -r -p "Enter local index name: " index
    curl -XGET "$AUTH_FLAGS" -u $ES_USER:"$ES_PW" "$ES_URL/$index/_search?pretty"
    ;;

  2)
    echo ""
    read -r -p "Enter full remote Elasticsearch URL (Ex. https://remotehost:9200): " remote_url
    read -r -p "Enter remote index name: " index
    curl -XGET "$AUTH_FLAGS" -u $ES_USER:"$ES_PW" "$remote_url/$index/_search?pretty"
    ;;

  3)
    echo ""
    echo "Cross-cluster requires remote cluster alias configured in elasticsearch.yml"
    echo "Can be comma-separated, or use wildcard (*)"
    echo ""
    read -r -p "Enter cross-cluster alias (Ex. bob_1): " cluster_alias
    read -r -p "Enter index name: " index
    curl -XGET "$AUTH_FLAGS" -u $ES_USER:"$ES_PW" "$ES_URL/${cluster_alias}:$index/_search?pretty"
    ;;

  *)
    echo "Invalid choice."
    ;;
  esac
}

# ====== Maintenance Menu ====== #
maintenance_menu() {
  echo "# ===== Maintenance ===== #"
  echo ""
  echo "1) Cluster"
  echo "2) Shards"
  echo "3) Indices"
  read -r -p "Select an option: " maintenance_choice
  case "$maintenance_choice" in
  1) maintenance_cluster_menu ;;
  2) maintenance_shards_menu ;;
  3) maintenance_indices_menu ;;
  *) echo "Invalid choice." ;;
  esac
}

maintenance_cluster_menu() {
  echo ""
  echo "Maintenance > Cluster"
  echo "1) Set to primaries"
  echo "2) Set to null"
  read -r -p "Select an option: " m_cluster_choice
  case "$m_cluster_choice" in
  1) curl -XGET "$AUTH_FLAGS" -u $ES_USER:"$ES_PW" -X PUT "$ES_URL/_cluster/settings" -H 'Content-Type: application/json' -d '{"persistent":{"cluster.routing.allocation.enable":"primaries"}}' ;;
  2) curl -XGET "$AUTH_FLAGS" -u $ES_USER:"$ES_PW" -X PUT "$ES_URL/_cluster/settings" -H 'Content-Type: application/json' -d '{"persistent":{"cluster.routing.allocation.enable":null}}' ;;
  *) echo "Invalid choice." ;;
  esac
}

maintenance_shards_menu() {
  echo ""
  echo "Maintenance > Shards"
  echo "1) Reroute retry"
  read -r -p "Select an option: " m_shards_choice
  case "$m_shards_choice" in
  1) curl -XPOST "$AUTH_FLAGS" -u $ES_USER:"$ES_PW" "$ES_URL/_cluster/reroute?retry_failed=true" ;;
  *) echo "Invalid choice." ;;
  esac
}

maintenance_indices_menu() {
  echo "Maintenance > Indices"
  echo ""
  echo "1) Fill"
  echo "2) Fill"
  read -r -p "Select an option: " m_indices_choice
  case "$m_indices_choice" in
  1) echo "Placeholder: Implement 'fill' logic for indices #1" ;;
  2) echo "Placeholder: Implement 'fill' logic for indices #2" ;;
  *) echo "Invalid choice." ;;
  esac
}

# ====== Main Menu ====== #
while true; do
  echo "# ===== Main Menu ===== #"
  echo ""
  echo "1) Cluster"
  echo "2) Shards"
  echo "3) Indices"
  echo "4) Messages"
  echo -e "963) Maintenance ${RED}!! DANGER !!${NC}"
  echo "0) Exit"
  echo ""

  read -r -p "Select an option: " main_choice

  case "$main_choice" in
  1) cluster_menu ;;
  2) shards_menu ;;
  3) indices_menu ;;
  4) messages_menu ;;
  963) maintenance_menu ;;
  0)
    echo "Exiting..."
    exit 0
    ;;
  *) echo "Invalid choice." ;;
  esac
done
