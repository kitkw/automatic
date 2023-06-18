#!/bin/bash

# GitHub API 工具函数

# 下载文件函数
download_file() {
    local file_path=$1
    local output_path=$2
    local token=$3
    local owner=$4
    local repo=$5
    
    echo "Downloading $file_path to $output_path"
    curl -H "Authorization: token $token" \
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
    local existing_sha=$(curl -s -H "Authorization: token $token" \
                                     -H "Accept: application/vnd.github.v3+json" \
                                     "https://api.github.com/repos/$owner/$repo/contents/$repo_path" | \
                                jq -r '.sha // empty')
    
    local message=""
    local data=""
    
    if [ ! -z "$existing_sha" ]; then
        message="Update $filename at $current_time"
        data="{\"message\": \"$message\", \"content\": \"$content\", \"sha\": \"$existing_sha\"}"
    else
        message="Add $filename at $current_time"
        data="{\"message\": \"$message\", \"content\": \"$content\"}"
    fi
    
    echo "Uploading $filename"
    curl -X PUT \
         -H "Authorization: token $token" \
         -H "Accept: application/vnd.github.v3+json" \
         -H "Content-Type: application/json" \
         -d "$data" \
         "https://api.github.com/repos/$owner/$repo/contents/$repo_path"
}

# 获取文件列表函数
get_file_list() {
    local path=$1
    local token=$2
    local owner=$3
    local repo=$4
    local pattern=$5
    
    curl -H "Authorization: token $token" \
         -H "Accept: application/vnd.github.v3+json" \
         "https://api.github.com/repos/$owner/$repo/contents/$path" | \
    jq -r ".[] | select(.name | test(\"$pattern\"; \"i\")) | .path"
} 