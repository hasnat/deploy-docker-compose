const core = require('@actions/core');

function getInputs() {
    return {
        'deploy_to': core.getInput('deploy_to'),
        'compose_folder': core.getInput('compose_folder') || '.',
        'secrets_path': core.getInput('secrets_path')
    };
}
core.error(`User passed config '${JSON.stringify(getInputs(), null, 2)}'.`);
core.error(`Runner Env '${JSON.stringify(process.env, null, 2)}'.`);
require('./src/index')