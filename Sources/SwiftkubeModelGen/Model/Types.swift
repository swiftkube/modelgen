//
// Copyright 2020 Swiftkube Project
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

let TypePrefixes = Set([
	"apiserver",
	"io.k8s.api.",
	"io.k8s.api.apiserver",
	"io.k8s.apiextensions-apiserver.pkg.apis.",
	"io.k8s.apimachinery.pkg.apis.",
	"io.k8s.kube-aggregator.pkg.apis.",
])

let ManualTypes = Set([
	"io.k8s.apimachinery.pkg.api.resource.Quantity",
	"io.k8s.apimachinery.pkg.util.intstr.IntOrString",
])

let JSONTypes = [
	"apiextensions.v1.JSONSchemaProps": PropertyType.map(valueType: .any),
	"apiextensions.v1beta1.JSONSchemaProps": PropertyType.map(valueType: .any),
	"meta.v1.FieldsV1": PropertyType.map(valueType: .any),
	"meta.v1.Patch": PropertyType.map(valueType: .any),
	"io.k8s.apimachinery.pkg.runtime.RawExtension": PropertyType.map(valueType: .any),
]

let ConvertedTypes = [
	"meta.v1.MicroTime": PropertyType.date,
	"meta.v1.Time": PropertyType.date,
]

let IgnoredSchemaTypes = Set([
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

let PluralNames = [
	"APIService":                     "apiservices",
	"AuditSink":                      "auditsinks",
	"Binding":                        "bindings",
	"CertificateSigningRequest":      "certificatesigningrequests",
	"ClusterRole":                    "clusterroles",
	"ClusterRoleBinding":             "clusterrolebindings",
	"ComponentStatus":                "componentstatuses",
	"ConfigMap":                      "configmaps",
	"ControllerRevision":             "controllerrevisions",
	"CronJob":                        "cronjobs",
	"CSIDriver":                      "csidrivers",
	"CSINode":                        "csinodes",
	"CSIStorageCapacity":             "csistoragecapacities",
	"CustomResourceDefinition":       "customresourcedefinitions",
	"DaemonSet":                      "daemonsets",
	"Deployment":                     "deployments",
	"Endpoints":                      "endpoints",
	"EndpointSlice":                  "endpointslices",
	"Event":                          "events",
	"FlowSchema":                     "flowschemas",
	"HorizontalPodAutoscaler":        "horizontalpodautoscalers",
	"Ingress":                        "ingresses",
	"IngressClass":                   "ingressclasses",
	"Job":                            "jobs",
	"Lease":                          "leases",
	"LimitRange":                     "limitranges",
	"LocalSubjectAccessReview":       "localsubjectaccessreviews",
	"MutatingWebhookConfiguration":   "mutatingwebhookconfigurations",
	"Namespace":                      "namespaces",
	"NetworkPolicy":                  "networkpolicies",
	"Node":                           "nodes",
	"NodeMetrics":                    "nodes",
	"PersistentVolume":               "persistentvolumes",
	"PersistentVolumeClaim":          "persistentvolumeclaims",
	"Pod":                            "pods",
	"PodDisruptionBudget":            "poddisruptionbudgets",
	"PodMetrics":                     "pods",
	"PodPreset":                      "podpresets",
	"PodSecurityPolicy":              "podsecuritypolicies",
	"PodTemplate":                    "podtemplates",
	"PriorityClass":                  "priorityclasses",
	"PriorityLevelConfiguration":     "prioritylevelconfigurations",
	"ReplicaSet":                     "replicasets",
	"ReplicationController":          "replicationcontrollers",
	"ResourceQuota":                  "resourcequotas",
	"Role":                           "roles",
	"RoleBinding":                    "rolebindings",
	"RuntimeClass":                   "runtimeclasses",
	"Secret":                         "secrets",
	"SelfSubjectAccessReview":        "selfsubjectaccessreviews",
	"SelfSubjectRulesReview":         "selfsubjectrulesreviews",
	"Service":                        "services",
	"ServiceAccount":                 "serviceaccounts",
	"StatefulSet":                    "statefulsets",
	"StorageClass":                   "storageclasses",
	"StorageVersion":                 "storageversions",
	"SubjectAccessReview":            "subjectaccessreviews",
	"TokenRequest":                   "tokenrequests",
	"TokenReview":                    "tokenreviews",
	"ValidatingWebhookConfiguration": "validatingwebhookconfigurations",
	"VolumeAttachment":               "volumeattachments",
]

let ShortNames = [
	"CertificateSigningRequest":      "csr",
	"ComponentStatus":                "cs",
	"ConfigMap":                      "cm",
	"CronJob":                        "cj",
	"CustomResourceDefinition":       "crd",
	"DaemonSet":                      "ds",
	"Deployment":                     "deploy",
	"Endpoints":                      "ep",
	"Event":                          "ev",
	"HorizontalPodAutoscaler":        "hpa",
	"Ingress":                        "ing",
	"LimitRange":                     "limits",
	"Namespace":                      "ns",
	"NetworkPolicy":                  "netpol",
	"Node":                           "no",
	"PersistentVolume":               "pv",
	"PersistentVolumeClaim":          "pvc",
	"Pod":                            "po",
	"PodDisruptionBudget":            "pdb",
	"PodSecurityPolicy":              "psp",
	"PriorityClass":                  "pc",
	"ReplicaSet":                     "rs",
	"ReplicationController":          "rc",
	"ResourceQuota":                  "quota",
	"Service":                        "svc",
	"ServiceAccount":                 "sa",
	"StatefulSet":                    "sts",
	"StorageClass":                   "sc",
]

let APIGroups = [
	"admissionregistration.k8s.io":   "AdmissionRegistration",
	"apiextensions.k8s.io":           "APIExtensions",
	"apiregistration.k8s.io":         "APIRegistration",
	"apps":                           "Apps",
	"authentication.k8s.io":          "Authentication",
	"authorization.k8s.io":           "Authorization",
	"autoscaling":                    "AutoScaling",
	"batch":                          "Batch",
	"certificates.k8s.io":            "Certificates",
	"coordination.k8s.io":            "Coordination",
	"core":                           "Core",
	"discovery.k8s.io":               "Discovery",
	"events.k8s.io":                  "Events",
	"extensions":                     "Extensions",
	"flowcontrol.apiserver.k8s.io":   "FlowControl",
	"internal.apiserver.k8s.io":      "Internal",
	"networking.k8s.io":              "Networking",
	"node.k8s.io":                    "Node",
	"policy":                         "Policy",
	"rbac.authorization.k8s.io":      "RBAC",
	"scheduling.k8s.io":              "Scheduling",
	"storage.k8s.io":                 "Storage",
]

let Keywords = Set(["continue", "default", "internal", "operator", "protocol"])
