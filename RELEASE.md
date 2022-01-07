# Release

This action is Docker based. Normally, this action will build the Docker image when used. However, to speed up usage, Docker actions can instead be built ahead of time. The `release.yaml` file under `/.github/workflows` handles the building and tagging of this repo for use. 

## Normal Release

Under normal circumstances, when a new version needs to be released it would simply increment the SEMVER tag. This can be done by pushing a new branch with the name `release/*` where `*` is the tag you would like to apply to both the Docker image and git tag. Pushes to `release/*` branches automatically perform both of these actions and publishes the Docker image to GitHub Container Registry as well as points the `action.yaml` file to the pre-built Docker image before applying the git tag. 

There are branch protections setup to only allow clean pushes to new `release/*` branches from `main`. If commits are made prior to publishing the new branch, GitHub will block the push. Pushes must instead always be merged from a pull request.

From here, any repos that need the new changes in the newly deployed semver tag will just need to update the tag they are requesting in their own GitHub Action workflow.

## Emergency Release

In the scenario where there is a dire change that needs to be made to this action and must be immediately replicated to all repos using this action, then there is a path for this. After making needed changes to a non-release branch, a pull request can be made against the existing `release/v1` branch. Once approved and merged, the `release.yaml` workflow will kick off, build and publish the new Docker image, and force tag over the prior `v1`. 

**WARNING:** This should only be performed when absolutely necessary and *must not* introduce breaking changes to the usage of the action.