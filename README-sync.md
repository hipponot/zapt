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