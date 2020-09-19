# Swiftkube:ModelGen

Kuberentes API resources model generator for [Swiftkube:Model](https://github.com/swiftkube/model)

## Overview

This tool converts Kuberentes JSON schema definitions hosted at [https://kubernetesjsonschema.dev](https://kubernetesjsonschema.dev) into Swift structs using Stencil templates.

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
