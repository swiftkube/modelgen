#!/bin/sh

../.build/debug/swiftkube-modelgen -t ../templates/model -o ../generated --api-version v1.18.13

swiftformat --config ../.swiftformat ../generated
