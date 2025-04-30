#!/bin/bash

# ================== READ ME ================== #
# Elastic Cluster Maintenance Script
# Uses curl with client cert.
#
# Modify variables as needed.
# ================== READ ME ================== #

# ====== Variables ====== #
ES_URL="http://localhost:9200"

# ====== PKI Locations ====== #
CA_CERT="/path/to/ca.cert"
ES_CERT="/path/to/es.cert"
ES_KEY="/path/to/es.key"

# ====== Colors ====== #
RED='\033[0;31m' # Red text
NC='\033[0m'     # No Color (reset)

# ========= Script ========= #
echo "
 _______ __               __   __                                       
|    ___|  |.---.-.-----.|  |_|__|.----.                                  
|    ___|  ||  _  |__ --||   _|  ||  __|                                  
|_______|__||___._|_____||____|__||____|                                 
                                                                         
 _______ __ __        __               _______                           
|   _   |  |  |______|__|.-----.______|       |.-----.-----.            
|       |  |  |______|  ||     |______|   -   ||     |  -__|            
|___|___|__|__|      |__||__|__|      |_______||__|__|_____|            
                                                                         
 _______         __         __                                          
|   |   |.---.-.|__|.-----.|  |_.-----.-----.---.-.-----.----.-----.    
|       ||  _  ||  ||     ||   _|  -__|     |  _  |     |  __|  -__|    
|__|_|__||___._||__||__|__||____|_____|__|__|___._|__|__|____|_____|    
                                                                         
 _______               __                                               
|_     _|.-----.-----.|  |                                              
  |   |  |  _  |  _  ||  |                                              
  |___|  |_____|_____||__|                                              
"

echo "** Welcome to the Elastic Help Tool! **"
echo ""
echo "You may exit at any time with <CTRL+C>"

echo ""

echo -e "******************** ${RED}!!!${NC} ********************"
echo -e "   Please note that the ${RED}Maintenance${NC} options"
echo -e "       can cause ${RED}harm${NC} to your cluster!!!"
echo -e "******************** ${RED}!!!${NC} ********************"

echo ""
echo "You may hardcode usernames & passwords--not recommended!"

# You may hardcode these; 
# Just remember to comment out the read below for whichever you want to hardcode!
ES_USER="elastic"
#ES_PW="changeme123"

echo ""

#read -r -p "Enter your ES username: " ES_USER
read -r -p "Enter your ES password: " ES_PW

echo ""

# ========= AUTH Method ========= #
echo "Select authentication components to use (separate multiple with commas):"
echo "1) Use --CA_CERT"
echo "2) Use --cert"
echo "3) Use --key"
echo "4) No certs (use --insecure) [this overrides everything else!]"
read -r -p "Your selection (e.g. 1,2,3): " auth_selection

AUTH_FLAGS=""
IFS=',' read -ra OPTIONS <<< "$auth_selection"
for opt in "${OPTIONS[@]}"; do
  case "$opt" in
    1) AUTH_FLAGS+=" --CA_CERT $CA_CERT" ;;
    2) AUTH_FLAGS+=" --cert $ES_CERT" ;;
    3) AUTH_FLAGS+=" --key $ES_KEY" ;;
    4) AUTH_FLAGS="--insecure" ; break ;;
    *) echo "Unknown option $opt ignored." ;;
  esac
done

# ====== Functions ====== #
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
