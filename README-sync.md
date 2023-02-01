## zapt sync command
---

Zapt remoting works by running the `zapt` application both locally and on remote clusters (over ssh) against a set of named tasks in a `tasks.rb` file.  There is an implicit requirement that both the remote version of the zapt application and the remote version of the tasks.rb files(s) that are by convention contained in a directory called `zcripts` are identical.  Occasionaly developers are required to update `zapt` and `zcripts` which can lead the local version getting out of sync with the remote version.

---

The command `sync` helps fix out of sync conditions by requiring local versions of `zapt` and `zcripts` contain no local modificaitons and are up to date with `github origin` and that these version match the versions that are deployed to the named remote cluster.


To issue the command run

```
zapt sync -c [cluster name]
```

Example

```
zapt sync -c skelly
```

Example Output

```bash
skelly-> bin/zapt sync -c skelly
################################################################################
Checking local zapt:
Local zapt has no local modifications
Local zapt has no unpushed commits
################################################################################
Checking local zapt:
Local zapt is up to date with origin
################################################################################
Checking remote zapt:
Connection to 54.187.149.211 closed.
Remote zapt is up to date with origin
################################################################################
Checking local zcripts:
Local zcripts have no local modifications
Local zcripts have no unpushed commits
################################################################################
Checking local zcripts:
Local zcripts are up to date with origin
################################################################################
Checking if remote zcripts need rsync:
rsync  --out-format="%f" -n -arc -e "ssh -i /home/skelly/credentials/dev-test-tmp.pem -l ubuntu" /home/skelly/dev/vega/zcripts ubuntu@54.187.149.211:. --exclude "common/cluster_defs/*"
Remote zcripts need rsynced
INFO: Running task: rsync_zcripts
Loaded /home/skelly/dev/vega/zcripts/common/cluster_defs/skelly.yaml
INFO: Running command: rsync -av -e "ssh -i /home/skelly/credentials/dev-test-tmp.pem -l ubuntu" /home/skelly/dev/vega/zcripts ubuntu@54.187.149.211:. --exclude "common/cluster_defs/*"
INFO: sending incremental file list
zcripts/deploy/
zcripts/deploy/build_all_dmelvin.sh

sent 5,188 bytes  received 65 bytes  3,502.00 bytes/sec
total size is 420,790  speedup is 80.10

INFO: ...tasks have been Zapt
################################################################################
INFO: ...tasks have been Zapt

```