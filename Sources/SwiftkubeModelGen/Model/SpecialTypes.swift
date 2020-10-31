//
// Copyright 2020 Iskandar Abudiab (iabudiab.dev)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

let ManualTypes = Set([
	"io.k8s.apimachinery.pkg.api.resource.Quantity",
	"io.k8s.apimachinery.pkg.util.intstr.IntOrString",
])

let JSONTypes = [
	"io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.JSONSchemaProps": PropertyType.map(valueType: .any),
	"io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1beta1.JSONSchemaProps": PropertyType.map(valueType: .any),
	"io.k8s.apimachinery.pkg.apis.meta.v1.FieldsV1": PropertyType.map(valueType: .any),
	"io.k8s.apimachinery.pkg.apis.meta.v1.Patch": PropertyType.map(valueType: .any),
	"io.k8s.apimachinery.pkg.runtime.RawExtension": PropertyType.map(valueType: .any),
]

let OtherTypes = [
	"io.k8s.apimachinery.pkg.apis.meta.v1.MicroTime": PropertyType.string,
	"io.k8s.apimachinery.pkg.apis.meta.v1.Time": PropertyType.string,
]

let IgnoredTypes = Set([
	"io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.JSON",
	"io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1beta1.JSON",
	"io.k8s.apimachinery.pkg.api.resource.Quantity",
	"io.k8s.apimachinery.pkg.apis.meta.v1.FieldsV1",
	"io.k8s.apimachinery.pkg.apis.meta.v1.MicroTime",
	"io.k8s.apimachinery.pkg.apis.meta.v1.Patch",
	"io.k8s.apimachinery.pkg.apis.meta.v1.Time",
	"io.k8s.apimachinery.pkg.runtime.RawExtension",
	"io.k8s.apimachinery.pkg.version.Info",
	"io.k8s.apimachinery.pkg.util.intstr.IntOrString",
])

let SpecialAPITypes = Set([
	"io.k8s.apimachinery.pkg.apis.meta.v1.APIVersions",
	"io.k8s.apimachinery.pkg.apis.meta.v1.APIResourceList",
	"io.k8s.apimachinery.pkg.apis.meta.v1.APIResource",
	"io.k8s.apimachinery.pkg.apis.meta.v1.APIGroupList",
	"io.k8s.apimachinery.pkg.apis.meta.v1.APIGroup"
])

let NonAPITypes = Set([
	"io.k8s.apimachinery.pkg.apis.meta.v1.Status",
	"io.k8s.apimachinery.pkg.apis.meta.v1.DeleteOptions"
])
