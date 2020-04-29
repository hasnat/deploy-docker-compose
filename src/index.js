const {getSecrets} = require('./vault.js');
const fs = require('fs-extra');
const {STAGE, PROJECT_NAME, DEPLOY_TO_ONE} = process.env;

const writeFiles = (filesSets) => {
    filesSets.map(files => {
        Object.keys(files).map(file => {
            fs.ensureFileSync(file)
            fs.writeFileSync(file, files[file])
        })
    })
};

const appendEnvs = (envSets, filename = './.env') => {
    let envs = {};
    envSets.map(env => {
        envs = {...envs, ...env}
    });
    fs.ensureFileSync(filename);
    fs.writeFileSync(
        filename,
        fs.readFileSync(filename) +
            "\n" + Object.keys(envs).map(k => `${k}=${envs[k]}`).join("\n")
    );
};

const main = async () => {
    switch (STAGE) {
        case 'build':
            writeFiles([await getSecrets(`${PROJECT_NAME}/files`)]);
            appendEnvs([await getSecrets(`common/compose`)]);
            break;
        case 'push':
            // appendEnvs([await getSecrets(`common/compose`)]);
            break;
        case 'deploy':
            appendEnvs([
                await getSecrets(`${DEPLOY_TO_ONE.replace(/[\d]+$/, '')}/common/compose`),
                await getSecrets(`${DEPLOY_TO_ONE}/common/compose`),
                await getSecrets(`${PROJECT_NAME}/common/compose`),
                await getSecrets(`${PROJECT_NAME}/${DEPLOY_TO_ONE.replace(/[\d]+$/, '')}/compose`),
                await getSecrets(`${PROJECT_NAME}/${DEPLOY_TO_ONE}/compose`)
            ], `./.${DEPLOY_TO_ONE}.env`);

            break;
    }
}
try {
main();
} catch (e) {
    console.error(e)
}