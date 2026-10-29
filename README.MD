# Bash Data Processing & Automation Toolkit

## Description
An interactive Bash toolkit for processing text and CSV files: counting lines,
extracting columns, filtering with regex, calculating statistics, merging files,
and removing duplicates. Includes colored logging, error handling, and input validation.

## Requirements
- Linux with Bash 4+
- awk, grep, sort, wc, cut

## Installation
```bash

cd bash-data-processing
chmod +x project_bash_script.sh
```

## Usage
```bash
./project_bash_script.sh
```
Choose an option from the menu (1-9).

## Functions
| Function | Description |
|---|---|
| `count_lines()` | Counts the lines in a file |
| `extract_columns()` | Extracts given columns from a CSV file |
| `filter_data()` | Filters lines matching a regex |
| `calculate_stats()` | Count, min, max, average of a numeric column |
| `merge_files()` | Merges multiple files into output/merged.txt |
| `remove_deduplicate()` | Removes duplicate lines and reports the count |
| `command_exists()` | Checks if a command is installed |
| `check_dependencies()` | Checks all required commands |
| `init_directories()` | Creates data/, output/, logs/ |

## Examples
- Count lines: choose 1, then enter `data/sample.txt`
- Extract columns: choose 2, file `data/data.csv`, columns `1,3`
- Filter: choose 3, file `data/sample.txt`, pattern `^L`

## Test Cases
### Valid
| Test | Input | Expected |
|---|---|---|
| Count lines | data/sample.txt | Number of lines |
| Extract columns | data.csv, 1,3 | Columns 1 and 3 |
| Regex filter | sample.txt, ^L | Lines starting with L |
| Merge | 2 existing files | output/merged.txt created |
| Deduplicate | sample.txt | Duplicates removed, count shown |

### Invalid
| Test | Input | Expected |
|---|---|---|
| Missing file | nofile.txt | [ERROR] File not found |
| Empty file | empty.txt | [WARNING] File is empty |
| Bad column | data.csv, 8 | [ERROR] Invalid column number: 8 |
| Bad menu input | abc | [ERROR] Invalid option |
| Out of range | 15 | [ERROR] Invalid choice |
| Ctrl+C | during run | [ERROR] Script interrupted by user |
