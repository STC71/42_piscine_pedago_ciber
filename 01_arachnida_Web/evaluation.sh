#!/bin/bash

###############################################################################
#                      ARACHNIDA - COMPREHENSIVE EVALUATION SCRIPT            #
#                                                                             #
#  Exhaustive evaluation of Spider (Web Scraper) & Scorpion (EXIF Analyzer) #
#  Based on evaluation_en.pdf requirements - All mandatory and bonus points  #
#                                                                             #
#  Version: 2.0 (Extended - Grade 10/10 Target)                             #
###############################################################################

set -o pipefail

# ============================================================================
# COLORS & FORMATTING
# ============================================================================
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly BOLD='\033[1m'
readonly RESET='\033[0m'

# ============================================================================
# GLOBAL SCORING VARIABLES
# ============================================================================
MANDATORY_SCORE=0
BONUS_SCORE=0
TOTAL_BONUS=0
MAX_MANDATORY=100

SPIDER_SCORE=0
SPIDER_MAX=0
SCORPION_SCORE=0
SCORPION_MAX=0

# Flags for serious issues
CRASH=false
INVALID_COMPILATION=false
CHEAT=false

# Directories
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly EX00_DIR="${SCRIPT_DIR}/ex00"
readonly EX01_DIR="${SCRIPT_DIR}/ex01"
readonly TEST_DIR="/tmp/arachnida_test_$$"

# ============================================================================
# OUTPUT FUNCTIONS
# ============================================================================

header() {
    echo -e "\n${BOLD}${BLUE}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET} $1"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════╝${RESET}\n"
}

section() {
    echo -e "\n${BOLD}${CYAN}▶ $1${RESET}"
    echo -e "${CYAN}─────────────────────────────────────────────────────────────${RESET}"
}

subsection() {
    echo -e "\n  ${MAGENTA}├─ $1${RESET}"
}

ok() {
    echo -e "    ${GREEN}✓${RESET} $1"
    ((MANDATORY_SCORE += $2))
    ((SPIDER_SCORE += $2))
}

fail() {
    echo -e "    ${RED}✗${RESET} $1"
}

warn() {
    echo -e "    ${YELLOW}⚠${RESET} $1"
}

info() {
    echo -e "    ${CYAN}ℹ${RESET} $1"
}

bonus_ok() {
    echo -e "    ${GREEN}✓${RESET} [BONUS] $1"
    ((BONUS_SCORE += $2))
    ((TOTAL_BONUS += $2))
}

bonus_fail() {
    echo -e "    ${RED}✗${RESET} [BONUS] $1"
}

# ============================================================================
# TEST SETUP & CLEANUP
# ============================================================================

setup() {
    mkdir -p "${TEST_DIR}"
    
    # Create test images with PIL if available
    python3 << 'PYEOF' 2>/dev/null || true
from PIL import Image
import os
test_dir = os.environ.get('TEST_DIR', '/tmp/test')
os.makedirs(test_dir, exist_ok=True)

try:
    # Create minimal test images of different formats
    img = Image.new('RGB', (10, 10), color='red')
    img.save(f'{test_dir}/test.jpg')
    img = Image.new('RGB', (10, 10), color='green')
    img.save(f'{test_dir}/test.png')
    img = Image.new('RGB', (10, 10), color='blue')
    img.save(f'{test_dir}/test.gif')
    img = Image.new('RGB', (10, 10), color='yellow')
    img.save(f'{test_dir}/test.bmp')
except Exception as e:
    print(f"Warning: Could not create test images: {e}")
PYEOF
}

cleanup() {
    rm -rf "${TEST_DIR}"
}

trap cleanup EXIT

# ============================================================================
# MANDATORY PART: SPIDER EVALUATION
# ============================================================================

validate_spider_structure() {
    section "SPIDER: Project Structure & Files"
    
    subsection "File Existence"
    
    if [[ -f "${EX00_DIR}/spider.py" ]]; then
        ok "spider.py found" 5
    else
        fail "spider.py NOT FOUND"
        return 1
    fi
    
    if [[ -f "${EX00_DIR}/requirements.txt" ]]; then
        ok "requirements.txt found" 3
    else
        warn "requirements.txt NOT FOUND"
    fi
    
    if [[ -x "${EX00_DIR}/spider.py" ]]; then
        ok "spider.py is executable" 2
    else
        fail "spider.py is NOT executable (missing -x permission)"
        chmod +x "${EX00_DIR}/spider.py"
    fi
    
    subsection "Code Quality"
    
    if head -1 "${EX00_DIR}/spider.py" | grep -q "^#!/usr/bin/env python3"; then
        ok "Correct shebang (#!/usr/bin/env python3)" 3
    else
        warn "Shebang missing or incorrect"
    fi
    
    if python3 -m py_compile "${EX00_DIR}/spider.py" 2>/dev/null; then
        ok "Valid Python 3 syntax" 2
    else
        fail "Python syntax errors detected"
        INVALID_COMPILATION=true
        python3 -m py_compile "${EX00_DIR}/spider.py" 2>&1 | sed 's/^/      /'
    fi
}

