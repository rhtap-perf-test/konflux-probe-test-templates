Konflux probe test templates
============================

Just templates for pipeline runs for our probe load tests.

Kanary-labelled variants
------------------------

Directories ending in `-kanary-label` copy the corresponding probe templates,
adding `appstudio.openshift.io/kanary: "true"` to the push and pull-request
PipelineRuns. Use these variants for Kanary priority selection; regular performance
runs should continue using the original directories.

These build templates do not configure label propagation to integration-test or
release PipelineRuns; verify those separately before enabling label-based priority
for the complete workflow.
