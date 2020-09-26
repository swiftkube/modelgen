# Swiftkube:ModelGen

Kuberentes API resources model generator for [Swiftkube:Model](https://github.com/swiftkube/model)

## Overview

This tool converts Kuberentes JSON schema definitions into Swift structs using Stencil templates. The JSON definitions are mapped from their openAPI counterparts via [openapi2jsonschema](https://github.com/instrumenta/openapi2jsonschema).

## Non-goals:

- Performance
- Reusability
- Clean code

## Build

Clone this repository and run:

```shell
swift build
```

## Usage

Run the script:

```shell
SwiftkubeModelGen --api-version v1.418.4 --templates templates/model --output <path for generated model>
```