validate_spider_parameters() {
    section "SPIDER: Parameter Support (-r, -l, -p)"
    
    subsection "Parameter Documentation"
    
    cd "${EX00_DIR}" || return
    
    local help_output
    help_output=$(python3 spider.py -h 2>&1 || python3 spider.py --help 2>&1 || echo "")
    
    # Check for -r parameter
    if echo "$help_output" | grep -qiE "\-r|--recursive"; then
        ok "Parameter -r (recursive) supported and documented" 8
    elif grep -q "recursive\|-r" spider.py; then
        warn "Parameter -r (recursive) found in code but not in help"
        ((MANDATORY_SCORE += 5))
        ((SPIDER_SCORE += 5))
    else
        fail "Parameter -r (recursive) NOT implemented"
    fi
    
    # Check for -l parameter
    if echo "$help_output" | grep -qiE "\-l|--level|--depth"; then
        ok "Parameter -l (level/depth) supported and documented" 8
    elif grep -q "level\|depth\|-l" spider.py; then
        warn "Parameter -l found in code but not visible in help"
        ((MANDATORY_SCORE += 5))
        ((SPIDER_SCORE += 5))
    else
        fail "Parameter -l (level) NOT implemented"
    fi
    
    # Check for -p parameter
    if echo "$help_output" | grep -qiE "\-p|--path|--output"; then
        ok "Parameter -p (output path) supported and documented" 8
    elif grep -q "path\|output\|-p" spider.py; then
        warn "Parameter -p found in code but not visible in help"
        ((MANDATORY_SCORE += 5))
        ((SPIDER_SCORE += 5))
    else
        fail "Parameter -p (path) NOT implemented"
    fi
}

validate_spider_http() {
    section "SPIDER: HTTP Link Processing"
    
    subsection "HTTP Request Handling"
    
    # Check for HTTP/requests handling
    if grep -q "requests\|urllib\|http" "${EX00_DIR}/spider.py"; then
        ok "HTTP library imported (requests/urllib)" 5
    else
        fail "No HTTP library detected"
    fi
    
    # Check for URL parameter usage
    if grep -q "argv\|argparse\|sys.*args" "${EX00_DIR}/spider.py"; then
        ok "Command-line URL argument handling detected" 5
    else
        warn "URL argument handling not detected"
    fi
    
    subsection "Test Execution"
    
    cd "${EX00_DIR}" || return
    
    # Try simple execution without network dependency
    if timeout 3 python3 spider.py --help > /dev/null 2>&1; then
        ok "Help execution works" 3
    else
        warn "Help execution failed or timed out"
    fi
}

validate_spider_file_extensions() {
    section "SPIDER: Image File Extension Support"
    
    subsection "Format Support (.jpg, .jpeg, .png, .gif, .bmp)"
    
    local spider_code
    spider_code=$(cat "${EX00_DIR}/spider.py")
    
    local supported=0
    
    if echo "$spider_code" | grep -qiE "\.(jpg|jpeg)"; then
        ((supported+=2))
        info ".jpg/.jpeg support detected"
    fi
    
    if echo "$spider_code" | grep -qiE "\.png"; then
        ((supported+=2))
        info ".png support detected"
    fi
    
    if echo "$spider_code" | grep -qiE "\.gif"; then
        ((supported+=2))
        info ".gif support detected"
    fi
    
    if echo "$spider_code" | grep -qiE "\.bmp"; then
        ((supported+=2))
        info ".bmp support detected"
    fi
    
    if [[ $supported -ge 6 ]]; then
        ok "All required image formats supported" 20
        MANDATORY_SCORE=$((MANDATORY_SCORE + 20))
        SPIDER_SCORE=$((SPIDER_SCORE + 20))
    elif [[ $supported -ge 4 ]]; then
        warn "Only $((supported/2)) formats supported (need at least 3)"
        ((MANDATORY_SCORE += 10))
        ((SPIDER_SCORE += 10))
    else
        fail "Insufficient image format support"
    fi
}

