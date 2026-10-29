#!/usr/bin/env bash
set -uo pipefail
readonly LVL_SUCCESS=1
readonly LVL_INFO=2
readonly LVL_WARNING=3
readonly LVL_ERROR=4

#########

readonly COLOR_RESET="\033[0m"
readonly COLOR_GREEN="\033[32m"
readonly COLOR_BLUE="\033[34m"
readonly COLOR_YELLOW="\033[33m"
readonly COLOR_RED="\033[31m"
#########



#################################################
#### logs and error handling project            #
### author = "ali hossam"                       #
## date "26/10/2026"                            #
#################################################

#directory init
init_directories() {
	cd $1
	if [[ ! -d "output" || ! -d "data" || ! -d "logs" ]]; then 
mkdir -p  data output logs
	fi
}








###########################################################################################################################################
log_message() {
##we defined the lvl ^
local LVL="$1"
local message="$2"
local timetamp

timetamp=$(date "+%Y-%m-%d %H:%M:%S")

mkdir -p logs

case "$LVL" in
	"$LVL_SUCCESS")
		echo -e "${COLOR_GREEN}[$timetamp] [SUCCESS] :$message${COLOR_RESET}" | tee -a logs/project.log
		;;
	"$LVL_INFO")
		echo -e "${COLOR_BLUE}[$timetamp] [INFO] :$message${COLOR_RESET}" | tee -a logs/project.log
	        ;;
	"$LVL_WARNING")
		echo -e "${COLOR_YELLOW}[$timetamp] [WARNING] :$message${COLOR_RESET}" | tee -a logs/project.log
                ;;
	"$LVL_ERROR")
		echo -e "${COLOR_RED}[$timetamp] [ERROR] :$message${COLOR_RESET}" | tee -a logs/project.log
		;;
	esac
}
trap 'log_message "$LVL_ERROR" " An unexpected error occured (line $LINENO)"'
trap 'echo ""; log_message "$LVL_ERROR" "SCRIPT INTERUPTED BY USER. "; exit 130 ' INT TERM
##############################################################################################################################################
validate_file() {
local file_path="$1"

if [[ -z "$file_path" ]]; then
	log_message "$LVL_ERROR" "NO FILE PATH !"
	return 1
fi

if [[ ! -f "$file_path" ]]; then
	log_message "$LVL_ERROR" "FILE NOT EXIST! "
       return 1
fi
if [[ ! -s "$file_path" ]]; then
	log_message "$LVL_WARNING" "FILE IS EXIST BUT EMPTY !"
	return 1 
fi

log_message "$LVL_SUCCESS" "FILE IS VALIDATED SUCCESSFULY!"
return 0
}
################################################################################################################################################
#############DATA PROCCESING#####################
count_lines() {
local file_path="$1"
if ! validate_file "$file_path" ;then
	log_message "$LVL_ERROR" "ERROR...FILE PASSED ERROR "
	return 1
fi
log_message "$LVL_SUCCESS" "LINES COUNTING....."

local line_count
line_count=$(wc -l < "$file_path" | tr -d ' ')
log_message "$LVL_SUCCESS" "line count : $line_count"
return 0
}
##################
####################extract columns
extract_columns() {
	local file_path="$1"
	local columns="$2"
        local delimiter="${3:-,}"	

if ! validate_file "$file_path"; then
	log_message "$LVL_ERROR" "ERROR WITH PASSED FILE.."
	return 1
fi

if [[ -z "$columns" ]]; then 
	log_message "$LVL_ERROR" "COMLUMNS NOT SELECTED..!"
	return 1
fi
log_message "$LVL_INFO" "COLUMNS SELECTED...($columns)"


awk -F"$delimiter" -v OFS="$delimiter" -v cols="$columns" '
BEGIN {
	n =split(cols, c, ",")
}
{out = ""
	for (i = 1;i <= n ; i++) {
		idx =c[i]
		if (idx <=NF){
			out = (out == "" ? $idx : out OFS $idx)
}
}
if (out != "") print out
}' "$file_path"
log_message "$LVL_SUCCESS" "EXTRACTED SUCCESSFULY !"
return 0
}
##################################################################################################
##########filter data
filter_data() {
	local file_path="$1"
	local pattern="$2"
if ! validate_file "$file_path" ;then 
log_message "$LVL_ERROR" "ERROR WITH PASSED FILE.."
return 1
fi

if [[ -z "$pattern" ]]; then
	log_message "$LVL_ERROR" "NO THING TO SEARCH ABOUT..."
	return 1
fi
log_message "$LVL_INFO" "SEARCHING...."
local result
if result=$(grep -E -- "$pattern" "$file_path") ; then
        echo "$result"
        log_message "$LVL_SUCCESS" "FOUND SUCCESSFLY"
	return 0 
else 
	log_message "$LVL_WARNING" "NOT FOUND $pattern "
	return 1
fi
}
#################################################################################
##########stats cal
calculate_stats() {
	local file_path="$1"
	local col_num="$2"
	local delimiter="${3:-,}"

	if ! validate_file "$file_path"; then
		log_message "$LVL_ERROR" "ERROR WITH PASSED FILE ..!"
		return 1
	fi

	if [[ -z "$col_num" ]]; then
		log_message "$LVL_ERROR" "COLUMN NUMBER NOT FOUND !"
		return 1
	fi
log_message "$LVL_INFO" "CALCU;ATING STATS FOR COLUMN NUMBER $col_num..."

local stats_result
stats_result=$(awk -F"$delimiter" -v col="$col_num" '
BEGIN{
	min = 0;
	max = 0;
	sum = 0;
	count = 0;
}

NR > 1 { 
	val =$col;
	gsub(/^[ \t]+|[ \t]+$/, "",val);
	if (val ~ /^[0-9]+([.,][0-9]+)?$/) {
		gsub(/,/, ".",val);
		num = val+ 0;
		if (count==0){
			min = num;
			max = num;
}else {
	if (num < min) min = num;
	if (num > max) max = num;
}
sum +=num
count++;
}
}
END {
	if (count > 0) {
		avg = sum / count;
		printf "Statistics (Column %d)\n----------------------\nCount : %d\nMinimum : %.2f\nMaximum : %.2f\nAverage : %.2f\n",col,count,min,max,avg;
} else
 {print "No numeric data found in Column " col;}
}' "$file_path")
echo -e "$stats_result"
log_message "$LVL_SUCCESS" "Column number ($col_num ) calculated Successfuly"
return 0
}

######################################################################################################
###########remove dup
remove_duplicates() {
	local file_path="$1"
	local output_path="${2:-output/cleaned_file.csv}"

	if ! validate_file "$file_path"; then
		log_message "$LVL_ERROR" "ERROR WITH PASSED FILE !"
		return 1
	fi
	log_message "$LVL_INFO" "Removing duplicates lines ..."

	if sort -u "$file_path" > "$output_path"; then
		log_message "$LVL_SUCCESS" "Removing duplicates is done and file saved in $output_path"
		return 0
	else
		log_message "$LVL_ERROR" "ERROR HAPPEND WHILE REMOVING !"
		return 1
	fi
	}
#######################################################################################################

merge_files() {
	local file1="$1"
	local file2="$2"

	local output_path="${3:-output/merged_file.csv}"

	if ! validate_file "$file1"; then
		log_message "$LVL_ERROR" "ERROR IN FILE 1"
                return 1
	fi

	if ! validate_file "$file2"; then
		log_message "$LVL_ERROR" "ERROR IN FILE 2"
		return 1
	fi
	log_message "$LVL_INFO" "MERGING..."

	if cat "$file1" "$file2" > "$output_path"; then
		log_message "$LVL_SUCCESS" "MERGED AND SAVED IN ($output_path)"
		return 0
	else
		log_message "$LVL_ERROR" "ERROR WHILE MERGING"
		return 1
	fi
}

######################################################################################################
command_exists() {
	local cmd="$1"
	 
	if [[ -z "$cmd" ]]; then
		log_message "$LVL_ERROR" "COMMAND NOT SELECTED !"
		return 1
	fi
	if command -v "$cmd" &> /dev/null; then
		log_message "$LVL_SUCCESS" "$cmd available and installed"
		return 0
	else 
		log_message "$LVL_ERROR" "$cmd unavailable or not exist in PATH !"
		return 1
	fi
}

################################
###
check_dependencies() {
local required_tools=("awk" "grep" "sort" "wc" "cut")
local missing_tools=0
log_message "$LVL_INFO" "loading..."

for tool in "${required_tools[@]}";do
	if ! command_exists "$tool"; then
		((missing_tools +=1))
	fi
done
 
if (( missing_tools > 0 )); then
	log_message "$LVL_ERROR" "MISSING TOOLS : $missing_tools"
	return 1
fi

log_message "$LVL_SUCCESS" "ALL TOOLS AVAILABLE "
return 0

}


################################
init_directories() {
	local dirs=("data" "output" "logs")

	log_message "$LVL_INFO" "LOADING..."

	for dir in "${dirs[@]}"; do
		if [[ ! -d "$dir" ]]; then
			if mkdir -p "$dir"; then 
				log_message "$LVL_SUCCESS" "NEW DIR : $dir added succesfuly"
			else 
				log_message "$LVL_ERROR" "ERROR WITH MAKING DIR : $dir "
				return 1
			fi
		else
			log_message "$LVL_INFO" "$dir is already exist"
		fi
	done
	log_message "$LVL_SUCCESS" "all dir is done successfuly !"
return 0
}
################################################################################
main_menu() {
	while true; do 
		clear
		echo "========================================================="
		echo "|            Bash Data Processing Toolkit               | "
		echo "========================================================="
		echo "| 1. Count lines                                        |"
		echo "| 2. Extract csv Columns                                |"
		echo "| 3.Filter Data                                         |"
		echo "| 4.Calculate Statistics                                |"
		echo "| 5. Merge Files                                        |"
		echo "| 6.Remove Duplicates                                   |"
		echo "| 7.check Dependencies                                  |"
		echo "| 8.Initialize Directories                              |"
		echo "| 9.Exit                                                |"
                echo "========================================================="
	
		echo ""
		echo "" 
		
    read -p "Choose an option : " choice

    case "$choice" in
        1)
            read -r -p "Enter the file path" file_path
            count_lines "$file_path"
            ;;
        2)
            read -r -p "Enter the file path" file_path
            read -p "Enter the columns number " cols
            read -p "Enter the delimter" delim
            extract_columns "$file_path" "$cols" "$delim"
            ;;
        3)
            read -r -p "Enter the file path" file_path
            read -p "Enter the pattern " pattern
            filter_data "$file_path" "$pattern"
            ;;
        4)
            read -r -p "Enter the file path " file_path
            read -p "Enter the column number" col_num
            read -p "Enter the delimter" delim
            calculate_stats "$file_path" "$col_num" "$delim"
            ;;
        5)
            read -r -p "Enter the first file path " file1
            read -r -p "Enter the second file path " file2
            merge_files "$file1" "$file2"
            ;;
        6)
            read -r -p "Enter the file " file_path
            remove_duplicates "$file_path"
            ;;
        7)
            check_dependencies
            ;;
        8)
            init_directories
            ;;
        9)
            echo "Exiting... Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid option! Please choose between 1 and 9."
            ;;
    esac

    echo ""
   read -r -p "Press Enter to continue..."
done
}
init_directories
main_menu
		
