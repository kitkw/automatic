#!/bin/bash

# GitHub API 工具函数

# 下载文件函数
download_file() {
    local file_path=$1
    local output_path=$2
    local token=$3
    local owner=$4
    local repo=$5
    
    curl -sS -f -H "Authorization: token $token" \
         -H "Accept: application/vnd.github.v3.raw" \
         -L "https://api.github.com/repos/$owner/$repo/contents/$file_path" \
         -o "$output_path"
}

# 上传文件函数
upload_file() {
    local file_path=$1
    local repo_path=$2
    local token=$3
    local owner=$4
    local repo=$5
    
    local filename=$(basename "$file_path")
    local content=$(base64 -w 0 < "$file_path")
    local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # 检查文件是否已存在
    local existing_sha=$(curl -sS -H "Authorization: token $token" \
                                     -H "Accept: application/vnd.github.v3+json" \
                                     "https://api.github.com/repos/$owner/$repo/contents/$repo_path" | \
                                jq -r '.sha // empty')
    
    local message=""
    local temp_file=$(mktemp)
    
    if [ ! -z "$existing_sha" ]; then
        message="Update file at $current_time"
        echo "{\"message\": \"$message\", \"content\": \"$content\", \"sha\": \"$existing_sha\"}" > "$temp_file"
    else
        message="Add file at $current_time"
        echo "{\"message\": \"$message\", \"content\": \"$content\"}" > "$temp_file"
    fi
    
    curl -sS -f -X PUT \
         -H "Authorization: token $token" \
         -H "Accept: application/vnd.github.v3+json" \
         -H "Content-Type: application/json" \
         -d "@$temp_file" \
         "https://api.github.com/repos/$owner/$repo/contents/$repo_path" \
         -o /dev/null
    
    # 清理临时文件
    rm -f "$temp_file"
}

# 获取文件列表函数
get_file_list() {
    local path=$1
    local token=$2
    local owner=$3
    local repo=$4
    local pattern=$5
    
    curl -sS -H "Authorization: token $token" \
         -H "Accept: application/vnd.github.v3+json" \
         "https://api.github.com/repos/$owner/$repo/contents/$path" | \
    jq -r ".[] | select(.name | test(\"$pattern\"; \"i\")) | .path"
} 