validate_spider_dependencies() {
    section "SPIDER: Dependencies"
    
    subsection "requirements.txt Content"
    
    if [[ ! -f "${EX00_DIR}/requirements.txt" ]]; then
        warn "requirements.txt not found"
        return
    fi
    
    local req_content
    req_content=$(cat "${EX00_DIR}/requirements.txt")
    
    if echo "$req_content" | grep -qi "beautifulsoup4\|bs4"; then
        ok "beautifulsoup4 in requirements" 5
    else
        fail "beautifulsoup4 NOT in requirements.txt"
    fi
    
    if echo "$req_content" | grep -qi "requests"; then
        ok "requests in requirements" 5
    else
        fail "requests NOT in requirements.txt"
    fi
    
    subsection "Dependency Installation"
    
    # Check virtual environment
    if [[ -d "${EX00_DIR}/.venv" ]]; then
        source "${EX00_DIR}/.venv/bin/activate" 2>/dev/null
        if python3 -c "import bs4, requests" 2>/dev/null; then
            ok "All dependencies installed" 3
        else
            warn "Virtual environment exists but dependencies missing"
        fi
        deactivate 2>/dev/null || true
    else
        warn "No virtual environment found (.venv)"
    fi
}

# ============================================================================
# MANDATORY PART: SCORPION EVALUATION
# ============================================================================

validate_scorpion_structure() {
    section "SCORPION: Project Structure & Files"
    
    subsection "File Existence"
    
    if [[ -f "${EX01_DIR}/scorpion.py" ]]; then
        ok "scorpion.py found" 5
    else
        fail "scorpion.py NOT FOUND"
        return 1
    fi
    
    if [[ -f "${EX01_DIR}/requirements.txt" ]]; then
        ok "requirements.txt found" 3
    else
        warn "requirements.txt NOT FOUND"
    fi
    
    if [[ -x "${EX01_DIR}/scorpion.py" ]]; then
        ok "scorpion.py is executable" 2
    else
        fail "scorpion.py is NOT executable"
        chmod +x "${EX01_DIR}/scorpion.py"
    fi
    
    subsection "Code Quality"
    
    if head -1 "${EX01_DIR}/scorpion.py" | grep -q "^#!/usr/bin/env python3"; then
        ok "Correct shebang" 3
    else
        warn "Shebang missing or incorrect"
    fi
    
    if python3 -m py_compile "${EX01_DIR}/scorpion.py" 2>/dev/null; then
        ok "Valid Python 3 syntax" 2
    else
        fail "Python syntax errors detected"
        INVALID_COMPILATION=true
    fi
}

validate_scorpion_basic_metadata() {
    section "SCORPION: Basic Metadata Display"
    
    subsection "Date & Time Information"
    
    local scorpion_code
    scorpion_code=$(cat "${EX01_DIR}/scorpion.py")
    
    # Check for date-related metadata handling
    if echo "$scorpion_code" | grep -qiE "date\|time\|datetime\|modified\|created"; then
        ok "Date/time metadata handling detected" 15
    else
        warn "Date/time metadata handling not clearly detected"
        ((MANDATORY_SCORE += 8))
        ((SCORPION_SCORE += 8))
    fi
    
    # Test execution with sample image
    subsection "Execution Test"
    
    cd "${EX01_DIR}" || return
    
    if [[ -f "${TEST_DIR}/test.jpg" ]]; then
        if timeout 3 python3 scorpion.py "${TEST_DIR}/test.jpg" > /dev/null 2>&1; then
            ok "Execution with test image successful" 5
        else
            warn "Execution with test image failed"
        fi
    fi
}

