const { Kv2SecretEngine } = require('vault-tacular')
const vault = new Kv2SecretEngine(process.env.VAULT_ADDR + 'v1', {
    authToken: process.env.VAULT_TOKEN,
    mount: '/serverConfigs'
});

const getSecrets = async path => {
    try {
        const a = await vault.readSecretVersion(path);
        return a.result.data.data
    } catch (e) {
        console.log('404 (skip)', path)
        return {}
    }
};
module.exports = {
    getSecrets,
    vault
};