#!/bin/bash

# Script to check npm install output for vulnerabilities
# Usage: npm install 2>&1 | bash check-vulnerabilities.sh
# Or: bash check-vulnerabilities.sh <npm_install_output_file>

set -e

# Color codes for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to extract vulnerability count from npm install output
parse_vulnerabilities() {
    local input="$1"
    local critical_count=0
    local high_count=0
    local moderate_count=0
    local low_count=0
    
    # Look for vulnerability pattern: "X vulnerabilities (Y low, Z moderate, A high, B critical)"
    # The pattern can vary in order and some severity levels might be missing
    local vuln_line=$(echo "$input" | grep -i "vulnerabilit" | head -1 || true)
    
    if [[ -n "$vuln_line" ]]; then
        echo "Found vulnerability line: $vuln_line"
        
        # Extract critical vulnerabilities
        if echo "$vuln_line" | grep -q "critical"; then
            critical_count=$(echo "$vuln_line" | sed -n 's/.*\([0-9]\+\) critical.*/\1/p')
        fi
        
        # Extract high vulnerabilities  
        if echo "$vuln_line" | grep -q "high"; then
            high_count=$(echo "$vuln_line" | sed -n 's/.*\([0-9]\+\) high.*/\1/p')
        fi
        
        # Extract moderate vulnerabilities
        if echo "$vuln_line" | grep -q "moderate"; then
            moderate_count=$(echo "$vuln_line" | sed -n 's/.*\([0-9]\+\) moderate.*/\1/p')
        fi
        
        # Extract low vulnerabilities
        if echo "$vuln_line" | grep -q "low"; then
            low_count=$(echo "$vuln_line" | sed -n 's/.*\([0-9]\+\) low.*/\1/p')
        fi
        
        echo "Parsed vulnerabilities - Critical: ${critical_count:-0}, High: ${high_count:-0}, Moderate: ${moderate_count:-0}, Low: ${low_count:-0}"
        
        # Return critical count as the main result
        echo "${critical_count:-0}"
    else
        echo "No vulnerabilities found in npm install output"
        echo "0"
    fi
}

# Main execution
if [[ $# -eq 1 && -f "$1" ]]; then
    # Read from file
    input=$(cat "$1")
elif [[ ! -t 0 ]]; then
    # Read from stdin (piped input)
    input=$(cat)
else
    echo -e "${RED}Error: No input provided${NC}"
    echo "Usage: npm install 2>&1 | bash check-vulnerabilities.sh"
    echo "   Or: bash check-vulnerabilities.sh <npm_install_output_file>"
    exit 1
fi

# Parse vulnerabilities
result=$(parse_vulnerabilities "$input")
critical_count=$(echo "$result" | tail -1)

echo ""
echo -e "${YELLOW}=== Vulnerability Check Results ===${NC}"

if [[ "$critical_count" =~ ^[0-9]+$ ]] && [[ "$critical_count" -gt 0 ]]; then
    echo -e "${RED}❌ CRITICAL: Found $critical_count critical vulnerabilities!${NC}"
    echo -e "${RED}   This requires immediate attention.${NC}"
    echo ""
    echo -e "${YELLOW}Running npm audit for detailed information...${NC}"
    npm audit || true
    echo ""
    echo -e "${RED}Build failed due to critical vulnerabilities. Please fix them before proceeding.${NC}"
    exit 1
else
    echo -e "${GREEN}✅ PASSED: No critical vulnerabilities found${NC}"
    exit 0
fi