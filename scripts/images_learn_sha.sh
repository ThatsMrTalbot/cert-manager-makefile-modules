#!/bin/bash

images_amd64=${IMAGES_AMD64}
images_arm64=${IMAGES_ARM64}
CRANE=${CRANE}

if [ -z "$images_amd64" ]; then
    echo "IMAGES_AMD64 is not set"
    exit 1
fi

if [ -z "$images_arm64" ]; then
    echo "IMAGES_ARM64 is not set"
    exit 1
fi

if [ -z "$CRANE" ]; then
    echo "CRANE is not set"
    exit 1
fi

learn_data=()

for image in $images_amd64; do
    image_no_digest=$(echo -n "$image" | cut -d@ -f1)
    find=$(echo -n "$image" | cut -d@ -f2)
    replace=$($CRANE digest --platform "linux/amd64" "$image_no_digest")

    if [ "$find" == "$replace" ]; then
        continue
    fi

    learn_data+=("s|$find|$replace|g\n")
done

for image in $images_arm64; do
    image_no_digest=$(echo -n "$image" | cut -d@ -f1)
    find=$(echo -n "$image" | cut -d@ -f2)
    replace=$($CRANE digest --platform "linux/arm64" "$image_no_digest")

    if [ "$find" == "$replace" ]; then
        continue
    fi

    learn_data+=("s|$find|$replace|g\n")
done

module_files=$(find ./modules/ -maxdepth 2 -name "00_mod.mk" -type f)

# Don't replace the digests of the kind images
module_files=$(echo "$module_files" | grep -v "docker.io/kindest/node")

for replace in "${learn_data[@]}"; do
    for file in $module_files; do
        sed -i "$replace" "$file";
    done
done
