#!/bin/bash

# Usage: ./convert_url_to_purl.sh input.txt

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="purl.txt"

if [ ! -f "$INPUT_FILE" ]; then
    echo "File not found: $INPUT_FILE"
    exit 1
fi

> "$OUTPUT_FILE"

while IFS= read -r line || [ -n "$line" ]; do
    # Ignore blank lines and comments
    if [[ -z "$line" || "$line" =~ ^# ]]; then
        continue
    fi

    # GitHub commit URL
    if [[ "$line" =~ github.com/([^/]+)/([^/]+)/commit/([a-f0-9]{40}) ]]; then
        owner="${BASH_REMATCH[1]}"
        repo="${BASH_REMATCH[2]}"
        commit="${BASH_REMATCH[3]}"
        echo "pkg:github/$owner/$repo@$commit" >> "$OUTPUT_FILE"
        continue
    fi

    # npm package URL (latest or with version)
    if [[ "$line" =~ npmjs.com/package/([^/@]+)@?([^/?#]*) ]]; then
        name="${BASH_REMATCH[1]}"
        version="${BASH_REMATCH[2]}"
        if [[ -n "$version" ]]; then
            echo "pkg:npm/$name@$version" >> "$OUTPUT_FILE"
        else
            echo "pkg:npm/$name" >> "$OUTPUT_FILE"
        fi
        continue
    fi

    # Maven Central artifact URL (search.maven.org or mvnrepository.com)
    if [[ "$line" =~ search.maven.org/artifact/([^/]+)/([^/]+)/([^/?#]+) ]]; then
        group="${BASH_REMATCH[1]}"
        artifact="${BASH_REMATCH[2]}"
        version="${BASH_REMATCH[3]}"
        echo "pkg:maven/$group/$artifact@$version" >> "$OUTPUT_FILE"
        continue
    fi
    if [[ "$line" =~ mvnrepository.com/artifact/([^/]+)/([^/]+)/([^/?#]+) ]]; then
        group="${BASH_REMATCH[1]}"
        artifact="${BASH_REMATCH[2]}"
        version="${BASH_REMATCH[3]}"
        echo "pkg:maven/$group/$artifact@$version" >> "$OUTPUT_FILE"
        continue
    fi

    # NuGet package URL
    if [[ "$line" =~ nuget.org/packages/([^/]+)(/([0-9A-Za-z\.\-]+))? ]]; then
        name="${BASH_REMATCH[1]}"
        version="${BASH_REMATCH[3]}"
        if [[ -n "$version" ]]; then
            echo "pkg:nuget/$name@$version" >> "$OUTPUT_FILE"
        else
            echo "pkg:nuget/$name" >> "$OUTPUT_FILE"
        fi
        continue
    fi

    # PyPI package URL
    if [[ "$line" =~ pypi.org/project/([^/]+)/([^/]+) ]]; then
        name="${BASH_REMATCH[1]}"
        version="${BASH_REMATCH[2]}"
        echo "pkg:pypi/$name@$version" >> "$OUTPUT_FILE"
        continue
    elif [[ "$line" =~ pypi.org/project/([^/]+) ]]; then
        name="${BASH_REMATCH[1]}"
        echo "pkg:pypi/$name" >> "$OUTPUT_FILE"
        continue
    fi

    # RubyGems package URL
    if [[ "$line" =~ rubygems.org/gems/([^/]+)/versions/([^/]+) ]]; then
        name="${BASH_REMATCH[1]}"
        version="${BASH_REMATCH[2]}"
        echo "pkg:gem/$name@$version" >> "$OUTPUT_FILE"
        continue
    elif [[ "$line" =~ rubygems.org/gems/([^/]+) ]]; then
        name="${BASH_REMATCH[1]}"
        echo "pkg:gem/$name" >> "$OUTPUT_FILE"
        continue
    fi

    # Go module URL from pkg.go.dev (Preferred PURL)
    if [[ "$line" =~ pkg.go.dev/([^@]+)@([^/?#]+) ]]; then
        module="${BASH_REMATCH[1]}"
        version="${BASH_REMATCH[2]}"
        echo "pkg:golang/$module@$version" >> "$OUTPUT_FILE"
        continue
    fi

    # Go direct path with version (e.g. github.com/foo/bar@v1.2.3)
    if [[ "$line" =~ ^https?://([^@]+)@([^/?#]+) ]]; then
        module="${BASH_REMATCH[1]}"
        version="${BASH_REMATCH[2]}"
        echo "pkg:golang/$module@$version" >> "$OUTPUT_FILE"
        continue
    fi

    # Debian - Salsa or tracker (assume latest)
    if [[ "$line" =~ salsa.debian.org/([^/]+)/([^/]+) ]]; then
        namespace="${BASH_REMATCH[1]}"
        name="${BASH_REMATCH[2]}"
        echo "pkg:deb/debian/$name" >> "$OUTPUT_FILE"
        continue
    elif [[ "$line" =~ tracker.debian.org/pkg/([^/]+) ]]; then
        name="${BASH_REMATCH[1]}"
        echo "pkg:deb/debian/$name" >> "$OUTPUT_FILE"
        continue
    fi
    # Debian pool URLs (ftp.debian.org/debian/pool/main/m/mailcap/)
    if [[ "$line" =~ debian.org/debian/pool/[^/]+/[^/]+/([^/]+)/? ]]; then
        name="${BASH_REMATCH[1]}"
        echo "pkg:deb/debian/$name" >> "$OUTPUT_FILE"
        continue
    fi

    # If not matched, print a warning
    echo "Unrecognized or unsupported URL: $line" >&2
done < "$INPUT_FILE"
