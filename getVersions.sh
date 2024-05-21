
echo ""
echo "Getting commit hash of tomatentim/nginx-custom"
repo_commit_hash=$(git log -1 --pretty=format:"%H")
repo_commit_hash_short=$(echo "$repo_commit_hash" | cut -c -7)

echo ""
echo "Pulling nginx:latest"
docker pull nginx:latest

# Get version of NGINX
nginx_config_string=$(docker image inspect nginx:latest --format '{{ .Config.Env }}')
nginx_version=$(echo "$nginx_config_string" | grep -oP 'NGINX_VERSION=\K[^\s]*')


echo ""
echo "Getting commit hash of arut/nginx-rtmp-module"
rtmp_module_response=$(git ls-remote https://github.com/arut/nginx-rtmp-module.git refs/heads/master)
rtmp_module_commit_hash=$(echo "$rtmp_module_response" | cut -d $'\t' -f 1)
rtmp_module_commit_hash_short=$(echo "$rtmp_module_commit_hash" | cut -c -7)


dockertag="$repo_commit_hash_short--nginx-$nginx_version--rtmp-$rtmp_module_commit_hash_short"

echo ""
echo "REPO Hash:         $repo_commit_hash_short ($repo_commit_hash)"
echo "NGINX Version:     $nginx_version"
echo "RTMP Module Hash:  $rtmp_module_commit_hash_short ($rtmp_module_commit_hash)"

echo "DOCKER_TAG:        $dockertag"

echo "{DOCKER_TAG}={$dockertag}" >> "$GITHUB_OUTPUT"
echo "{NGINX_VERSION}={$nginx_version}" >> "$GITHUB_OUTPUT"
echo "{RTMP_MODULE_VERSION}={$rtmp_module_commit_hash}" >> "$GITHUB_OUTPUT"

# echo ""
# echo "Building Docker image"

# docker build . \
#   --no-cache \
#   -t nginx-custom \
#   --build-arg="NGINX_VERSION=$nginx_version" \
#   --build-arg="RTMP_MODULE_VERSION=c56fd73def3eb407155ecebc28af84ea83dc99e5"


# docker tag nginx-custom nginx-custom:latest
# docker tag nginx-custom nginx-custom:$dockertag

# docker push nginx-custom:latest
# docker push nginx-custom:$dockertag