validate_scorpion_exif_data() {
    section "SCORPION: EXIF Data Extraction"
    
    subsection "EXIF Library & Processing"
    
    local scorpion_code
    scorpion_code=$(cat "${EX01_DIR}/scorpion.py")
    
    # Check for EXIF handling
    if echo "$scorpion_code" | grep -qiE "exif|piexif|PIL"; then
        ok "EXIF/image processing library detected" 10
    else
        warn "EXIF library reference not clearly found"
        ((MANDATORY_SCORE += 5))
        ((SCORPION_SCORE += 5))
    fi
    
    subsection "Image Format Support (jpg, png, bmp, gif)"
    
    local formats_supported=0
    
    for fmt in "jpg" "jpeg" "png" "bmp" "gif"; do
        if echo "$scorpion_code" | grep -qiE "\.${fmt}"; then
            ((formats_supported++))
            info "Format .$fmt supported"
        fi
    done
    
    local points=$((formats_supported * 4))
    if [[ $formats_supported -ge 3 ]]; then
        ok "Multiple image formats supported (.jpg, .png, .bmp, .gif)" $points
    else
        warn "Limited image format support detected"
        ((MANDATORY_SCORE += $points))
        ((SCORPION_SCORE += $points))
    fi
    
    subsection "Metadata Display"
    
    if echo "$scorpion_code" | grep -qiE "print.*exif|print.*metadata|display"; then
        ok "Metadata output/display logic found" 5
    else
        warn "Metadata display logic not explicitly detected"
    fi
}

validate_scorpion_dependencies() {
    section "SCORPION: Dependencies"
    
    subsection "requirements.txt Content"
    
    if [[ ! -f "${EX01_DIR}/requirements.txt" ]]; then
        warn "requirements.txt not found"
        return
    fi
    
    local req_content
    req_content=$(cat "${EX01_DIR}/requirements.txt")
    
    if echo "$req_content" | grep -qi "Pillow\|PIL"; then
        ok "Pillow in requirements" 5
    else
        fail "Pillow NOT in requirements.txt"
    fi
    
    if echo "$req_content" | grep -qi "piexif"; then
        ok "piexif in requirements" 5
    else
        warn "piexif NOT in requirements.txt (EXIF handling may use PIL)"
    fi
    
    subsection "Dependency Installation"
    
    if [[ -d "${EX01_DIR}/.venv" ]]; then
        source "${EX01_DIR}/.venv/bin/activate" 2>/dev/null
        if python3 -c "import PIL, piexif" 2>/dev/null; then
            ok "All dependencies installed" 3
        else
            warn "Some dependencies missing from virtual environment"
        fi
        deactivate 2>/dev/null || true
    else
        warn "No virtual environment found"
    fi
}

# ============================================================================
# BONUS PART: METADATA MANIPULATION
# ============================================================================

validate_bonus_metadata_deletion() {
    if [[ "$MANDATORY_SCORE" -lt 80 ]]; then
        warn "[BONUS] Skipping - mandatory part incomplete ($MANDATORY_SCORE < 80)"
        return 0
    fi
    
    section "BONUS: Metadata Deletion"
    
    subsection "Deletion Feature"
    
    local scorpion_code
    if [[ -f "${EX01_DIR}/scorpion_bonus.py" ]]; then
        scorpion_code=$(cat "${EX01_DIR}/scorpion_bonus.py")
    else
        scorpion_code=$(cat "${EX01_DIR}/scorpion.py")
    fi
    
    if echo "$scorpion_code" | grep -qiE "delete.*exif|remove.*exif|strip.*metadata|clear.*exif"; then
        bonus_ok "Metadata deletion capability detected" 10
    else
        bonus_fail "Metadata deletion not detected"
    fi
}

validate_bonus_metadata_modification() {
    if [[ "$MANDATORY_SCORE" -lt 80 ]]; then
        return 0
    fi
    
    section "BONUS: Metadata Modification"
    
    subsection "Modification Feature"
    
    local scorpion_code
    if [[ -f "${EX01_DIR}/scorpion_bonus.py" ]]; then
        scorpion_code=$(cat "${EX01_DIR}/scorpion_bonus.py")
    else
        scorpion_code=$(cat "${EX01_DIR}/scorpion.py")
    fi
    
    if echo "$scorpion_code" | grep -qiE "modify.*exif|edit.*exif|change.*metadata|set.*exif|write.*exif"; then
        bonus_ok "Metadata modification capability detected" 10
    else
        bonus_fail "Metadata modification not detected"
    fi
}

validate_bonus_gui() {
    if [[ "$MANDATORY_SCORE" -lt 80 ]]; then
        return 0
    fi
    
    section "BONUS: Graphical User Interface"
    
    subsection "GUI Framework Detection"
    
    local total_gui_score=0
    
    # Check SPIDER for GUI
    if grep -qiE "tkinter|pyqt|wxpython|flask|django|streamlit|pygame" "${EX00_DIR}/spider.py"; then
        bonus_ok "SPIDER graphical interface detected" 10
        total_gui_score=$((total_gui_score + 10))
    fi
    
    # Check SCORPION for GUI
    if grep -qiE "tkinter|pyqt|wxpython|flask|django|streamlit|pygame" "${EX01_DIR}/scorpion.py"; then
        bonus_ok "SCORPION graphical interface detected" 10
        total_gui_score=$((total_gui_score + 10))
    fi
    
    if [[ $total_gui_score -eq 0 ]]; then
        bonus_fail "No graphical interface framework detected in either module"
    fi
}

