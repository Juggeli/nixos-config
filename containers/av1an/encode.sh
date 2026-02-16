#!/bin/bash
set -euo pipefail

SONARR_URL="${SONARR_URL:-http://10.11.11.2:8999}"
SONARR_API_KEY="${SONARR_API_KEY:-}"
INPUT_DIR="/input"
OUTPUT_DIR="/output"
APP_DIR="/app"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

get_codec() {
    local file="$1"
    ffprobe -v quiet -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$file" 2>/dev/null || echo "unknown"
}

get_size_human() {
    local bytes="$1"
    if [ "$bytes" -ge 1073741824 ]; then
        echo "$(echo "scale=2; $bytes / 1073741824" | bc)G"
    elif [ "$bytes" -ge 1048576 ]; then
        echo "$(echo "scale=1; $bytes / 1048576" | bc)M"
    else
        echo "${bytes}B"
    fi
}

list_series() {
    echo ""
    echo -e "${BOLD}Available series:${NC}"
    echo "─────────────────────────────────────────────────────────────────"
    printf "%-4s %-45s %6s %8s %s\n" "#" "Series" "Files" "Size" "Codec"
    echo "─────────────────────────────────────────────────────────────────"

    local i=1
    SERIES_DIRS=()

    for dir in "$INPUT_DIR"/*/; do
        [ -d "$dir" ] || continue
        local name
        name=$(basename "$dir")
        SERIES_DIRS+=("$name")

        local count=0
        local total_size=0
        local first_codec="n/a"

        while IFS= read -r -d '' file; do
            count=$((count + 1))
            local fsize
            fsize=$(stat -c%s "$file" 2>/dev/null || echo 0)
            total_size=$((total_size + fsize))
            if [ "$count" -eq 1 ]; then
                first_codec=$(get_codec "$file")
            fi
        done < <(find "$dir" -maxdepth 1 -type f \( -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" \) -print0 | sort -z)

        local size_human
        size_human=$(get_size_human "$total_size")

        local status=""
        if [ "$first_codec" = "av1" ]; then
            status=" ${GREEN}[DONE]${NC}"
        fi

        printf "%-4s %-45s %6s %8s %s%b\n" "$i" "$name" "$count" "$size_human" "$first_codec" "$status"
        i=$((i + 1))
    done

    echo "─────────────────────────────────────────────────────────────────"
    echo ""
}

unmonitor_sonarr_series() {
    local series_name="$1"

    if [ -z "$SONARR_API_KEY" ]; then
        echo -e "${YELLOW}No SONARR_API_KEY set, skipping unmonitor${NC}"
        return
    fi

    echo -e "${CYAN}Looking up series in Sonarr...${NC}"

    local series_json
    series_json=$(curl -s "${SONARR_URL}/api/v3/series" \
        -H "X-Api-Key: ${SONARR_API_KEY}")

    local series_id
    series_id=$(echo "$series_json" | jq -r \
        --arg name "$series_name" \
        '.[] | select(.path | split("/") | last | ascii_downcase == ($name | ascii_downcase)) | .id' | head -1)

    if [ -z "$series_id" ] || [ "$series_id" = "null" ]; then
        series_id=$(echo "$series_json" | jq -r \
            --arg name "$series_name" \
            '.[] | select(.title | ascii_downcase == ($name | ascii_downcase)) | .id' | head -1)
    fi

    if [ -z "$series_id" ] || [ "$series_id" = "null" ]; then
        echo -e "${YELLOW}Could not find series '${series_name}' in Sonarr${NC}"
        return
    fi

    echo -e "${CYAN}Found series ID: ${series_id}. Unmonitoring all seasons...${NC}"

    local updated_series
    updated_series=$(echo "$series_json" | jq \
        --argjson id "$series_id" \
        '[.[] | select(.id == $id)][0] | .seasons = [.seasons[] | .monitored = false]')

    curl -s -X PUT "${SONARR_URL}/api/v3/series/${series_id}" \
        -H "X-Api-Key: ${SONARR_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$updated_series" > /dev/null

    echo -e "${GREEN}All seasons unmonitored for '${series_name}'${NC}"
}

encode_series() {
    local series_name="$1"
    local series_path="${INPUT_DIR}/${series_name}"
    local output_path="${OUTPUT_DIR}/${series_name}"

    mkdir -p "$output_path"

    local total_original=0
    local total_encoded=0
    local encoded_count=0
    local skipped_count=0

    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(find "$series_path" -maxdepth 1 -type f \( -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" \) -print0 | sort -z)

    local total=${#files[@]}
    echo -e "${BOLD}Encoding ${total} episodes from '${series_name}'${NC}"
    echo ""

    for file in "${files[@]}"; do
        local filename
        filename=$(basename "$file")
        local stem="${filename%.*}"
        local codec
        codec=$(get_codec "$file")

        echo -e "${CYAN}[${encoded_count}/${total}] ${filename}${NC}"

        if [ "$codec" = "av1" ]; then
            echo -e "${YELLOW}  Already AV1, skipping${NC}"
            skipped_count=$((skipped_count + 1))
            continue
        fi

        rm -rf "${APP_DIR}/Input/"* "${APP_DIR}/Output/"*
        mkdir -p "${APP_DIR}/Input" "${APP_DIR}/Output"

        ln -sf "$file" "${APP_DIR}/Input/${filename}"

        local original_size
        original_size=$(stat -c%s "$file")
        total_original=$((total_original + original_size))

        echo -e "  Encoding (${codec} → AV1)..."

        cd "$APP_DIR"
        bash ./run_linux_anime_crf30.sh

        local output_file
        output_file=$(find "${APP_DIR}/Output/" -type f \( -name "*.mkv" -o -name "*.mp4" \) | head -1)

        if [ -z "$output_file" ]; then
            echo -e "${RED}  Encoding failed, no output file found${NC}"
            continue
        fi

        local encoded_size
        encoded_size=$(stat -c%s "$output_file")
        total_encoded=$((total_encoded + encoded_size))

        mv "$output_file" "${output_path}/${filename}"
        encoded_count=$((encoded_count + 1))

        local savings
        savings=$(echo "scale=1; (1 - $encoded_size / $original_size) * 100" | bc)
        echo -e "${GREEN}  $(get_size_human "$original_size") → $(get_size_human "$encoded_size") (${savings}% saved)${NC}"
    done

    rm -rf "${APP_DIR}/Input/"* "${APP_DIR}/Output/"*

    echo ""
    echo -e "${BOLD}═══ Summary for '${series_name}' ═══${NC}"
    echo -e "  Encoded: ${encoded_count}/${total} (skipped: ${skipped_count})"

    if [ "$total_original" -gt 0 ]; then
        local total_savings
        total_savings=$(echo "scale=1; (1 - $total_encoded / $total_original) * 100" | bc)
        echo -e "  Original: $(get_size_human "$total_original")"
        echo -e "  Encoded:  $(get_size_human "$total_encoded")"
        echo -e "  ${GREEN}Saved: $(get_size_human $((total_original - total_encoded))) (${total_savings}%)${NC}"
    fi
    echo ""

    if [ "$encoded_count" -gt 0 ]; then
        unmonitor_sonarr_series "$series_name"
    fi
}

main() {
    if [ -L "/app/tools-config/workercount-ssimu2.txt" ] || [ -f "/app/tools-config/workercount-ssimu2.txt" ]; then
        mkdir -p "${APP_DIR}/tools"
        cp "/app/tools-config/workercount-ssimu2.txt" "${APP_DIR}/tools/workercount-ssimu2.txt" 2>/dev/null || true
    fi

    while true; do
        list_series

        if [ ${#SERIES_DIRS[@]} -eq 0 ]; then
            echo -e "${YELLOW}No series found in ${INPUT_DIR}${NC}"
            exit 0
        fi

        echo -n "Pick a series number (or 'q' to quit): "
        read -r choice

        if [ "$choice" = "q" ] || [ "$choice" = "Q" ]; then
            echo "Bye!"
            exit 0
        fi

        if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#SERIES_DIRS[@]} ]; then
            echo -e "${RED}Invalid choice${NC}"
            continue
        fi

        local idx=$((choice - 1))
        local selected="${SERIES_DIRS[$idx]}"

        echo ""
        echo -e "${BOLD}Selected: ${selected}${NC}"
        echo ""

        encode_series "$selected"

        if [ -d "${APP_DIR}/tools" ] && [ -f "${APP_DIR}/tools/workercount-ssimu2.txt" ]; then
            cp "${APP_DIR}/tools/workercount-ssimu2.txt" "/app/tools-config/workercount-ssimu2.txt" 2>/dev/null || true
        fi

        echo ""
        echo -e "${GREEN}Done! Returning to series list...${NC}"
        echo ""
    done
}

main
