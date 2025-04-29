#!/bin/bash

# ================== READ ME ================== #
# Elastic Cluster Maintenance Script
# Uses curl with client cert if needed. 
#
# Modify variables as needed.
# ================== READ ME ================== #

# ====== Variables ====== #
ES_URL="http://localhost:9200"
ES_USER="elastic"
ES_PW="changeme123"
CACERT="/path/to/ca.cert"

# ====== Colors ====== #
RED='\033[0;31m'   # Red text
NC='\033[0m'       # No Color (reset)

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

# ====== Functions ====== #
cluster_menu() {
  echo "Cluster:"
  echo "1) Health"
  echo "2) Health Report"
  echo "3) Nodes"
  echo "4) Settings"

  read -r -p "Select an option: " cluster_choice
  
  case "$cluster_choice" in
    1) curl -XGET --cacert $CACERT -u $ES_USER:$ES_PW "$ES_URL/_cluster/health" ;;
    2) curl -XGET --cacert $CACERT -u $ES_USER:$ES_PW "$ES_URL/_cluster/health_report" ;;
    3) curl -XGET --cacert $CACERT -u $ES_USER:$ES_PW "$ES_URL/_nodes" ;;
    4) curl -XGET --cacert $CACERT -u $ES_USER:$ES_PW "$ES_URL/_cluster/settings" ;;
    *) echo "Invalid choice." ;;
  esac
}

shards_menu() {
  echo "# ===== Shards ===== #"
  echo ""
  echo "1) Get all shards"
  echo "2) Get yellow shards"
  echo "3) Get red shards"
  read -r -p "Select an option: " shards_choice
  case "$shards_choice" in
    1) curl -XGET --cacert $CACERT -u $ES_USER:$ES_PW "$ES_URL/_cat/shards?v" ;;
    2) curl -XGET --cacert $CACERT -u $ES_USER:$ES_PW "$ES_URL/_cat/shards?v&health=yellow" ;;
    3) curl -XGET --cacert $CACERT -u $ES_USER:$ES_PW "$ES_URL/_cat/shards?v&health=red" ;;
    *) echo "Invalid choice." ;;
  esac
}

indices_menu() {
  echo "# ===== Indices ===== #"
  echo ""
  echo "1) Index size (desc)"
  echo "2) Index shards (desc)"
  echo "3) Index name (desc)"
  read -r -p "Select an option: " indices_choice
  case "$indices_choice" in
    1) curl -XGET --cacert $CACERT -u $ES_USER:$ES_PW "$ES_URL/_cat/indices?v&s=store.size:desc" ;;
    2) curl -XGET --cacert $CACERT -u $ES_USER:$ES_PW "$ES_URL/_cat/indices?v&s=pri:desc" ;;
    3) curl -XGET --cacert $CACERT -u $ES_USER:$ES_PW "$ES_URL/_cat/indices?v&s=index:desc" ;;
    *) echo "Invalid choice." ;;
  esac
}

maintenance_cluster_menu() {
  echo "Maintenance > Cluster:"
  echo "1) Set to primaries"
  echo "2) Set to null"
  read -r -p "Select an option: " m_cluster_choice
  case "$m_cluster_choice" in
    1) curl -XGET --cacert $CACERT -u $ES_USER:$ES_PW -X PUT "$ES_URL/_cluster/settings" -H 'Content-Type: application/json' -d '{"persistent":{"cluster.routing.allocation.enable":"primaries"}}' ;;
    2) curl -XGET --cacert $CACERT -u $ES_USER:$ES_PW -X PUT "$ES_URL/_cluster/settings" -H 'Content-Type: application/json' -d '{"persistent":{"cluster.routing.allocation.enable":null}}' ;;
    *) echo "Invalid choice." ;;
  esac
}

maintenance_shards_menu() {
  echo "Maintenance > Shards:"
  echo "1) Reroute retry"
  read -r -p "Select an option: " m_shards_choice
  case "$m_shards_choice" in
    1) curl -XPOST --cacert $CACERT -u $ES_USER:$ES_PW "$ES_URL/_cluster/reroute?retry_failed=true" ;;
    *) echo "Invalid choice." ;;
  esac
}

maintenance_indices_menu() {
  echo "Maintenance > Indices:"
  echo "1) Fill"
  echo "2) Fill"
  read -r -p "Select an option: " m_indices_choice
  case "$m_indices_choice" in
    1) echo "Placeholder: Implement 'fill' logic for indices #1" ;;
    2) echo "Placeholder: Implement 'fill' logic for indices #2" ;;
    *) echo "Invalid choice." ;;
  esac
}

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

# ====== Main Menu ====== #
while true; do
  echo "# ===== Main Menu ===== #"
  echo ""
  echo "1) Cluster"
  echo "2) Shards"
  echo "3) Indices"
  echo -e "9) Maintenance ${RED}!! DANGER !!${NC}"
  echo "0) Exit"
  echo ""

  read -r -p "Select an option: " main_choice
  case "$main_choice" in
    1) cluster_menu ;;
    2) shards_menu ;;
    3) indices_menu ;;
    9) maintenance_menu ;;
    0) echo "Exiting..."; exit 0 ;;
    *) echo "Invalid choice." ;;
  esac
done