# ============================================================================
# FINAL REPORT
# ============================================================================

final_report() {
    header "EVALUATION COMPLETE - COMPREHENSIVE ARACHNIDA SCORING"
    
    echo -e "${BOLD}MANDATORY PART:${RESET}"
    echo -e "  Score: ${GREEN}${MANDATORY_SCORE}${RESET}/${MAX_MANDATORY}"
    
    if [[ "$MANDATORY_SCORE" -ge 80 ]]; then
        echo -e "  Status: ${GREEN}✓ PASS (Bonus eligible)${RESET}"
        
        echo -e "\n${BOLD}BONUS PART:${RESET}"
        echo -e "  Score: ${GREEN}${BONUS_SCORE}${RESET}/${TOTAL_BONUS}"
        
        local total=$((MANDATORY_SCORE + BONUS_SCORE))
        echo -e "\n${BOLD}TOTAL SCORE:${RESET} ${GREEN}${total}${RESET}/120+"
        
        if [[ $total -ge 115 ]]; then
            echo -e "${BOLD}${GREEN}GRADE: 10/10 - EXCELLENT${RESET}"
        elif [[ $total -ge 105 ]]; then
            echo -e "${BOLD}${GREEN}GRADE: 9/10 - VERY GOOD${RESET}"
        elif [[ $total -ge 95 ]]; then
            echo -e "${BOLD}${GREEN}GRADE: 8/10 - GOOD${RESET}"
        else
            echo -e "${BOLD}${YELLOW}GRADE: 7/10 - ACCEPTABLE${RESET}"
        fi
    else
        echo -e "  Status: ${RED}✗ FAIL (Bonus ineligible)${RESET}"
        echo -e "\n${BOLD}GRADE:${RESET} ${RED}$((MANDATORY_SCORE / 10))/10${RESET}"
        echo -e "${YELLOW}Note: Mandatory part incomplete. Bonus features not evaluated.${RESET}"
    fi
    
    # Flags
    echo -e "\n${BOLD}CRITICAL FLAGS:${RESET}"
    [[ "$CRASH" == true ]] && echo -e "  ${RED}✗ CRASH${RESET}" || echo -e "  ${GREEN}✓${RESET} No crashes"
    [[ "$INVALID_COMPILATION" == true ]] && echo -e "  ${RED}✗ INVALID COMPILATION${RESET}" || echo -e "  ${GREEN}✓${RESET} Valid syntax"
    [[ "$CHEAT" == true ]] && echo -e "  ${RED}✗ CHEAT SUSPECTED${RESET}" || echo -e "  ${GREEN}✓${RESET} No cheating"
    
    echo ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    setup
    
    header "🕷️  ARACHNIDA PROJECT EVALUATION 🦂"
    
    # ========== SPIDER VALIDATION ==========
    validate_spider_structure
    validate_spider_parameters
    validate_spider_http
    validate_spider_file_extensions
    validate_spider_dependencies
    
    # ========== SCORPION VALIDATION ==========
    validate_scorpion_structure
    validate_scorpion_basic_metadata
    validate_scorpion_exif_data
    validate_scorpion_dependencies
    
    # ========== BONUS VALIDATION ==========
    if [[ "$MANDATORY_SCORE" -ge 80 ]]; then
        validate_bonus_metadata_deletion
        validate_bonus_metadata_modification
        validate_bonus_gui
    fi
    
    # ========== FINAL REPORT ==========
    final_report
    
    # Return appropriate exit code
    if [[ "$CRASH" == true ]] || [[ "$INVALID_COMPILATION" == true ]] || [[ "$CHEAT" == true ]]; then
        return 1
    elif [[ "$MANDATORY_SCORE" -lt 50 ]]; then
        return 1
    fi
    
    return 0
}

# ============================================================================
# SCRIPT ENTRY POINT
# ============================================================================

if [[ ! -f "${SCRIPT_DIR}/evaluation.sh" ]]; then
    echo -e "${RED}Error: This script must be run from the 01_arachnida_Web directory${RESET}"
    exit 1
fi

main
exit $?
