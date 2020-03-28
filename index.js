const core = require('@actions/core');
const github = require('@actions/github');

function getInputs() {
    return {
        token: core.getInput('token'),
        repository: core.getInput('repository'),
        branch: core.getInput('branch'),
        'deploy-to': core.getInput('deploy-to'),
        'compose-folder': core.getInput('compose-folder'),
        'project-name': core.getInput('project-name'),
        'build-args': core.getInput('build-args'),
    };
}
core.error(`User passed config '${JSON.stringify(getInputs(), null, 2)}'.`);
core.error(`User passed config '${JSON.stringify(process.env, null, 2)}'.`);