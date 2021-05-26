
# get the tags
`git fetch origin --tags`

do a list of the tags to see the format:
`git tag`

# Add a new firmware version

commit either to master branch (-stable), beta branch (-beta) or experimental branch (-experimental)

tag the commit
`git tag 0.0.1-beta`

push your commit:
`git push origin beta`

push the tag:
`git push origin 0.0.1-beta`

# publish firmware version

rerun CI/CD pipeline for pilotbuildserver
