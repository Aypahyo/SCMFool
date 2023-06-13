# SCMFool

This is my foolish tool to manage my scm repos on different machines.
I have a lot of repos on different machines and I want to keep them up to date.
I have the same basic directory structure on all machines, so I can use the same script on all machines.
My repos are currently either git or svn repos, so I only support these two.
Reach out on twitter if you need anything or just want to say hi.

## Configuration

| Variable | Description | Default |
| -------- | ----------- | ------- |
| SCMFOOL_ROOT | root directory for all repos | /home/$USER/scm |
| SCMFOOL_TEMP | temp directory for log files | dirname($0)/tmp |

## Usage

### run a selftest

```bash
./scmfool.sh selftest
```

The selftest checks if all required tools are installed.
The exit code is 0 if all tests are passed, otherwise 1.

### pull

```bash
./scmfool.sh pull
```

pull will write a full report into pull.log.
The exit code is 0 if all repos are up to date, otherwise 1.
In case of an error, the report will contain the error message.
Erronious repos will be written to stderr, that does not include folders that are not a repo.

The directory is inspected recusively for repos.
The first hit is the repo, so nested repos are not supported.

## development

I used the following extensions for vscode:

| Key | Value |
| --- | ----- |
| Name | ShellCheck |
| Id | timonwong.shellcheck |
| Description | Integrates ShellCheck into VS Code, a linter for Shell scripts. |
| Version | 0.32.6 |
| Publisher | Timon Wong |
| VS Marketplace | [Link](https://marketplace.visualstudio.com/items?itemName=timonwong.shellcheck) |
