# Docker Compose Merge

This repository contains a bash script named `docker-compose-merge.sh` that will assist you to generate a single docker-compose.yml file by merging specified docker projects together.

## Setup

### Optionally clone into an existing directory, ex: ```~/code```  *this works as unrelated files are not tracked in this repo*
```bash
git clone git@github.com:Sectimus/docker-compose-merge.git /tmp/docker-compose-merge-local && mv /tmp/docker-compose-merge-local/.[!.]* ~/code/
```

### Make the script executable

```bash
sudo chmod +x ./docker-compose-merge.sh
```

## Usage
```
docker-compose-merge.sh [-a|--auto] [-p <arg>...] [output]
docker-compose-merge.sh [-h|--help]

flags:
    -h, --help          Show this help text
    -p, --project       Manually specify project paths, latter takes precedence
    -a  --auto,         Build git hooks for repositories on specified project paths to auto rebuild the compose file
args:
    output              Specifies an output file. (default: "./docker-compose.yml")
```
---
## Examples
### Create a ```docker-compose.yml``` file with two individual projects' docker-compose.yml files merged:
```bash
sudo chmod +x ./docker-compose-merge.sh
./docker-compose-merge.sh -p "./example/project" -p "./different/project"
```
### Create a ```docker-compose.yml``` file with three individual projects' docker-compose.yml files merged:
```bash
sudo chmod +x ./docker-compose-merge.sh
./docker-compose-merge.sh -p "./example/project" -p "./different/project" -p "./yet/another/directory"
```
### Output the Compose file to ```my-custom-compose.yml``` instead:
```bash
sudo chmod +x ./docker-compose-merge.sh
./docker-compose-merge.sh -p "./example/project" -p "./different/project" "./my-custom-compose.yml"
```
### Auto-run on ```git pull```, ```git checkout```, ```git merge``` etc. of the specified project ```-p``` paths.
```bash
sudo chmod +x ./docker-compose-merge.sh
./docker-compose-merge.sh --auto -p "./example/project" -p "./different/project"
```
