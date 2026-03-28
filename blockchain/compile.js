const path = require('path');
const fs = require('fs');
const solc = require('solc');

const contractPath = path.resolve(__char(92),__char(92),'pallothi hack', 'blockchain', 'contracts', 'TrustVerify.sol');
const source = fs.readFileSync(contractPath, 'utf8');

const input = {
    language: 'Solidity',
    sources: {
        'TrustVerify.sol': {
            content: source,
        },
    },
    settings: {
        outputSelection: {
            '*': {
                '*': ['*'],
            },
        },
    },
};

const output = JSON.parse(solc.compile(JSON.stringify(input)));

if (output.errors) {
    output.errors.forEach((err) => {
        console.error(err.formattedMessage);
    });
}

const contract = output.contracts['TrustVerify.sol']['TrustVerify'];

const dir = path.resolve(__char(92),__char(92),'pallothi hack', 'blockchain', 'build');
if (!fs.existsSync(dir)){
    fs.mkdirSync(dir);
}

fs.writeFileSync(
    path.resolve(dir, 'TrustVerify.json'),
    JSON.stringify({
        abi: contract.abi,
        bytecode: contract.evm.bytecode.object,
    }, null, 2)
);

console.log('Contract compiled successfully!');
